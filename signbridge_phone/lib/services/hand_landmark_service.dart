import 'package:signbridge_phone/core/models/landmark_point.dart';

/// Abstract interface for MediaPipe Hands landmark extraction.
///
/// In Phase 2 the real implementation will call through an Android
/// platform channel to the MediaPipe Tasks Hand Landmarker. The mock
/// implementation emits synthetic 21-point frames on a timer so the rest
/// of the pipeline can be exercised without hardware.
abstract class HandLandmarkService {
  /// A broadcast stream of detected hand frames.
  ///
  /// Each event is a list of exactly 21 [LandmarkPoint]s for one hand.
  /// Frames are emitted at the camera frame rate (target 30fps).
  /// If no hand is detected the stream is silent (no null events emitted).
  Stream<List<LandmarkPoint>> get landmarkStream;

  /// Starts landmark detection on the given camera image stream.
  ///
  /// [imageStream] should be the raw bytes of each camera frame in the
  /// format expected by the platform channel (YUV420 for Android).
  Future<void> startDetection(Stream<dynamic> imageStream);

  /// Stops detection and releases native resources.
  Future<void> stopDetection();

  /// Whether the landmark service is currently running.
  bool get isRunning;

  /// Disposes the service and closes all streams.
  Future<void> dispose();
}
