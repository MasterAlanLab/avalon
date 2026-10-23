package app.getavalon.avalon.background

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager

/**
 * Debug builds only: runs the scheduled updates now, which WorkManager
 * will not do early for periodic work.
 * `adb shell am broadcast -n app.getavalon.avalon/.background.RunUpdatesNow`
 */
class RunUpdatesNow : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WorkManager.getInstance(context).enqueue(OneTimeWorkRequestBuilder<UpdateWorker>().build())
    }
}
