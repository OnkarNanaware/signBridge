import 'dart:async';
import 'dart:math';

import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/services/hand_landmark_service.dart';

/// Mock [HandLandmarkService] that emits synthetic 21-point landmark frames.
///
/// Emits a random set of 21 [LandmarkPoint]s every 33ms (~30 fps) so the
/// rest of the pipeline (DTW matcher, UI) can be tested without a camera.
class MockHandLandmarkService implements HandLandmarkService {
  final StreamController<List<LandmarkPoint>> _controller =
      StreamController<List<LandmarkPoint>>.broadcast();
  final Random _random = Random();
  Timer? _timer;
  bool _isRunning = false;

  @override
  Stream<List<LandmarkPoint>> get landmarkStream => _controller.stream;

  @override
  Future<void> startDetection(Stream<dynamic> imageStream) async {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _emitFrame(),
    );
  }

  @override
  Future<void> stopDetection() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  @override
  bool get isRunning => _isRunning;

  void _emitFrame() {
    final List<LandmarkPoint> frame = List.generate(
      kLandmarkCount,
      (int i) => LandmarkPoint(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        z: _random.nextDouble() * 0.1,
        landmarkIndex: i,
      ),
    );
    _controller.add(frame);
  }

  @override
  Future<void> dispose() async {
    await stopDetection();
    await _controller.close();
  }
}
