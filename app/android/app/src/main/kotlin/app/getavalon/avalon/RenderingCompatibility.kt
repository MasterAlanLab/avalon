package app.getavalon.avalon

import android.os.Build
import io.flutter.embedding.engine.FlutterShellArgs

/** Renderer selection is process-wide, including a background-first startup. */
internal object RenderingCompatibility {
    fun shellArgs(args: FlutterShellArgs = FlutterShellArgs(emptyArray())): FlutterShellArgs {
        val explicit = args.toArray().any {
            it == FlutterShellArgs.ARG_ENABLE_IMPELLER ||
                it == FlutterShellArgs.ARG_DISABLE_IMPELLER
        }
        // D116: the MT6855's PowerVR BXM stalls in this Flutter pin's
        // Impeller backends. Recheck when upgrading the SDK. Explicit
        // profiling flags still allow comparisons on the same build.
        if (!explicit && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            Build.SOC_MODEL.equals("MT6855", ignoreCase = true)
        ) {
            args.add(FlutterShellArgs.ARG_DISABLE_IMPELLER)
        }
        return args
    }
}
