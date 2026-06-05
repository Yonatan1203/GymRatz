package com.gymratz.gymratz

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * GYM-37 — Picture-in-Picture (PiP) support.
 *
 * Flutter MethodChannel: 'com.gymratz.gymratz/pip'
 *
 * Methods exposed to Flutter:
 *   isPipSupported  → Bool  : true if device SDK >= 26 (Android 8.0 / O)
 *   enablePip       → Bool  : immediately enter PiP and enable auto-PiP on
 *                             home/app-switch. Returns true on success.
 *   disablePip      → Bool  : disable auto-PiP; always true.
 *
 * Callbacks sent to Flutter:
 *   onPipChanged(bool isInPip) — fires whenever PiP mode changes.
 *
 * minSdkVersion: flutter.minSdkVersion (set in android/app/build.gradle.kts).
 * PiP APIs are guarded by Build.VERSION_CODES.O (26) checks.
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gymratz.gymratz/pip"
    private var pipAutoEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Returns true if PiP is supported on this device.
                    "isPipSupported" -> {
                        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    }
                    // Enter PiP mode immediately and enable auto-PiP on home.
                    "enablePip" -> {
                        pipAutoEnabled = true
                        result.success(enterPipMode())
                    }
                    // Disable auto-PiP. Does NOT exit an active PiP session.
                    "disablePip" -> {
                        pipAutoEnabled = false
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Auto-enter PiP when the user presses Home/Recents, if enabled. */
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (pipAutoEnabled) {
            enterPipMode()
        }
    }

    private fun enterPipMode(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(9, 16)) // portrait video ratio
                .build()
            enterPictureInPictureMode(params)
            true
        } catch (e: Exception) {
            false
        }
    }

    /** Forward PiP mode changes to the Flutter layer. */
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod(
                "onPipChanged",
                isInPictureInPictureMode,
            )
        }
    }
}
