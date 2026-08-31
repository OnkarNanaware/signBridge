package com.example.signbridge_phone

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.signbridge/hand_landmarker"
    private var helper: HandLandmarkerHelper? = null
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        helper = HandLandmarkerHelper(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "detectLandmarks" -> {
                    val yBytes = call.argument<ByteArray>("yPlane")
                    val uBytes = call.argument<ByteArray>("uPlane")
                    val vBytes = call.argument<ByteArray>("vPlane")
                    val width = call.argument<Int>("width")
                    val height = call.argument<Int>("height")
                    val rotation = call.argument<Int>("rotation") ?: 0
                    val yRowStride = call.argument<Int>("yRowStride") ?: width ?: 0
                    val uvRowStride = call.argument<Int>("uvRowStride") ?: width ?: 0
                    val uvPixelStride = call.argument<Int>("uvPixelStride") ?: 1

                    if (yBytes == null || uBytes == null || vBytes == null || width == null || height == null) {
                        result.error("INVALID_ARGS", "Missing plane or dimension arguments", null)
                        return@setMethodCallHandler
                    }

                    executor.execute {
                        val landmarks = helper?.detectFromYuvPlanes(
                            yBytes, uBytes, vBytes,
                            width, height, rotation,
                            yRowStride, uvRowStride, uvPixelStride
                        )
                        runOnUiThread {
                            result.success(landmarks ?: emptyList<Map<String, Any>>())
                        }
                    }
                }
                "close" -> {
                    helper?.close()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        helper?.close()
        executor.shutdown()
        super.onDestroy()
    }
}
