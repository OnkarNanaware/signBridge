import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
import 'package:signbridge_phone/shared/widgets/status_chip.dart';

/// Panel that displays live camera feed, real-time hand landmark overlays,
/// and recognized sign results from the DTW matcher.
class SignCapturePanel extends ConsumerStatefulWidget {
  const SignCapturePanel({super.key});

  @override
  ConsumerState<SignCapturePanel> createState() => _SignCapturePanelState();
}

class _SignCapturePanelState extends ConsumerState<SignCapturePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;

  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _cameraStatus;

  List<LandmarkPoint>? _currentLandmarks;
  StreamSubscription<List<LandmarkPoint>>? _landmarkSub;
  StreamController<CameraImage>? _imageStreamController;

  DtwMatch? _lastMatch;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flashOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _initCameraPipeline();
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
        setState(() => _currentLandmarks = landmarks);
        // Feed frame into DTW matcher
        dtwService.addFrame(landmarks);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cameraStatus = 'Camera offline ($e)');
      }
    }
  }

  @override
  void dispose() {
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
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    ref.listen<AsyncValue<DtwMatch>>(dtwMatchStreamProvider, (_, next) {
      next.whenData(_onNewMatch);
    });

    final String signText = _lastMatch?.signName ?? '—';
    final double confidence = _lastMatch?.confidence ?? 0.0;
    final bool hasMatch = _lastMatch != null;
    final bool handDetected =
        _currentLandmarks != null && _currentLandmarks!.isNotEmpty;

    return PanelCard(
      title: 'Sign → Text',
      icon: Icons.sign_language_rounded,
      trailing: StatusChip(
        label: useMockServices
            ? 'Demo'
            : _cameraReady
                ? 'Front Camera · 30 FPS'
                : 'Camera Off',
        color: useMockServices
            ? AppTheme.demoBannerBg
            : _cameraReady
                ? AppTheme.statusConnected
                : AppTheme.statusDisconnected,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Camera Preview with Landmark Overlay ─────────────────────────
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: handDetected
                    ? AppTheme.statusConnected.withValues(alpha: 0.6)
                    : theme.colorScheme.outline.withValues(alpha: 0.15),
                width: handDetected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cameraReady && _cameraController != null)
                  CameraPreview(_cameraController!)
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_outlined,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _cameraStatus ?? 'Initializing front camera…',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // 21-point hand landmark skeleton overlay
                if (handDetected)
                  CustomPaint(
                    painter: HandLandmarkPainter(
                      landmarks: _currentLandmarks,
                      isFrontCamera: true,
                    ),
                  ),

                // Hand detection badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: handDetected
                                ? AppTheme.statusConnected
                                : Colors.orangeAccent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          handDetected
                              ? 'Hand Tracked (21 pts)'
                              : 'Waiting for hand…',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Main caption display ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _flashOpacity,
            builder: (BuildContext context, Widget? child) => Container(
              decoration: BoxDecoration(
                color: hasMatch
                    ? theme.colorScheme.primary
                        .withValues(alpha: _flashOpacity.value * 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: child,
            ),
            child: CaptionText(
              signText,
              size: CaptionSize.large,
            ),
          ),
          const SizedBox(height: 10),

          // ── Confidence bar ────────────────────────────────────────────────
          if (hasMatch) ...[
            Row(
              children: [
                Text(
                  'Confidence',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidence,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        confidence > 0.85
                            ? AppTheme.statusConnected
                            : AppTheme.statusSearching,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(confidence * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Perform a sign toward the camera…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
