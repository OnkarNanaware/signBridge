package com.example.signbridge_phone

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import java.io.ByteArrayOutputStream

/**
 * Helper class that encapsulates MediaPipe Tasks Hand Landmarker inference.
 *
 * Receives camera frame planes (YUV420), converts them to NV21 bitmap,
 * executes synchronous HandLandmarker detection, and returns the 21 normalized
 * 3D landmarks for the detected hand.
 */
class HandLandmarkerHelper(
    private val context: Context,
    private val minHandDetectionConfidence: Float = 0.5f,
    private val minHandTrackingConfidence: Float = 0.5f,
    private val minHandPresenceConfidence: Float = 0.5f,
    private val maxNumHands: Int = 1
) {
    private var handLandmarker: HandLandmarker? = null

    init {
        setupHandLandmarker()
    }

    private fun setupHandLandmarker() {
        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()

            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setMinHandDetectionConfidence(minHandDetectionConfidence)
                .setMinTrackingConfidence(minHandTrackingConfidence)
                .setMinHandPresenceConfidence(minHandPresenceConfidence)
                .setNumHands(maxNumHands)
                .setRunningMode(RunningMode.IMAGE)
                .build()

            handLandmarker = HandLandmarker.createFromOptions(context, options)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Detects 21 hand landmarks from YUV_420_888 camera planes.
     * Returns a list of maps, each containing landmarkIndex, x, y, and z.
     */
    fun detectFromYuvPlanes(
        yBytes: ByteArray,
        uBytes: ByteArray,
        vBytes: ByteArray,
        width: Int,
        height: Int,
        rotation: Int,
        yRowStride: Int,
        uvRowStride: Int,
        uvPixelStride: Int
    ): List<Map<String, Any>>? {
        val landmarker = handLandmarker ?: return null

        return try {
            val nv21 = yuv420ToNv21(
                width, height,
                yBytes, uBytes, vBytes,
                yRowStride, uvRowStride, uvPixelStride
            )

            val out = ByteArrayOutputStream()
            val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
            yuvImage.compressToJpeg(Rect(0, 0, width, height), 75, out)
            val jpegData = out.toByteArray()
            var bitmap = BitmapFactory.decodeByteArray(jpegData, 0, jpegData.size) ?: return null

            if (rotation != 0) {
                val matrix = Matrix()
                matrix.postRotate(rotation.toFloat())
                bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            }

            val mpImage: MPImage = BitmapImageBuilder(bitmap).build()
            val result: HandLandmarkerResult = landmarker.detect(mpImage)

            val landmarks = result.landmarks()
            if (landmarks.isEmpty()) {
                return emptyList()
            }

            val firstHand = landmarks[0]
            val list = ArrayList<Map<String, Any>>(firstHand.size)
            for (i in firstHand.indices) {
                val lm = firstHand[i]
                val map = HashMap<String, Any>()
                map["landmarkIndex"] = i
                map["x"] = lm.x().toDouble()
                map["y"] = lm.y().toDouble()
                map["z"] = lm.z().toDouble()
                list.add(map)
            }
            list
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    fun close() {
        handLandmarker?.close()
        handLandmarker = null
    }

    companion object {
        fun yuv420ToNv21(
            width: Int,
            height: Int,
            yPlane: ByteArray,
            uPlane: ByteArray,
            vPlane: ByteArray,
            yRowStride: Int,
            uvRowStride: Int,
            uvPixelStride: Int
        ): ByteArray {
            val nv21 = ByteArray(width * height * 3 / 2)
            var destPos = 0

            // Copy Y
            if (yRowStride == width) {
                System.arraycopy(yPlane, 0, nv21, 0, width * height)
                destPos = width * height
            } else {
                for (row in 0 until height) {
                    System.arraycopy(yPlane, row * yRowStride, nv21, destPos, width)
                    destPos += width
                }
            }

            // Copy UV interleaved (NV21 expects V then U)
            val uvHeight = height / 2
            val uvWidth = width / 2
            for (row in 0 until uvHeight) {
                for (col in 0 until uvWidth) {
                    val uvIndex = row * uvRowStride + col * uvPixelStride
                    if (uvIndex < vPlane.size && uvIndex < uPlane.size && destPos + 1 < nv21.size) {
                        nv21[destPos++] = vPlane[uvIndex]
                        nv21[destPos++] = uPlane[uvIndex]
                    }
                }
            }
            return nv21
        }
    }
}
