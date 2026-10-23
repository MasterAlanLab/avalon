package app.getavalon.avalon.host

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * The interface side of the host: carries bridge commands from Dart to
 * [AvalonVpnService], asks the system for what a session needs, and keeps
 * the options the host acts on by itself. The commands themselves pass
 * through untouched (D85).
 */
class HostChannel(
    private val context: Context,
    /** Null in the background engine (D75): nothing to ask the user with. */
    private val activity: Activity?,
) : MethodChannel.MethodCallHandler {
    // Calls block until the host answers; several may be under way (a
    // snapshot while a start is still running).
    private val workers = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())

    private var service: IAvalonHost? = null
    private var connection: ServiceConnection? = null
    private var awaitingVpn: MethodChannel.Result? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "dev.avalon/host").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "facts" -> result.success(
                mapOf(
                    "stateDir" to AvalonVpnService.stateDirectory(context).path,
                    "deviceName" to Build.MODEL,
                ),
            )
            "prepare" -> prepare(call.argument<Boolean>("tun") == true, result)
            "call" -> {
                val command = call.argument<String>("command")!!
                val request = call.argument<String>("request")!!
                workers.execute {
                    try {
                        val response = bound().call(command, request)
                        main.post { result.success(response) }
                    } catch (e: Exception) {
                        // The service died or could not be reached.
                        synchronized(this) { service = null }
                        main.post { result.error("host.unreachable", e.message, null) }
                    }
                }
            }
            "release" -> {
                release()
                result.success(null)
            }
            // Written here, where the host reads it even without the app;
            // a running host is told to read it again.
            "configure" -> {
                val json = call.arguments as String
                workers.execute {
                    try {
                        HostOptions.write(context, json)
                        synchronized(this) { service }?.let { running ->
                            runCatching { running.call("configure", "{}") }
                        }
                        main.post { result.success(null) }
                    } catch (e: Exception) {
                        main.post { result.error("host.configure", e.message, null) }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Asks for what a session needs before it starts: the VPN consent when
     * the tunnel is on, and (without waiting for the answer) permission to
     * show the notification. Answers false when the VPN was refused.
     */
    private fun prepare(tun: Boolean, result: MethodChannel.Result) {
        val activity = activity
        if (activity == null) {
            // Without the interface the user cannot be asked.
            result.success(!tun || VpnService.prepare(context) == null)
            return
        }
        if (Build.VERSION.SDK_INT >= 33 &&
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
        }
        val consent = if (tun) VpnService.prepare(activity) else null
        if (consent == null) {
            result.success(true)
            return
        }
        awaitingVpn?.success(false)
        awaitingVpn = result
        activity.startActivityForResult(consent, REQUEST_VPN)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int) {
        if (requestCode != REQUEST_VPN) return
        awaitingVpn?.success(resultCode == Activity.RESULT_OK)
        awaitingVpn = null
    }

    @Synchronized
    private fun bound(): IAvalonHost {
        service?.let { return it }
        val connected = CountDownLatch(1)
        val link = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName, binder: IBinder) {
                service = IAvalonHost.Stub.asInterface(binder)
                connected.countDown()
            }

            override fun onServiceDisconnected(name: ComponentName) {
                service = null
            }
        }
        val intent = Intent(context, AvalonVpnService::class.java).setAction(AvalonVpnService.ACTION_BIND)
        if (!context.bindService(intent, link, Context.BIND_AUTO_CREATE)) {
            throw IllegalStateException("the host service cannot be bound")
        }
        connection = link
        if (!connected.await(10, TimeUnit.SECONDS)) throw IllegalStateException("the host service did not start")
        return service ?: throw IllegalStateException("the host service went away")
    }

    /** Lets go of the host; without a session its process can then end. */
    @Synchronized
    fun release() {
        connection?.let { runCatching { context.unbindService(it) } }
        connection = null
        service = null
    }

    private companion object {
        const val REQUEST_VPN = 0x4156
        const val REQUEST_NOTIFICATIONS = 0x4157
    }
}
