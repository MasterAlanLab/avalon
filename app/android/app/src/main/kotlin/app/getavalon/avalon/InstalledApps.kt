package app.getavalon.avalon

import android.Manifest
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * The apps the per-app list can name (PRODUCT_SPEC §3.11): every package
 * that can use the network, except this one.
 */
class InstalledApps(private val context: Context) {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "dev.avalon/apps").setMethodCallHandler { call, result ->
            if (call.method != "list") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            // Reading every label takes a moment: off the main thread.
            worker.execute {
                try {
                    val apps = list()
                    main.post { result.success(apps) }
                } catch (e: Exception) {
                    main.post { result.error("apps.list", e.message, null) }
                }
            }
        }
    }

    private fun list(): List<Map<String, Any>> {
        val pm = context.packageManager
        return packages(pm)
            .filter { it.packageName != context.packageName }
            .filter { it.requestedPermissions?.contains(Manifest.permission.INTERNET) == true }
            .mapNotNull { info ->
                val app = info.applicationInfo ?: return@mapNotNull null
                mapOf(
                    "id" to info.packageName,
                    "name" to app.loadLabel(pm).toString(),
                    "system" to (app.flags and ApplicationInfo.FLAG_SYSTEM != 0),
                )
            }
    }

    private fun packages(pm: PackageManager): List<PackageInfo> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(
                PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        }
}
