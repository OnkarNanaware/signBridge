import 'dart:async';

import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/services/dtw_matcher_service.dart';

/// Mock [DtwMatcherService] that cycles through the vocabulary on a timer.
///
/// Emits a new [DtwMatch] every 3 seconds, cycling through:
/// HELLO → THANK YOU → HELP → YES → NO → (repeat).
/// Ignores calls to [addFrame] — the timer drives all output in demo mode.
class MockDtwMatcherService implements DtwMatcherService {
  static const List<String> _cycle = [
    'HELLO',
    'THANK YOU',
    'HELP',
    'YES',
    'NO',
  ];

  final StreamController<DtwMatch> _controller =
      StreamController<DtwMatch>.broadcast();
  Timer? _timer;
  int _cycleIndex = 0;

  @override
  Stream<DtwMatch> get matchStream => _controller.stream;

  /// Starts the mock emission timer. Called by the DI provider on first use.
  void startMockEmission() {
    _timer ??= Timer.periodic(
      const Duration(seconds: 3),
      (_) => _emitNext(),
    );
  }

  @override
  void addFrame(List<LandmarkPoint> frame) {
    // In mock mode, frames are ignored; the timer drives output.
    // TODO(phase2): Replace with real DTW computation in a background isolate.
  }

  @override
  void resetWindow() {
    // No-op in mock mode.
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _controller.close();
  }

  void _emitNext() {
    final String sign = _cycle[_cycleIndex % _cycle.length];
    _cycleIndex++;
    _controller.add(
      DtwMatch(
        signName: sign,
        confidence: 0.85 + (_cycleIndex % 5) * 0.02,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }
}
