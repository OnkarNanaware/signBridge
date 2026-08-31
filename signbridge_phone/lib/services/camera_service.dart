import 'package:camera/camera.dart';

/// Abstract interface for the device camera.
///
/// The real implementation wraps the `camera` package. The mock
/// implementation returns immediately without accessing hardware.
abstract class CameraService {
  /// Initialises the camera and returns the available [CameraDescription]s.
  ///
  /// Must be called before [startPreview].
  Future<List<CameraDescription>> initialize();

  /// Starts the camera preview using the given [camera].
  ///
  /// Returns a [CameraController] that the UI layer can use to display the
  /// preview widget.
  Future<CameraController> startPreview(CameraDescription camera);

  /// Stops the active camera preview and releases hardware resources.
  Future<void> stopPreview();

  /// Whether the camera is currently streaming frames.
  bool get isActive;

  /// Disposes all resources held by this service.
  Future<void> dispose();
}
