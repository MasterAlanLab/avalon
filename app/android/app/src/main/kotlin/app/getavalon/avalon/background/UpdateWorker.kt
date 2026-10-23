package app.getavalon.avalon.background

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import app.getavalon.avalon.MainActivity
import app.getavalon.avalon.RenderingCompatibility
import app.getavalon.avalon.host.HostChannel
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Scheduled updates without the interface (D75): WorkManager runs this
 * every hour while there is a network. It starts a Flutter engine on the
 * app's background entry point, which updates the subscriptions and rule
 * sets that are due, reloads a running host whose plan changed, and says
 * when it is done. While the interface is open its own scheduler does the
 * same, so this does nothing.
 */
class UpdateWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        if (MainActivity.open) return Result.success()
        val done = CountDownLatch(1)
        val main = Handler(Looper.getMainLooper())
        var engine: FlutterEngine? = null
        main.post {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(
                applicationContext,
                RenderingCompatibility.shellArgs().toArray(),
            )
            engine = FlutterEngine(applicationContext).also { started ->
                val messenger = started.dartExecutor.binaryMessenger
                HostChannel(applicationContext, null).register(messenger)
                MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                    result.success(null)
                    if (call.method == "done") done.countDown()
                }
                started.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRY_POINT),
                )
            }
        }
        // WorkManager stops a worker after ten minutes.
        val finished = done.await(9, TimeUnit.MINUTES)
        main.post { engine?.destroy() }
        return if (finished) Result.success() else Result.retry()
    }

    companion object {
        private const val CHANNEL = "dev.avalon/background"
        private const val ENTRY_POINT = "backgroundMain"
        private const val NAME = "scheduled-updates"

        /** Registers the hourly run; one registered before stays as it is. */
        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<UpdateWorker>(1, TimeUnit.HOURS)
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(NAME, ExistingPeriodicWorkPolicy.KEEP, request)
        }
    }
}
