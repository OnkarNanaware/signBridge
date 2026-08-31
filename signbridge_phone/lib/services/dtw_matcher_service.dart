import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';

/// Abstract interface for the DTW (Dynamic Time Warping) sign matching engine.
///
/// Consumes frames of 21 [LandmarkPoint]s from [HandLandmarkService] and
/// emits [DtwMatch] events when a recognised sign is held for the required
/// minimum duration. All computation MUST run off the UI isolate.
abstract class DtwMatcherService {
  /// A broadcast stream of committed DTW match events.
  ///
  /// Only emits when a match exceeds [kDtwConfidenceThreshold] and has been
  /// held for [kSignHoldMs] milliseconds.
  Stream<DtwMatch> get matchStream;

  /// Feeds a new frame of landmarks into the DTW gesture window.
  ///
  /// Call this once per camera frame when landmarks are available.
  /// Internally buffers frames up to [kGestureWindowFrames] and runs
  /// DTW matching asynchronously on a background isolate.
  void addFrame(List<LandmarkPoint> frame);

  /// Clears the current gesture window (e.g. after a committed match).
  void resetWindow();

  /// Duration of the most recent DTW matching evaluation in milliseconds.
  int get lastMatchDurationMs;

  /// Disposes the service and closes the match stream.
  Future<void> dispose();
}
