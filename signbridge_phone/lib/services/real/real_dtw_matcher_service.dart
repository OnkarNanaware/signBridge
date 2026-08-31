import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/core/models/sign_entry.dart';
import 'package:signbridge_phone/services/activity_log_service.dart';
import 'package:signbridge_phone/services/dtw_matcher_service.dart';
import 'package:signbridge_phone/services/sign_library_repository.dart';

/// Serializable DTO for running DTW matching across isolates.
class _DtwParams {
  const _DtwParams({
    required this.liveWindow,
    required this.referenceSigns,
    required this.maxDistance,
  });

  /// [frameCount][21 landmarks][3 coords (x,y,z)]
  final List<List<List<double>>> liveWindow;

  /// Map of sign name -> list of samples (each sample is a frame sequence)
  final Map<String, List<List<List<List<double>>>>> referenceSigns;

  final double maxDistance;
}

/// Result returned from background isolate DTW evaluation.
class _DtwEvalResult {
  const _DtwEvalResult({
    required this.bestSign,
    required this.confidence,
    required this.distance,
  });

  final String? bestSign;
  final double confidence;
  final double distance;
}

/// Real [DtwMatcherService] implementing Dynamic Time Warping in pure Dart.
///
/// Features:
/// - Translation & scale normalization relative to the palm.
/// - Multi-sample matching across all references in [SignLibraryRepository].
/// - Execution on background isolate via [Isolate.run] to protect UI frame rate.
/// - Minimum hold duration ([kSignHoldMs]) before committing a match.
/// - Mandatory logging of every match attempt to [ActivityLogService].
class RealDtwMatcherService implements DtwMatcherService {
  RealDtwMatcherService({
    required SignLibraryRepository signLibraryRepository,
    required ActivityLogService activityLogService,
    double confidenceThreshold = kDtwConfidenceThreshold,
    double maxDistanceThreshold = kDtwMaxDistance,
    int signHoldMs = kSignHoldMs,
  })  : _signLibraryRepository = signLibraryRepository,
        _activityLogService = activityLogService,
        _confidenceThreshold = confidenceThreshold,
        _maxDistanceThreshold = maxDistanceThreshold,
        _signHoldMs = signHoldMs;

  final SignLibraryRepository _signLibraryRepository;
  final ActivityLogService _activityLogService;
  final double _confidenceThreshold;
  final double _maxDistanceThreshold;
  final int _signHoldMs;

  final StreamController<DtwMatch> _matchController =
      StreamController<DtwMatch>.broadcast();

  final List<List<LandmarkPoint>> _window = [];
  bool _isMatching = false;
  int _framesSinceLastMatch = 0;

  // Hold tracking
  String? _candidateSign;
  DateTime? _candidateFirstSeen;

  @override
  Stream<DtwMatch> get matchStream => _matchController.stream;

  @override
  void addFrame(List<LandmarkPoint> frame) {
    if (frame.length != kLandmarkCount) return;

    _window.add(frame);
    if (_window.length > kGestureWindowFrames) {
      _window.removeAt(0);
    }

    _framesSinceLastMatch++;

    // Trigger DTW match pass every 5 frames (~150ms at 30fps) if window is ready
    if (_framesSinceLastMatch >= 5 && _window.length >= 12 && !_isMatching) {
      _framesSinceLastMatch = 0;
      _runMatchPass();
    }
  }

  Future<void> _runMatchPass() async {
    _isMatching = true;
    try {
      final List<SignEntry> allSigns =
          await _signLibraryRepository.getAllSigns();

      if (allSigns.isEmpty) {
        await _activityLogService.log(
          EventType.dtwMatchRun,
          'DTW match pass: sign library is empty (0 references)',
        );
        return;
      }

      // Convert window to serializable coordinates
      final List<List<List<double>>> windowVectors = _window
          .map(
            (List<LandmarkPoint> frame) =>
                frame.map((LandmarkPoint p) => [p.x, p.y, p.z]).toList(),
          )
          .toList();

      // Group samples by sign name
      final Map<String, List<List<List<List<double>>>>> refMap = {};
      for (final SignEntry entry in allSigns) {
        if (entry.landmarkSequence.length < 5) continue;
        final List<List<List<double>>> sample = entry.landmarkSequence
            .map(
              (List<LandmarkPoint> frame) =>
                  frame.map((LandmarkPoint p) => [p.x, p.y, p.z]).toList(),
            )
            .toList();
        refMap.putIfAbsent(entry.signName, () => []).add(sample);
      }

      if (refMap.isEmpty) return;

      final _DtwParams params = _DtwParams(
        liveWindow: windowVectors,
        referenceSigns: refMap,
        maxDistance: _maxDistanceThreshold,
      );

      // Log the match attempt
      await _activityLogService.log(
        EventType.dtwMatchRun,
        'DTW evaluating ${refMap.length} signs (${allSigns.length} samples) '
        'against ${_window.length} frames',
      );

      // Execute DTW algorithm off the UI isolate
      final _DtwEvalResult eval = await Isolate.run(() => _dtwIsolateEntry(params));

      if (eval.bestSign != null && eval.confidence >= _confidenceThreshold) {
        final String sign = eval.bestSign!;
        final DateTime now = DateTime.now();

        if (_candidateSign == sign) {
          final int holdDuration =
              now.difference(_candidateFirstSeen!).inMilliseconds;
          if (holdDuration >= _signHoldMs) {
            // Sign held long enough -> commit match
            final DtwMatch match = DtwMatch(
              signName: sign,
              confidence: eval.confidence,
              timestamp: now.toUtc(),
            );
            if (!_matchController.isClosed) {
              _matchController.add(match);
            }
            await _activityLogService.log(
              EventType.dtwMatchResult,
              'Committed match: $sign (${(eval.confidence * 100).toStringAsFixed(1)}%) '
              'after ${holdDuration}ms hold',
            );
            // Reset hold candidate
            _candidateSign = null;
            _candidateFirstSeen = null;
          }
        } else {
          _candidateSign = sign;
          _candidateFirstSeen = now;
        }
      } else {
        _candidateSign = null;
        _candidateFirstSeen = null;
        await _activityLogService.log(
          EventType.dtwMatchResult,
          'No match above threshold (best: ${eval.bestSign ?? 'none'} '
          'at ${(eval.confidence * 100).toStringAsFixed(1)}%)',
        );
      }
    } catch (e) {
      await _activityLogService.log(
        EventType.error,
        'DTW match pass failed: $e',
      );
    } finally {
      _isMatching = false;
    }
  }

  @override
  void resetWindow() {
    _window.clear();
    _framesSinceLastMatch = 0;
    _candidateSign = null;
    _candidateFirstSeen = null;
  }

  @override
  Future<void> dispose() async {
    resetWindow();
    await _matchController.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pure DTW isolate calculation functions
// ─────────────────────────────────────────────────────────────────────────────

_DtwEvalResult _dtwIsolateEntry(_DtwParams params) {
  final List<List<List<double>>> normWindow =
      _normalizeSequence(params.liveWindow);

  String? bestSign;
  double lowestDistance = double.infinity;

  params.referenceSigns.forEach((String signName, List<List<List<List<double>>>> samples) {
    for (final List<List<List<double>>> rawSample in samples) {
      final List<List<List<double>>> normSample = _normalizeSequence(rawSample);
      final double dist = _computeDtwDistance(normWindow, normSample);

      if (dist < lowestDistance) {
        lowestDistance = dist;
        bestSign = signName;
      }
    }
  });

  if (lowestDistance <= params.maxDistance && bestSign != null) {
    final double confidence =
        (1.0 - (lowestDistance / params.maxDistance)).clamp(0.0, 1.0);
    return _DtwEvalResult(
      bestSign: bestSign,
      confidence: confidence,
      distance: lowestDistance,
    );
  }

  return _DtwEvalResult(
    bestSign: bestSign,
    confidence: 0.0,
    distance: lowestDistance,
  );
}

/// Normalizes a sequence of hand landmark frames:
/// 1. Centers all points relative to wrist (index 0).
/// 2. Scales by the distance from wrist (0) to middle finger MCP (9).
List<List<List<double>>> _normalizeSequence(List<List<List<double>>> sequence) {
  return sequence.map((List<List<double>> frame) {
    if (frame.length < 21) return frame;

    final double wristX = frame[0][0];
    final double wristY = frame[0][1];
    final double wristZ = frame[0][2];

    final double midX = frame[9][0] - wristX;
    final double midY = frame[9][1] - wristY;
    final double midZ = frame[9][2] - wristZ;

    final double scale = math.sqrt(midX * midX + midY * midY + midZ * midZ);
    final double safeScale = scale > 0.001 ? scale : 1.0;

    return frame.map((List<double> pt) {
      return [
        (pt[0] - wristX) / safeScale,
        (pt[1] - wristY) / safeScale,
        (pt[2] - wristZ) / safeScale,
      ];
    }).toList();
  }).toList();
}

/// Euclidean distance between two normalized 21-landmark frames.
double _frameDistance(List<List<double>> f1, List<List<double>> f2) {
  double sum = 0.0;
  for (int i = 0; i < 21; i++) {
    final double dx = f1[i][0] - f2[i][0];
    final double dy = f1[i][1] - f2[i][1];
    final double dz = f1[i][2] - f2[i][2];
    sum += math.sqrt(dx * dx + dy * dy + dz * dz);
  }
  return sum / 21.0;
}

/// Computes normalized Dynamic Time Warping distance between sequences A and B.
double _computeDtwDistance(
  List<List<List<double>>> a,
  List<List<List<double>>> b,
) {
  final int n = a.length;
  final int m = b.length;

  if (n == 0 || m == 0) return double.infinity;

  // Use 1D array to optimize memory during DTW matrix evaluation
  final List<double> prev = List<double>.filled(m + 1, double.infinity);
  final List<double> curr = List<double>.filled(m + 1, double.infinity);

  prev[0] = 0.0;

  for (int i = 1; i <= n; i++) {
    curr[0] = double.infinity;
    for (int j = 1; j <= m; j++) {
      final double cost = _frameDistance(a[i - 1], b[j - 1]);
      final double minPrev = math.min(
        prev[j], // insertion
        math.min(
          curr[j - 1], // deletion
          prev[j - 1], // match
        ),
      );
      curr[j] = cost + minPrev;
    }
    for (int j = 0; j <= m; j++) {
      prev[j] = curr[j];
    }
  }

  // Normalized distance by total path length
  return prev[m] / (n + m);
}
