package com.vena.doctor

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val SCREEN_CAPTURE_CHANNEL =
            "com.vena.doctor/screen_capture"
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_CAPTURE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val enabled =
                        call.argument<Boolean>("enabled")

                    if (enabled == null) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "enabled 값이 필요합니다.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    if (enabled) {
                        window.addFlags(
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                    } else {
                        window.clearFlags(
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                    }

                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}