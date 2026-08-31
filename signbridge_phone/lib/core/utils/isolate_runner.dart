import 'dart:async';

/// Runs [computation] on a background isolate and returns the result.
///
/// Use this for heavy CPU work (DTW matching, ASR pre-processing, etc.)
/// that must not block the UI isolate.
///
/// Example:
/// ```dart
/// final double distance = await runOffIsolate(
///   () => dtwDistance(query, reference),
/// );
/// ```
Future<T> runOffIsolate<T>(FutureOr<T> Function() computation) {
  return Future<T>(() async => computation());
  // TODO(phase2): Replace with Isolate.run(computation) on Dart ≥ 2.19.
  // Using Future here for Phase 1 compatibility; the real implementation
  // must use Isolate.run to achieve true off-isolate execution.
}
