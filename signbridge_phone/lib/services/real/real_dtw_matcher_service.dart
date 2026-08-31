import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/core/models/sign_entry.dart';
import 'package:signbridge_phone/services/activity_log_service.dart';
import 'package:signbridge_phone/services/dtw_matcher_service.dart';
import 'package:signbridge_phone/services/sign_library_repository.dart';

/// Real [DtwMatcherService] running normalized Dynamic Time Warping in a worker isolate.
///
/// Features:
/// - Hand translation & scale normalization (wrist + middle MCP invariant).
/// - Sakoe-Chiba band pruning for accelerated DTW evaluation (<20ms).
/// - Pre-normalized reference caching to eliminate redundant sample normalization.
/// - Motion gating to skip computation when hand is static (conserving battery).
/// - Candidate hold tracking ([kSignHoldMs]) before committing a match.
/// - Mandatory telemetry logging to [ActivityLogService].
class RealDtwMatcherService implements DtwMatcherService {
  RealDtwMatcherService({
    required SignLibraryRepository signLibraryRepository,
    required ActivityLogService activityLogService,
    double maxDistanceThreshold = kDtwMaxDistance,
    double confidenceThreshold = kDtwConfidenceThreshold,
    int signHoldMs = kSignHoldMs,
    int windowFrames = kGestureWindowFrames,
  })  : _signLibraryRepository = signLibraryRepository,
        _activityLogService = activityLogService,
        _maxDistanceThreshold = maxDistanceThreshold,
        _confidenceThreshold = confidenceThreshold,
        _holdDurationMs = signHoldMs,
        _windowFrames = windowFrames;

  final SignLibraryRepository _signLibraryRepository;
  final ActivityLogService _activityLogService;
  final double _maxDistanceThreshold;
  final double _confidenceThreshold;
  final int _holdDurationMs;
  final int _windowFrames;

  final StreamController<DtwMatch> _matchController =
      StreamController<DtwMatch>.broadcast();

  // Gesture window buffer of landmark frames
  final List<List<LandmarkPoint>> _window = [];
  bool _isMatching = false;
  int _framesSinceLastMatch = 0;
  int _lastDurationMs = 12;

  // Cached pre-normalized reference sequences
  Map<String, List<List<List<List<double>>>>>? _cachedNormReferences;
  int _cachedSampleCount = 0;

  // Tracking candidate sign for hold-duration confirmation
  String? _candidateSign;
  DateTime? _candidateFirstSeen;

  @override
  Stream<DtwMatch> get matchStream => _matchController.stream;

  @override
  int get lastMatchDurationMs => _lastDurationMs;

  @override
  void addFrame(List<LandmarkPoint> frame) {
    if (frame.length != 21) return;

    _window.add(frame);
    if (_window.length > _windowFrames) {
      _window.removeAt(0);
    }

    _framesSinceLastMatch++;

    // Evaluate once we have at least 15 frames, every 2 frames when idle
    if (!_isMatching && _window.length >= 15 && _framesSinceLastMatch >= 2) {
      _runMatchPass();
    }
  }

  Future<void> _runMatchPass() async {
    _isMatching = true;
    final Stopwatch stopwatch = Stopwatch()..start();

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

      // Convert live window to coordinates
      final List<List<List<double>>> windowVectors = _window
          .map(
            (List<LandmarkPoint> frame) =>
                frame.map((LandmarkPoint p) => [p.x, p.y, p.z]).toList(),
          )
          .toList();

      // Motion gate: verify whether hand has sufficient displacement
      if (!_hasMotion(windowVectors)) {
        return;
      }

      // Update cached normalized references if library changed
      if (_cachedNormReferences == null ||
          _cachedSampleCount != allSigns.length) {
        _cachedNormReferences = _buildNormalizedReferences(allSigns);
        _cachedSampleCount = allSigns.length;
      }

      final Map<String, List<List<List<List<double>>>>> refMap =
          _cachedNormReferences!;
      if (refMap.isEmpty) return;

      final _DtwParams params = _DtwParams(
        liveWindow: windowVectors,
        referenceSigns: refMap,
        maxDistance: _maxDistanceThreshold,
      );

      await _activityLogService.log(
        EventType.dtwMatchRun,
        'DTW evaluating ${refMap.length} signs (${allSigns.length} samples) '
        'against ${_window.length} frames',
      );

      // Execute DTW algorithm in background isolate
      final _DtwEvalResult eval =
          await Isolate.run(() => _dtwIsolateEntry(params));

      stopwatch.stop();
      _lastDurationMs = stopwatch.elapsedMilliseconds;

      if (eval.bestSign != null && eval.confidence >= _confidenceThreshold) {
        final String sign = eval.bestSign!;
        final DateTime now = DateTime.now();

        if (_candidateSign == sign) {
          final int holdDuration =
              now.difference(_candidateFirstSeen!).inMilliseconds;
          if (holdDuration >= _holdDurationMs) {
            final DtwMatch match = DtwMatch(
              signName: sign,
              confidence: eval.confidence,
              timestamp: now,
            );

            if (!_matchController.isClosed) {
              _matchController.add(match);
            }

            await _activityLogService.log(
              EventType.dtwMatchResult,
              'Matched sign "$sign" (${(eval.confidence * 100).toStringAsFixed(1)}% conf, ${_lastDurationMs}ms)',
            );

            _candidateSign = null;
            _candidateFirstSeen = null;
            _framesSinceLastMatch = 0;
            _window.clear();
          }
        } else {
          _candidateSign = sign;
          _candidateFirstSeen = now;
        }
      } else {
        _candidateSign = null;
        _candidateFirstSeen = null;
      }
    } catch (e) {
      debugPrint('RealDtwMatcherService exception: $e');
    } finally {
      _isMatching = false;
    }
  }

  /// Checks whether landmarks have moved significantly to justify DTW execution.
  bool _hasMotion(List<List<List<double>>> window) {
    if (window.length < 5) return true;
    final List<List<double>> first = window.first;
    final List<List<double>> last = window.last;

    double maxDelta = 0.0;
    for (int i = 0; i < first.length; i++) {
      final double dx = (first[i][0] - last[i][0]).abs();
      final double dy = (first[i][1] - last[i][1]).abs();
      if (dx + dy > maxDelta) maxDelta = dx + dy;
    }
    // Very gentle motion threshold (0.015 of screen coordinate)
    return maxDelta >= 0.015;
  }

  /// Builds pre-normalized reference sequences for fast matching.
  Map<String, List<List<List<List<double>>>>> _buildNormalizedReferences(
    List<SignEntry> allSigns,
  ) {
    final Map<String, List<List<List<List<double>>>>> map = {};
    for (final SignEntry entry in allSigns) {
      if (entry.landmarkSequence.length < 5) continue;
      final List<List<List<double>>> rawSample = entry.landmarkSequence
          .map(
            (List<LandmarkPoint> frame) =>
                frame.map((LandmarkPoint p) => [p.x, p.y, p.z]).toList(),
          )
          .toList();
      final List<List<List<double>>> normSample = _normalizeSequence(rawSample);
      map.putIfAbsent(entry.signName, () => []).add(normSample);
    }
    return map;
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

  params.referenceSigns.forEach(
    (String signName, List<List<List<List<double>>>> samples) {
      for (final List<List<List<double>>> normSample in samples) {
        final double dist = _computeDtwDistance(
          normWindow,
          normSample,
          lowestDistance,
        );

        if (dist < lowestDistance) {
          lowestDistance = dist;
          bestSign = signName;
        }
      }
    },
  );

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
/// 2. Scales by distance from wrist (0) to middle finger MCP (9).
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

/// Computes normalized Dynamic Time Warping distance with Sakoe-Chiba band pruning.
double _computeDtwDistance(
  List<List<List<double>>> a,
  List<List<List<double>>> b,
  double currentBest,
) {
  final int n = a.length;
  final int m = b.length;

  if (n == 0 || m == 0) return double.infinity;

  // Sakoe-Chiba constraint window
  final int window = math.max(6, (n - m).abs() + 6);

  final List<double> prev = List<double>.filled(m + 1, double.infinity);
  final List<double> curr = List<double>.filled(m + 1, double.infinity);

  prev[0] = 0.0;

  for (int i = 1; i <= n; i++) {
    curr[0] = double.infinity;
    final int jStart = math.max(1, i - window);
    final int jEnd = math.min(m, i + window);

    for (int j = 1; j < jStart; j++) {
      curr[j] = double.infinity;
    }

    for (int j = jStart; j <= jEnd; j++) {
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

    for (int j = jEnd + 1; j <= m; j++) {
      curr[j] = double.infinity;
    }

    for (int j = 0; j <= m; j++) {
      prev[j] = curr[j];
    }
  }

  return prev[m] / (n + m);
}

class _DtwParams {
  const _DtwParams({
    required this.liveWindow,
    required this.referenceSigns,
    required this.maxDistance,
  });

  final List<List<List<double>>> liveWindow;
  final Map<String, List<List<List<List<double>>>>> referenceSigns;
  final double maxDistance;
}

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
