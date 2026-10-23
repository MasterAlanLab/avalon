package app.getavalon.avalon.host

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import app.getavalon.avalon.BuildConfig
import app.getavalon.avalon.R
import dev.avalon.core.mobile.Host
import dev.avalon.core.mobile.Mobile
import org.json.JSONObject
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * The Android host (docs/RUNTIME_HOST.md §8): owns the Core Bridge and the
 * VPN interface, in the `:vpn` process, and keeps running after the app's
 * interface is gone. It only does what commands tell it; the interface
 * process sends them through [IAvalonHost].
 *
 * While a session runs the service is started and in the foreground with
 * a notification (the speed, and a button to stop); with no session it
 * lives only as long as it is bound. The system (always-on VPN) or a boot
 * can also start it without the app: it then runs the last plan.
 */
class AvalonVpnService : VpnService() {
    private lateinit var platform: AndroidPlatform
    private var host: Host? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val ticker = Executors.newSingleThreadScheduledExecutor()
    private var ticking: ScheduledFuture<*>? = null
    private var options = HostOptions()
    private var shownSpeed: String? = null

    private val binder = object : IAvalonHost.Stub() {
        override fun call(command: String, request: String): String = handle(command, request)
    }

    override fun onCreate() {
        super.onCreate()
        platform = AndroidPlatform(this)
        options = HostOptions.read(this)
    }

    // The system binds with the VPN action; the app's interface with ours.
    override fun onBind(intent: Intent): IBinder? =
        if (intent.action == ACTION_BIND) binder else super.onBind(intent)

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            // The notification's button.
            ACTION_STOP -> worker.execute { handle("stop", JSONObject().put("requestId", "notification").toString()) }
            // A boot, or the system's always-on VPN: in the foreground at
            // once (the system allows only seconds), then the last plan.
            ACTION_RESTORE, SERVICE_INTERFACE -> {
                hold()
                worker.execute { restore() }
            }
        }
        return START_NOT_STICKY
    }

    /**
     * Starts the last plan the app ran (docs/RUNTIME_HOST.md §8), unless a
     * session already runs. Without one, or when it does not start, the
     * host goes back to rest; the app finds it stopped.
     */
    private fun restore() {
        if (running()) return
        val plan = RestorePoint.plan(this)
        val hash = RestorePoint.planHash(this)
        if (!plan.exists() || hash == null) {
            release()
            return
        }
        val now = System.currentTimeMillis()
        val request = JSONObject()
            .put("requestId", "restore-$now")
            .put("planPath", plan.path)
            .put("planHash", hash)
            .put("utcOffsetSeconds", TimeZone.getDefault().getOffset(now) / 1000)
        handle("start", request.toString())
    }

    /** The user turned the VPN off in the system, or another VPN took over. */
    override fun onRevoke() {
        worker.execute {
            runCatching { bridge().call("stop", """{"requestId":"revoked"}""") }
            release()
        }
    }

    override fun onDestroy() {
        synchronized(this) {
            host?.close()
            host = null
        }
        platform.closeTun()
        ticker.shutdownNow()
        super.onDestroy()
    }

    @Synchronized
    private fun bridge(): Host = host ?: run {
        Mobile.setup(filesDir.path, stateDirectory(this).path, cacheDir.path)
        Host(platform, "android").also { host = it }
    }

    private fun handle(command: String, request: String): String = try {
        when (command) {
            "start", "reload" -> {
                // In the foreground before the core starts: it must outlive
                // the binding, and the system gives it only seconds to show
                // its notification.
                hold()
                mirrorLog()
                bridge().call(command, request).also { response ->
                    val accepted = JSONObject(response).has("result")
                    val actual = currentSnapshot()
                    when {
                        actual?.optString("state") != "running" -> release()
                        // The new plan has no tunnel (TUN was turned off):
                        // the interface of the plan before must go, or it
                        // would swallow the device's traffic.
                        // A plan rejected before reloading leaves the old
                        // interface and proxy alive with the old session.
                        // Idempotent duplicate commands also return success
                        // without opening a new TUN: use the running core's
                        // inbound, rather than this attempt's callbacks.
                        accepted && actual?.optBoolean("tunActive") != true -> platform.closeTun()
                    }
                    if (accepted) {
                        runCatching { RestorePoint.ran(this, JSONObject(request).getString("planHash")) }
                        tick()
                    }
                }
            }
            "snapshot" -> {
                val response = JSONObject(bridge().call(command, request))
                response.optJSONObject("result")?.let { snapshot ->
                    // During a failed reload the old session remains.
                    // Report the interface actually established by the
                    // host, never the settings of the attempted plan.
                    val tunnel = platform.tunnelFacts()
                    val active = snapshot.optBoolean("tunActive") && tunnel.active
                    snapshot.put("tunActive", active)
                    snapshot.put("systemProxyActive", active && tunnel.systemProxyActive)
                }
                response.toString()
            }
            "stop" -> bridge().call(command, request).also { release() }
            // Not the bridge's: the app wrote new options for the host.
            "configure" -> {
                options = HostOptions.read(this)
                shownSpeed = null
                if (running()) tick()
                "{\"result\":{}}"
            }
            else -> bridge().call(command, request)
        }.also { response ->
            // Debug builds: what commands answered, for adb. Never the
            // snapshots and logs polled every second.
            if (BuildConfig.DEBUG && command != "snapshot" && command != "logs") {
                // Responses can hold authentication URLs (including a
                // queryCommand recovery). Do not copy payloads to logcat.
                android.util.Log.d("AvalonHost", "$command completed")
            }
        }
    } catch (e: Throwable) {
        // The bridge answers failures itself; this is the host breaking.
        JSONObject().put(
            "error",
            JSONObject().put("code", "CORE_FAILED").put("message", e.message ?: e.javaClass.simpleName),
        ).toString()
    }

    /**
     * Debug builds only: copies the core's log lines to logcat while a
     * session runs, so that a developer can follow it with adb. Release
     * builds never do this (the lines name the sites being visited).
     */
    private fun mirrorLog() {
        if (!BuildConfig.DEBUG || mirroring) return
        mirroring = true
        Thread {
            var after = 0L
            while (mirroring) {
                runCatching {
                    val request = JSONObject().put("afterSeq", after).put("limit", 200).toString()
                    val page = JSONObject(bridge().call("logs", request)).getJSONObject("result")
                    val entries = page.getJSONArray("entries")
                    for (i in 0 until entries.length()) {
                        val entry = entries.getJSONObject(i)
                        android.util.Log.d("AvalonCore", "${entry.getString("level")} ${entry.getString("message")}")
                    }
                    after = page.getLong("nextSeq")
                }
                Thread.sleep(500)
            }
        }.start()
    }

    @Volatile private var mirroring = false

    private fun currentSnapshot(): JSONObject? = runCatching {
        JSONObject(bridge().call("snapshot", "{}")).getJSONObject("result")
    }.getOrNull()

    private fun running(): Boolean = currentSnapshot()?.optString("state") == "running"

    private fun hold() {
        startService(Intent(this, AvalonVpnService::class.java))
        val notification = notification()
        if (Build.VERSION.SDK_INT >= 34) {
            // A granted VPN makes this a system-exempted service; with the
            // tunnel off (ports only) it is a special use.
            val type = if (prepare(this) == null) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED
            } else {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            }
            startForeground(NOTIFICATION_ID, notification, type)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun release() {
        ticking?.cancel(false)
        ticking = null
        mirroring = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        platform.closeTun()
        stopSelf()
    }

    /**
     * Keeps the notification's speed current, every second while a session
     * runs and the screen is on, when the settings show it (RUNTIME_HOST
     * §6). Without it the notification is posted once.
     */
    private fun tick() {
        ticking?.cancel(false)
        ticking = null
        shownSpeed = null
        val manager = getSystemService(NotificationManager::class.java)
        if (!options.speedNotification) {
            manager.notify(NOTIFICATION_ID, notification(null))
            return
        }
        val power = getSystemService(PowerManager::class.java)
        ticking = ticker.scheduleWithFixedDelay({
            if (!power.isInteractive) return@scheduleWithFixedDelay
            val snapshot = runCatching {
                JSONObject(bridge().call("snapshot", "{}")).getJSONObject("result")
            }.getOrNull() ?: return@scheduleWithFixedDelay
            if (snapshot.optString("state") != "running") return@scheduleWithFixedDelay
            val speed = "↑ ${speed(snapshot.optLong("upBps"))}   ↓ ${speed(snapshot.optLong("downBps"))}"
            if (speed == shownSpeed) return@scheduleWithFixedDelay
            shownSpeed = speed
            manager.notify(NOTIFICATION_ID, notification(speed))
        }, 0, 1, TimeUnit.SECONDS)
    }

    /** The host's own text in the app's language, else the system's. */
    private fun texts(): Context {
        val language = options.language ?: return this
        val configuration = Configuration(resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(language))
        return createConfigurationContext(configuration)
    }

    private fun notification(speed: String? = null): Notification {
        val texts = texts()
        val open = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val stop = PendingIntent.getService(
            this,
            1,
            Intent(this, AvalonVpnService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(
                    CHANNEL,
                    texts.getString(R.string.host_notification_channel),
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
            Notification.Builder(this, CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(R.drawable.ic_stat_avalon)
            .setContentTitle(texts.getString(R.string.host_notification_title))
            .setContentText(speed)
            .setContentIntent(open)
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, R.drawable.ic_stat_avalon),
                    texts.getString(R.string.host_notification_stop),
                    stop,
                ).build(),
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .build()
    }

    private fun speed(bytesPerSecond: Long): String = when {
        bytesPerSecond < 1024 -> "$bytesPerSecond B/s"
        bytesPerSecond < 1024 * 1024 -> String.format(Locale.ROOT, "%.1f KB/s", bytesPerSecond / 1024.0)
        else -> String.format(Locale.ROOT, "%.1f MB/s", bytesPerSecond / (1024.0 * 1024))
    }

    companion object {
        const val ACTION_BIND = "app.getavalon.avalon.host.BIND"
        const val ACTION_STOP = "app.getavalon.avalon.host.STOP"
        const val ACTION_RESTORE = "app.getavalon.avalon.host.RESTORE"
        private const val CHANNEL = "connection"
        private const val NOTIFICATION_ID = 1

        /** Where the core and the bridge keep their files (cache, traffic, plan). */
        fun stateDirectory(context: android.content.Context) = context.getDir("state", MODE_PRIVATE)
    }
}
