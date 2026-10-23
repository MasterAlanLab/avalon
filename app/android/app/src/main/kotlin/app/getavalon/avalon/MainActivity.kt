package app.getavalon.avalon

import android.content.Intent
import android.os.Bundle
import app.getavalon.avalon.background.UpdateWorker
import app.getavalon.avalon.host.HostChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs

class MainActivity : FlutterActivity() {
    private var host: HostChannel? = null
    private val launchScreen = LaunchScreen(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        launchScreen.watch()
        super.onCreate(savedInstanceState)
        open = true
        UpdateWorker.schedule(applicationContext)
    }

    override fun onDestroy() {
        open = false
        super.onDestroy()
    }

    override fun getFlutterShellArgs(): FlutterShellArgs =
        RenderingCompatibility.shellArgs(super.getFlutterShellArgs())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        InstalledApps(applicationContext).register(messenger)
        launchScreen.register(messenger)
        host = HostChannel(applicationContext, this).also { it.register(messenger) }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        host?.onActivityResult(requestCode, resultCode)
    }

    companion object {
        /** The interface is up: its own scheduler runs the updates. */
        @Volatile
        var open = false
            private set
    }
}
