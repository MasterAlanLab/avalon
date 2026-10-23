package app.getavalon.avalon.host

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * After a boot, starts the host with the last plan when «开机自动启动» and
 * «启动后自动连接» are both on (PRODUCT_SPEC §6, docs/RUNTIME_HOST.md §8).
 * The app need not have been opened since; it adopts the session later.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        if (!HostOptions.read(context).startAtBoot || !RestorePoint.plan(context).exists()) return
        val start = Intent(context, AvalonVpnService::class.java).setAction(AvalonVpnService.ACTION_RESTORE)
        if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(start) else context.startService(start)
    }
}
