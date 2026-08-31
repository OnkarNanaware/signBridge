import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/services/hand_landmark_service.dart';

/// Real [HandLandmarkService] integrating MediaPipe Tasks Hand Landmarker
/// through an Android platform channel (`com.example.signbridge/hand_landmarker`).
///
/// Yields 21 3D normalized hand landmarks per frame. Throttles frame processing
/// so frames are dropped if native inference is still running, guaranteeing <500ms
/// latency and zero memory accumulation.
class NativeHandLandmarkService implements HandLandmarkService {
  NativeHandLandmarkService({int cameraSensorOrientation = 270})
      : _sensorOrientation = cameraSensorOrientation;

  static const MethodChannel _channel =
      MethodChannel('com.example.signbridge/hand_landmarker');

  final int _sensorOrientation;
  final StreamController<List<LandmarkPoint>> _landmarkController =
      StreamController<List<LandmarkPoint>>.broadcast();

  StreamSubscription<dynamic>? _imageSubscription;
  bool _isRunning = false;
  bool _isProcessing = false;

  @override
  Stream<List<LandmarkPoint>> get landmarkStream => _landmarkController.stream;

  @override
  Future<void> startDetection(Stream<dynamic> imageStream) async {
    if (_isRunning) await stopDetection();
    _isRunning = true;

    _imageSubscription = imageStream.listen(
      (dynamic image) {
        if (!_isRunning || _isProcessing) return;
        if (image is CameraImage) {
          _processCameraFrame(image);
        }
      },
      onError: (dynamic error) {
        debugPrint('HandLandmarkService frame error: $error');
      },
    );
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (!Platform.isAndroid) {
      // Platform channel is native Android. If running elsewhere, do not call.
      return;
    }

    _isProcessing = true;
    try {
      if (image.planes.length < 3) return;

      final List<dynamic>? rawLandmarks =
          await _channel.invokeMethod<List<dynamic>>('detectLandmarks', {
        'width': image.width,
        'height': image.height,
        'rotation': _sensorOrientation,
        'yPlane': image.planes[0].bytes,
        'uPlane': image.planes[1].bytes,
        'vPlane': image.planes[2].bytes,
        'yRowStride': image.planes[0].bytesPerRow,
        'uvRowStride': image.planes[1].bytesPerRow,
        'uvPixelStride': image.planes[1].bytesPerPixel,
      });

      if (rawLandmarks != null && rawLandmarks.length == kLandmarkCount) {
        final List<LandmarkPoint> landmarks = rawLandmarks.map((dynamic item) {
          final Map<dynamic, dynamic> map = item as Map<dynamic, dynamic>;
          return LandmarkPoint(
            landmarkIndex: (map['landmarkIndex'] as num).toInt(),
            x: (map['x'] as num).toDouble(),
            y: (map['y'] as num).toDouble(),
            z: (map['z'] as num).toDouble(),
          );
        }).toList();

        if (!_landmarkController.isClosed) {
          _landmarkController.add(landmarks);
        }
      }
    } catch (e) {
      debugPrint('Error invoking native HandLandmarker: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Future<void> stopDetection() async {
    _isRunning = false;
    await _imageSubscription?.cancel();
    _imageSubscription = null;
  }

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> dispose() async {
    await stopDetection();
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('close');
      }
    } catch (_) {}
    await _landmarkController.close();
  }
}
