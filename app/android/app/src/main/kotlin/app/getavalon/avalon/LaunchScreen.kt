package app.getavalon.avalon

import android.app.Activity
import android.app.UiModeManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The launch screen (docs/UI_DESIGN_SYSTEM.md §5). Android 12 and later
 * show a blank system splash first; the Flutter animation waits until it
 * has gone, so that it plays from its first frame. The app's appearance
 * is handed to the system, which keeps it for the next launches: the
 * system splash and the startup background then match the app rather
 * than the device's dark-mode setting.
 */
class LaunchScreen(private val activity: Activity) {
    @Volatile
    private var systemSplashVisible = Build.VERSION.SDK_INT >= 31

    /** Call from onCreate: notes when the system splash leaves. */
    fun watch() {
        if (Build.VERSION.SDK_INT < 31) return
        activity.splashScreen.setOnExitAnimationListener { view ->
            view.remove()
            systemSplashVisible = false
        }
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "dev.avalon/launch").setMethodCallHandler { call, result ->
            when (call.method) {
                "isSystemSplashVisible" -> result.success(systemSplashVisible)
                "setAppearance" -> {
                    remember(call.arguments as? String)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun remember(appearance: String?) {
        // Before Android 12 there is no system splash, and the window
        // before the first frame follows the device's setting.
        if (Build.VERSION.SDK_INT < 31) return
        val mode = when (appearance) {
            "dark" -> UiModeManager.MODE_NIGHT_YES
            "light" -> UiModeManager.MODE_NIGHT_NO
            else -> UiModeManager.MODE_NIGHT_AUTO
        }
        // The system keeps the mode; setting it again would still
        // reconfigure the app, so only a change is passed on.
        val kept = activity.getSharedPreferences(PREFERENCES, Activity.MODE_PRIVATE)
        if (kept.getInt(NIGHT_MODE, -1) == mode) return
        activity.getSystemService(UiModeManager::class.java).setApplicationNightMode(mode)
        kept.edit().putInt(NIGHT_MODE, mode).apply()
    }

    private companion object {
        const val PREFERENCES = "launch"
        const val NIGHT_MODE = "nightMode"
    }
}
