package app.getavalon.avalon.host

import android.net.DnsResolver
import android.net.Network
import android.os.Build
import android.os.CancellationSignal
import android.system.ErrnoException
import android.system.OsConstants
import dev.avalon.core.libbox.ExchangeContext
import dev.avalon.core.libbox.Func
import dev.avalon.core.libbox.LocalDNSTransport
import java.net.Inet4Address
import java.net.Inet6Address
import java.net.UnknownHostException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executor

/**
 * The system's resolver, for plans with a `local` DNS server
 * (docs/RUNTIME_HOST.md §8). Queries go to the DNS of [network], the
 * network apps would use without the VPN, so they never loop back into
 * the tunnel. Android 10 and later pass the whole query through
 * [DnsResolver]; before that only address lookups are possible.
 */
class SystemDns(private val network: () -> Network?) : LocalDNSTransport {
    override fun raw() = Build.VERSION.SDK_INT >= 29

    override fun exchange(ctx: ExchangeContext, message: ByteArray) {
        if (Build.VERSION.SDK_INT < 29) throw Exception("needs Android 10")
        val target = network() ?: throw Exception("no network to resolve on")
        val done = CountDownLatch(1)
        val signal = CancellationSignal()
        // A cancelled query never calls back: stop waiting for it.
        ctx.onCancel(object : Func {
            override fun invoke() {
                signal.cancel()
                done.countDown()
            }
        })
        DnsResolver.getInstance().rawQuery(
            target,
            message,
            DnsResolver.FLAG_NO_RETRY,
            Executor { it.run() },
            signal,
            object : DnsResolver.Callback<ByteArray> {
                // The answer carries its own response code (NXDOMAIN too).
                override fun onAnswer(answer: ByteArray, rcode: Int) {
                    ctx.rawSuccess(answer)
                    done.countDown()
                }

                override fun onError(error: DnsResolver.DnsException) {
                    ctx.errnoCode((error.cause as? ErrnoException)?.errno ?: OsConstants.EIO)
                    done.countDown()
                }
            },
        )
        done.await()
    }

    override fun lookup(ctx: ExchangeContext, network: String, domain: String) {
        val target = network() ?: throw Exception("no network to resolve on")
        val addresses = try {
            target.getAllByName(domain.trimEnd('.'))
        } catch (e: UnknownHostException) {
            ctx.errorCode(NXDOMAIN)
            return
        }
        val wanted = addresses.filter { if (network == "ip4") it is Inet4Address else it is Inet6Address }
        ctx.success(wanted.mapNotNull { it.hostAddress?.substringBefore('%') }.joinToString("\n"))
    }

    private companion object {
        const val NXDOMAIN = 3
    }
}
