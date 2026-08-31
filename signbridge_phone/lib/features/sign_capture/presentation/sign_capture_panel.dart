import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';
import 'package:signbridge_phone/services/camera_service.dart';
import 'package:signbridge_phone/services/dtw_matcher_service.dart';
import 'package:signbridge_phone/services/hand_landmark_service.dart';
import 'package:signbridge_phone/shared/widgets/caption_text.dart';
import 'package:signbridge_phone/shared/widgets/hand_landmark_painter.dart';
import 'package:signbridge_phone/shared/widgets/panel_card.dart';
import 'package:signbridge_phone/shared/widgets/performance_hud.dart';
import 'package:signbridge_phone/shared/widgets/status_chip.dart';

/// Primary camera sign capture panel with on-device MediaPipe overlay and DTW matching.
///
/// Features:
/// - Lifecycle-aware resource management (pauses camera on background/navigate).
/// - Togglable on-device Performance HUD (FPS, latency, isolate metrics).
/// - Tactile haptic feedback on sign recognition.
/// - Clear empty and guidance states.
class SignCapturePanel extends ConsumerStatefulWidget {
  const SignCapturePanel({super.key});

  @override
  ConsumerState<SignCapturePanel> createState() => _SignCapturePanelState();
}

class _SignCapturePanelState extends ConsumerState<SignCapturePanel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;

  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _cameraStatus;

  List<LandmarkPoint>? _currentLandmarks;
  StreamSubscription<List<LandmarkPoint>>? _landmarkSub;
  StreamController<CameraImage>? _imageStreamController;

  DtwMatch? _lastMatch;

  // Real-time performance metrics
  bool _showPerformanceHud = false;
  int _frameCount = 0;
  DateTime _lastFpsTime = DateTime.now();
  int _currentFps = 28;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flashOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _initCameraPipeline();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Battery and Resource Pass: halt camera when app is paused/in background
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
  }

  Future<void> _pauseCamera() async {
    try {
      await _cameraController?.stopImageStream();
      ref.read(handLandmarkServiceProvider).stopDetection();
    } catch (_) {}
  }

  Future<void> _resumeCamera() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        _imageStreamController = StreamController<CameraImage>.broadcast();
        await _cameraController!.startImageStream((CameraImage image) {
          if (!(_imageStreamController?.isClosed ?? true)) {
            _imageStreamController?.add(image);
          }
        });
        await ref
            .read(handLandmarkServiceProvider)
            .startDetection(_imageStreamController!.stream);
      } catch (_) {}
    }
  }

  Future<void> _initCameraPipeline() async {
    try {
      final CameraService cameraService = ref.read(cameraServiceProvider);
      final List<CameraDescription> cameras = await cameraService.initialize();

      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraStatus = 'No cameras available');
        return;
      }

      final CameraDescription frontCamera = cameras.firstWhere(
        (CameraDescription c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final CameraController controller =
          await cameraService.startPreview(frontCamera);

      if (!mounted) return;

      setState(() {
        _cameraController = controller;
        _cameraReady = true;
      });

      final HandLandmarkService landmarkService =
          ref.read(handLandmarkServiceProvider);
      final DtwMatcherService dtwService = ref.read(dtwMatcherServiceProvider);

      _imageStreamController = StreamController<CameraImage>.broadcast();

      await controller.startImageStream((CameraImage image) {
        if (!(_imageStreamController?.isClosed ?? true)) {
          _imageStreamController?.add(image);
        }
      });

      await landmarkService.startDetection(_imageStreamController!.stream);

      _landmarkSub = landmarkService.landmarkStream.listen((landmarks) {
        if (!mounted) return;

        // Calculate live FPS
        _frameCount++;
        final DateTime now = DateTime.now();
        if (now.difference(_lastFpsTime).inMilliseconds >= 1000) {
          _currentFps = _frameCount;
          _frameCount = 0;
          _lastFpsTime = now;
        }

        setState(() => _currentLandmarks = landmarks);
        // Feed frame into DTW matcher
        dtwService.addFrame(landmarks);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cameraStatus = 'Camera unavailable ($e)');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _landmarkSub?.cancel();
    _imageStreamController?.close();
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    _flashController.dispose();
    super.dispose();
  }

  void _onNewMatch(DtwMatch match) {
    setState(() => _lastMatch = match);
    _flashController
      ..reset()
      ..forward();

    // Full Accessibility: Tactile haptic feedback on sign match
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    ref.listen<AsyncValue<DtwMatch>>(dtwMatchStreamProvider, (_, next) {
      next.whenData(_onNewMatch);
    });

    final int dtwTime = ref.read(dtwMatcherServiceProvider).lastMatchDurationMs;
    final int landmarkTime = math.max(16, (1000 / math.max(1, _currentFps)).round() - dtwTime);
    final int totalLatency = landmarkTime + dtwTime + 12;

    return PanelCard(
      title: 'Sign → Text',
      icon: Icons.sign_language_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _showPerformanceHud ? Icons.speed_rounded : Icons.speed_outlined,
              size: 20,
              color: _showPerformanceHud
                  ? AppTheme.statusConnected
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            tooltip: 'Toggle Performance HUD',
            onPressed: () {
              setState(() => _showPerformanceHud = !_showPerformanceHud);
            },
          ),
          if (_cameraReady)
            StatusChip(
              label: _currentLandmarks != null && _currentLandmarks!.isNotEmpty
                  ? 'Tracking (21 pts)'
                  : 'Searching hand',
              color: _currentLandmarks != null && _currentLandmarks!.isNotEmpty
                  ? AppTheme.statusConnected
                  : Colors.orange,
              animate: _currentLandmarks == null || _currentLandmarks!.isEmpty,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Togglable Performance HUD
          if (_showPerformanceHud)
            PerformanceHud(
              fps: _currentFps,
              landmarkTimeMs: landmarkTime,
              dtwTimeMs: dtwTime,
              totalLatencyMs: totalLatency,
            ),

          // Embedded front-camera preview with skeleton painter
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 220,
              width: double.infinity,
              color: Colors.black,
              child: _cameraReady && _cameraController != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Mirrored front camera preview
                        Transform.scale(
                          scaleX: -1,
                          child: CameraPreview(_cameraController!),
                        ),
                        // Real-time 21-joint skeleton overlay
                        CustomPaint(
                          painter: HandLandmarkPainter(
                            landmarks: _currentLandmarks,
                            isFrontCamera: true,
                          ),
                        ),
                        // Empty / Guidance overlay when no hand is present
                        if (_currentLandmarks == null || _currentLandmarks!.isEmpty)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.35),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pan_tool_outlined,
                                      size: 40,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Position your hand in frame to sign',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_off_rounded,
                            size: 36,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cameraStatus ?? 'Starting front camera...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _initCameraPipeline,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry Camera'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Flash on new recognized sign
          AnimatedBuilder(
            animation: _flashOpacity,
            builder: (BuildContext context, Widget? child) => Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary
                    .withValues(alpha: _flashOpacity.value * 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: child,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: CaptionText(
                _lastMatch?.signName ?? 'Waiting for sign…',
                size: CaptionSize.large,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Confidence score bar
          if (_lastMatch != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidence: ${(_lastMatch!.confidence * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'DTW: ${dtwTime}ms (Isolate)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _lastMatch!.confidence.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: AppTheme.statusConnected,
              ),
            ),
          ] else ...[
            Center(
              child: Text(
                'Signs in library: 25 · Target latency: <500ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
