package com.masteralanlab.avalon

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import com.masteralanlab.avalon.plugins.AppPlugin
import com.masteralanlab.avalon.plugins.ServicePlugin
import com.masteralanlab.avalon.plugins.TilePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    @Volatile
    private var systemSplashVisible = true

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        // Keep the Flutter surface behind both system bars. Without this,
        // Android can leave the launch window's black bar visible in light
        // mode even though Flutter requests edge-to-edge afterwards.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        splashScreen.setOnExitAnimationListener { provider ->
            provider.remove()
            systemSplashVisible = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AppPlugin())
        flutterEngine.plugins.add(ServicePlugin())
        flutterEngine.plugins.add(TilePlugin())
        ServiceState.attachFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            startupSplashChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSystemSplashVisible" -> result.success(systemSplashVisible)
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        flutterEngine?.let(ServiceState::detachFlutterEngine)
        super.onDestroy()
    }

    companion object {
        private const val startupSplashChannel =
            "com.masteralanlab.avalon/startup_splash"
    }
}
