/// The result of a single DTW matching pass against the sign library.
class DtwMatch {
  const DtwMatch({
    required this.signName,
    required this.confidence,
    required this.timestamp,
  });

  /// Canonical name of the best-matching sign (e.g. "HELLO").
  final String signName;

  /// Normalised confidence score in the range [0.0, 1.0].
  /// Values below [kDtwConfidenceThreshold] should be discarded by the caller.
  final double confidence;

  /// UTC timestamp when this match was produced.
  final DateTime timestamp;

  /// Returns true if this match meets the confidence threshold.
  bool isAboveThreshold(double threshold) => confidence >= threshold;

  @override
  String toString() =>
      'DtwMatch(sign=$signName, '
      'confidence=${confidence.toStringAsFixed(3)}, '
      'ts=${timestamp.millisecondsSinceEpoch})';
}
