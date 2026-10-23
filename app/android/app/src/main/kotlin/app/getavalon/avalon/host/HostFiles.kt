package app.getavalon.avalon.host

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * What the host acts on by itself (docs/RUNTIME_HOST.md §8), as the app
 * last set it. Kept in the host directory, so that the `:vpn` process and
 * the boot receiver read it without the app.
 */
data class HostOptions(
    val speedNotification: Boolean = true,
    val startAtBoot: Boolean = false,
    /** The app's language for the host's text; null follows the system. */
    val language: String? = null,
) {
    companion object {
        private const val FILE = "host-options.json"

        fun read(context: Context): HostOptions = runCatching {
            parse(File(AvalonVpnService.stateDirectory(context), FILE).readText())
        }.getOrDefault(HostOptions())

        /** Keeps [json] as the app sent it, once it parses. */
        fun write(context: Context, json: String) {
            parse(json)
            HostFiles.replace(File(AvalonVpnService.stateDirectory(context), FILE), json)
        }

        private fun parse(json: String): HostOptions {
            val o = JSONObject(json)
            return HostOptions(
                speedNotification = o.optBoolean("speedNotification", true),
                startAtBoot = o.optBoolean("startAtBoot", false),
                language = o.optString("language").ifEmpty { null },
            )
        }
    }
}

/**
 * The plan to start again from when the system or a boot restarts the
 * host without the app: the app keeps it as `plan.json` once the host
 * runs it, and the host notes its hash.
 */
object RestorePoint {
    private const val HASH = "plan-hash"

    fun plan(context: Context) = File(AvalonVpnService.stateDirectory(context), "plan.json")

    fun planHash(context: Context): String? =
        runCatching { File(AvalonVpnService.stateDirectory(context), HASH).readText() }
            .getOrNull()?.takeIf { it.isNotEmpty() }

    fun ran(context: Context, planHash: String) =
        HostFiles.replace(File(AvalonVpnService.stateDirectory(context), HASH), planHash)
}

object HostFiles {
    /** Writes beside [file] and moves into place whole: two processes read these. */
    fun replace(file: File, text: String) {
        val temp = File(file.parentFile, ".${file.name}.tmp")
        temp.writeText(text)
        if (!temp.renameTo(file)) {
            temp.delete()
            throw IllegalStateException("cannot write ${file.name}")
        }
    }
}
