import 'package:hive/hive.dart';

part 'landmark_point.g.dart';

/// A single 3D landmark point from MediaPipe Hands.
///
/// [x], [y], [z] are normalised coordinates (0.0–1.0) relative to the
/// bounding box of the detected hand. [landmarkIndex] corresponds to the
/// MediaPipe landmark ID (0–20).
@HiveType(typeId: 2)
class LandmarkPoint extends HiveObject {
  LandmarkPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.landmarkIndex,
  });

  @HiveField(0)
  final double x;

  @HiveField(1)
  final double y;

  @HiveField(2)
  final double z;

  /// MediaPipe landmark index (0 = wrist, 4 = thumb tip, 8 = index tip …).
  @HiveField(3)
  final int landmarkIndex;

  /// Converts to a flat feature vector [x, y, z] for DTW distance computation.
  List<double> toFeatureVector() => [x, y, z];

  @override
  String toString() =>
      'LandmarkPoint(idx=$landmarkIndex, x=${x.toStringAsFixed(3)}, '
      'y=${y.toStringAsFixed(3)}, z=${z.toStringAsFixed(3)})';
}
