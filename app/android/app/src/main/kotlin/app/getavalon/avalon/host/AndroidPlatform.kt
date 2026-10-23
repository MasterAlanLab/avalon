package app.getavalon.avalon.host

import android.net.ConnectivityManager
import android.net.IpPrefix
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.os.Process
import dev.avalon.core.libbox.BridgeOptions
import dev.avalon.core.libbox.BridgeSession
import dev.avalon.core.libbox.ConnectionOwner
import dev.avalon.core.libbox.InterfaceUpdateListener
import dev.avalon.core.libbox.Libbox
import dev.avalon.core.libbox.LocalDNSTransport
import dev.avalon.core.libbox.NeighborUpdateListener
import dev.avalon.core.libbox.NetworkInterface
import dev.avalon.core.libbox.NetworkInterfaceIterator
import dev.avalon.core.libbox.Notification
import dev.avalon.core.libbox.PlatformInterface
import dev.avalon.core.libbox.PlatformUser
import dev.avalon.core.libbox.RoutePrefix
import dev.avalon.core.libbox.RoutePrefixIterator
import dev.avalon.core.libbox.ShellSession
import dev.avalon.core.libbox.StringIterator
import dev.avalon.core.libbox.TunOptions
import dev.avalon.core.libbox.WIFIState
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface as JavaInterface

/**
 * What sing-box asks of an Android host (docs/RUNTIME_HOST.md §8): the
 * TUN through [VpnService.Builder], keeping the core's own sockets out of
 * the tunnel, the default network, the interfaces, and which app owns a
 * connection. The rest of libbox's interface serves features Avalon does
 * not have and answers «not supported».
 */
class AndroidPlatform(private val service: VpnService) : PlatformInterface {
    private val connectivity = service.getSystemService(ConnectivityManager::class.java)
    private val main = Handler(Looper.getMainLooper())
    private val monitors = HashMap<InterfaceUpdateListener, ConnectivityManager.NetworkCallback>()

    /** The VPN interface while there is one; the core holds its own copy. */
    @Volatile
    private var tun: EstablishedTun? = null

    private data class EstablishedTun(
        val descriptor: ParcelFileDescriptor,
        val httpProxyInstalled: Boolean,
    )

    /** A single established interface's facts, visible across AIDL threads. */
    data class TunnelFacts(val active: Boolean, val systemProxyActive: Boolean)

    fun tunnelFacts(): TunnelFacts {
        val established = tun
        return TunnelFacts(established != null, established?.httpProxyInstalled == true)
    }

    /** Closes the VPN interface (after the core has stopped using it). */
    @Synchronized
    fun closeTun() {
        val established = tun
        tun = null
        established?.descriptor?.close()
    }

    @Synchronized
    override fun openTun(options: TunOptions): Int {
        if (VpnService.prepare(service) != null) throw Exception("VPN permission has not been granted")
        val builder = service.Builder().setSession("Avalon").setMtu(options.mtu)
        if (Build.VERSION.SDK_INT >= 29) builder.setMetered(false)
        var inet6 = false
        for (prefix in options.inet4Address.list()) builder.addAddress(prefix.address(), prefix.prefix())
        for (prefix in options.inet6Address.list()) {
            builder.addAddress(prefix.address(), prefix.prefix())
            inet6 = true
        }
        if (options.autoRoute) {
            for (server in options.dnsServerAddress.list()) builder.addDnsServer(server)
            if (Build.VERSION.SDK_INT >= 33) {
                // The system subtracts excluded prefixes itself.
                builder.routes(options.inet4RouteAddress, "0.0.0.0")
                for (prefix in options.inet4RouteExcludeAddress.list()) builder.excludeRoute(prefix.toIpPrefix())
                if (inet6) {
                    builder.routes(options.inet6RouteAddress, "::")
                    for (prefix in options.inet6RouteExcludeAddress.list()) builder.excludeRoute(prefix.toIpPrefix())
                }
            } else {
                // Before Android 13 the core has already computed the ranges.
                builder.routes(options.inet4RouteRange, "0.0.0.0")
                if (inet6) builder.routes(options.inet6RouteRange, "::")
            }
            // Only installed packages are passed on. Depending on the
            // Android version an unknown name is refused or kept as a
            // filter that matches nothing; neither is what the list means.
            val allowed = options.includePackage.list()
            val installed = allowed.filter(::isInstalled)
            // Nothing of an allow list installed: the tunnel would carry no
            // app (or every app, where the builder refuses the names).
            // Refuse rather than run something else (PRODUCT_SPEC §3.11).
            if (allowed.isNotEmpty() && installed.isEmpty()) {
                throw Exception("none of the apps the per-app list allows is installed")
            }
            for (name in installed) builder.addAllowedApplication(name)
            for (name in options.excludePackage.list().filter(::isInstalled)) {
                builder.addDisallowedApplication(name)
            }
            if (options.isHTTPProxyEnabled && Build.VERSION.SDK_INT >= 29) {
                builder.setHttpProxy(
                    android.net.ProxyInfo.buildDirectProxy(
                        options.httpProxyServer,
                        options.httpProxyServerPort,
                        options.httpProxyBypassDomain.list(),
                    ),
                )
            }
        }
        val descriptor = builder.establish() ?: throw Exception("the system refused to create the VPN interface")
        // The previous interface is released only now that the new one
        // exists, so no traffic leaves outside a tunnel during a reload.
        val previous = tun
        tun = EstablishedTun(
            descriptor,
            options.autoRoute && options.isHTTPProxyEnabled && Build.VERSION.SDK_INT >= 29,
        )
        previous?.descriptor?.close()
        return descriptor.fd
    }

    private fun isInstalled(name: String): Boolean = try {
        service.packageManager.getPackageInfo(name, 0)
        true
    } catch (e: android.content.pm.PackageManager.NameNotFoundException) {
        false
    }

    private fun VpnService.Builder.routes(prefixes: RoutePrefixIterator, everything: String) {
        val list = prefixes.list()
        if (list.isEmpty()) addRoute(everything, 0)
        for (prefix in list) addRoute(prefix.address(), prefix.prefix())
    }

    private fun RoutePrefix.toIpPrefix() = IpPrefix(InetAddress.getByName(address()), prefix())

    override fun usePlatformAutoDetectInterfaceControl() = true

    @Synchronized
    override fun autoDetectInterfaceControl(fd: Int) {
        // A standalone probe opens no TUN and must work before VPN consent.
        // Android refuses protect() until prepared; an active tunnel still
        // requires protection, including while its authorization is revoked.
        if (tun == null && VpnService.prepare(service) != null) return
        if (!service.protect(fd)) throw Exception("could not keep the socket out of the tunnel")
    }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        fun report(network: Network, properties: LinkProperties?): Boolean {
            val name = properties?.interfaceName ?: return false
            val index = runCatching { JavaInterface.getByName(name)?.index }.getOrNull() ?: return false
            val capabilities = connectivity.getNetworkCapabilities(network)
            val metered = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) == false
            listener.updateDefaultInterface(name, index, metered, false)
            return true
        }
        // The core dials as soon as this returns: it must know the network
        // now, not when the first callback arrives. A latency probe, which
        // opens no tunnel, dials at once.
        currentNetwork()?.let { report(it, connectivity.getLinkProperties(it)) }
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onLinkPropertiesChanged(network: Network, properties: LinkProperties) {
                report(network, properties)
            }

            override fun onLost(network: Network) = listener.updateDefaultInterface("", -1, false, false)
        }
        // The network apps would use if no VPN were up.
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
            .build()
        if (Build.VERSION.SDK_INT >= 31) {
            connectivity.registerBestMatchingNetworkCallback(request, callback, main)
        } else {
            connectivity.requestNetwork(request, callback, main)
        }
        synchronized(monitors) { monitors[listener] = callback }
    }

    /** The network apps would use if no VPN were up, as it is now. */
    private fun currentNetwork(): Network? {
        fun usable(network: Network): Boolean {
            val capabilities = connectivity.getNetworkCapabilities(network) ?: return false
            return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                !capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        }
        connectivity.activeNetwork?.takeIf(::usable)?.let { return it }
        @Suppress("DEPRECATION")
        return connectivity.allNetworks.firstOrNull(::usable)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        synchronized(monitors) { monitors.remove(listener) }?.let {
            runCatching { connectivity.unregisterNetworkCallback(it) }
        }
    }

    override fun getInterfaces(): NetworkInterfaceIterator {
        val found = ArrayList<NetworkInterface>()
        @Suppress("DEPRECATION")
        for (network in connectivity.allNetworks) {
            val properties = connectivity.getLinkProperties(network) ?: continue
            val capabilities = connectivity.getNetworkCapabilities(network) ?: continue
            val name = properties.interfaceName ?: continue
            val java = runCatching { JavaInterface.getByName(name) }.getOrNull() ?: continue
            found += NetworkInterface().apply {
                this.name = name
                index = java.index
                mtu = runCatching { java.mtu }.getOrDefault(1500)
                addresses = Strings(
                    java.interfaceAddresses.map {
                        "${it.address.hostAddress?.substringBefore('%')}/${it.networkPrefixLength}"
                    },
                )
                dnsServer = Strings(properties.dnsServers.mapNotNull { it.hostAddress })
                type = when {
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> Libbox.InterfaceTypeWIFI
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> Libbox.InterfaceTypeCellular
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> Libbox.InterfaceTypeEthernet
                    else -> Libbox.InterfaceTypeOther
                }
                metered = !capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
                // Linux interface flags, as the core reads them.
                var bits = 0
                if (capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) bits = bits or IFF_UP or IFF_RUNNING
                if (runCatching { java.isLoopback }.getOrDefault(false)) bits = bits or IFF_LOOPBACK
                if (runCatching { java.isPointToPoint }.getOrDefault(false)) bits = bits or IFF_POINTOPOINT
                if (runCatching { java.supportsMulticast() }.getOrDefault(false)) bits = bits or IFF_MULTICAST
                flags = bits
            }
        }
        return object : NetworkInterfaceIterator {
            private val iterator = found.iterator()
            override fun hasNext() = iterator.hasNext()
            override fun next() = iterator.next()
        }
    }

    // Android 10 and later no longer let an app read /proc/net.
    override fun useProcFS() = Build.VERSION.SDK_INT < 29

    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int,
    ): ConnectionOwner {
        if (Build.VERSION.SDK_INT < 29) throw Exception("needs Android 10")
        val uid = connectivity.getConnectionOwnerUid(
            ipProtocol,
            InetSocketAddress(sourceAddress, sourcePort),
            InetSocketAddress(destinationAddress, destinationPort),
        )
        if (uid == Process.INVALID_UID) throw Exception("no owner found")
        val packages = service.packageManager
        return ConnectionOwner().apply {
            userId = uid
            userName = packages.getNameForUid(uid) ?: ""
            setAndroidPackageNames(Strings(packages.getPackagesForUid(uid)?.toList() ?: emptyList()))
        }
    }

    // System DNS for plans with a `local` server, on the network apps
    // would use without the VPN (RUNTIME_HOST §8).
    private val systemDns = SystemDns { currentNetwork() }
    override fun localDNSTransport(): LocalDNSTransport = systemDns
    override fun underNetworkExtension() = false
    override fun includeAllNetworks() = false
    override fun readWIFIState(): WIFIState? = null
    override fun clearDNSCache() {}
    override fun registerMyInterface(name: String) {}
    override fun tailscaleHostname(): String = Build.MODEL
    override fun sendNotification(notification: Notification) {}
    override fun cancelNotification(identifier: String, typeID: Int) {}
    override fun startNeighborMonitor(listener: NeighborUpdateListener) {}
    override fun closeNeighborMonitor(listener: NeighborUpdateListener) {}
    override fun usePlatformShell() = false
    override fun checkPlatformShell() = throw unsupported()
    override fun openShellSession(
        user: PlatformUser?,
        command: String?,
        environ: StringIterator?,
        term: String?,
        rows: Int,
        cols: Int,
    ): ShellSession = throw unsupported()
    override fun lookupUser(username: String?): PlatformUser = throw unsupported()
    override fun lookupSFTPServer(): String = throw unsupported()
    override fun readSystemSSHHostKey(): String = throw unsupported()
    override fun usePlatformBridge() = false
    override fun createBridge(options: BridgeOptions?): BridgeSession = throw unsupported()

    private fun unsupported() = Exception("not supported")

    private class Strings(private val values: List<String>) : StringIterator {
        private var at = 0
        override fun hasNext() = at < values.size
        override fun len() = values.size
        override fun next() = values[at++]
    }

    private fun StringIterator.list(): List<String> {
        val out = ArrayList<String>()
        while (hasNext()) out += next()
        return out
    }

    private fun RoutePrefixIterator.list(): List<RoutePrefix> {
        val out = ArrayList<RoutePrefix>()
        while (hasNext()) out += next()
        return out
    }

    private companion object {
        const val IFF_UP = 0x1
        const val IFF_LOOPBACK = 0x8
        const val IFF_POINTOPOINT = 0x10
        const val IFF_RUNNING = 0x40
        const val IFF_MULTICAST = 0x1000
    }
}
