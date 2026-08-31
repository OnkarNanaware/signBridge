import 'package:camera/camera.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/services/activity_log_service.dart';
import 'package:signbridge_phone/services/camera_service.dart';

/// Real [CameraService] wrapping the official `camera` package.
///
/// Configured for front camera sign-language frame streaming. Automatically
/// logs `cameraActivated` and `cameraDeactivated` events to [ActivityLogService].
class RealCameraService implements CameraService {
  RealCameraService(this._activityLogService);

  final ActivityLogService _activityLogService;
  CameraController? _controller;
  CameraDescription? _activeCamera;
  bool _isActive = false;

  /// The active [CameraController], or null if preview has not been started.
  CameraController? get controller => _controller;

  /// The currently active [CameraDescription], or null.
  CameraDescription? get activeCamera => _activeCamera;

  @override
  Future<List<CameraDescription>> initialize() async {
    return await availableCameras();
  }

  @override
  Future<CameraController> startPreview(CameraDescription camera) async {
    // If an existing preview is running, stop it first
    if (_controller != null) {
      await stopPreview();
    }

    _activeCamera = camera;
    final CameraController controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller.initialize();
    _controller = controller;
    _isActive = true;

    await _activityLogService.log(
      EventType.cameraActivated,
      'Camera activated: ${camera.lensDirection.name} (${camera.name})',
    );

    return controller;
  }

  @override
  Future<void> stopPreview() async {
    if (_controller != null) {
      final String camName = _activeCamera?.name ?? 'camera';
      try {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
      } catch (_) {
        // Ignore disposal errors on teardown
      } finally {
        _controller = null;
        _activeCamera = null;
        _isActive = false;
        await _activityLogService.log(
          EventType.cameraDeactivated,
          'Camera deactivated: $camName',
        );
      }
    }
  }

  @override
  bool get isActive => _isActive && _controller != null && _controller!.value.isInitialized;

  @override
  Future<void> dispose() async {
    await stopPreview();
  }
}
