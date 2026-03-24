package com.liquid.dialer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CallScreeningConstants.METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    CallScreeningConstants.SYNC_CALL_DIRECTORY_METHOD -> {
                        // The Android Call Screening Service queries Flutter live,
                        // so sync is mostly a placeholder or to clear local cache if any.
                        Log.d(TAG, "Syncing call directory (Android)...")
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
