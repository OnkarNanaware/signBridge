import 'package:hive/hive.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';

part 'sign_entry.g.dart';

/// A reference sign stored in the local sign library (Hive box).
///
/// Each entry holds the canonical sign name and the landmark sequence
/// captured during the recording phase. The sequence is a list of frames,
/// each frame being a list of 21 [LandmarkPoint]s.
@HiveType(typeId: 0)
class SignEntry extends HiveObject {
  SignEntry({
    required this.signName,
    required this.landmarkSequence,
    required this.dateRecorded,
  });

  /// Canonical display name (e.g. "HELLO", "THANK YOU").
  @HiveField(0)
  final String signName;

  /// Frame-by-frame sequence of 21 landmarks per frame.
  /// Outer list = frames, inner list = landmarks per frame.
  @HiveField(1)
  final List<List<LandmarkPoint>> landmarkSequence;

  /// UTC timestamp when this reference was recorded.
  @HiveField(2)
  final DateTime dateRecorded;

  /// Number of frames captured in this reference sequence.
  int get frameCount => landmarkSequence.length;

  @override
  String toString() =>
      'SignEntry(name=$signName, frames=$frameCount, '
      'recorded=${dateRecorded.toIso8601String()})';
}
