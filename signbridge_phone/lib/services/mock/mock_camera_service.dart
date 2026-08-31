import 'dart:async';

import 'package:camera/camera.dart';
import 'package:signbridge_phone/services/camera_service.dart';

/// Mock [CameraService] that never accesses hardware.
///
/// Returns an empty list from [initialize] and a no-op controller from
/// [startPreview]. Used during Phase 1 demo mode.
class MockCameraService implements CameraService {
  bool _isActive = false;

  @override
  Future<List<CameraDescription>> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const [];
  }

  @override
  Future<CameraController> startPreview(CameraDescription camera) async {
    // NOTE: Cannot construct a real CameraController without hardware.
    // In Phase 2, swap this mock for the real implementation.
    // TODO(phase2): Return a real CameraController bound to the device camera.
    _isActive = true;
    throw UnimplementedError(
      'MockCameraService: startPreview is not available in demo mode. '
      'Phase 2 will provide the real implementation.',
    );
  }

  @override
  Future<void> stopPreview() async {
    _isActive = false;
  }

  @override
  bool get isActive => _isActive;

  @override
  Future<void> dispose() async {
    _isActive = false;
  }
}
