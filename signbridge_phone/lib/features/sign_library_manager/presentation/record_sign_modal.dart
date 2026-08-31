import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/core/models/sign_entry.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';
import 'package:signbridge_phone/services/camera_service.dart';
import 'package:signbridge_phone/services/hand_landmark_service.dart';
import 'package:signbridge_phone/shared/widgets/hand_landmark_painter.dart';

/// Modal dialog/sheet for recording reference sign samples.
///
/// Features:
/// - Live front camera feed with real-time 21-point hand landmark overlay.
/// - Hold-to-record button that captures landmark frames continuously while pressed.
/// - Persists sample to Hive [kSignLibraryBox] upon release if >= 10 frames.
/// - Allows capturing multiple samples per sign for enhanced DTW robustness.
class RecordSignModal extends ConsumerStatefulWidget {
  const RecordSignModal({
    required this.signName,
    super.key,
  });

  final String signName;

  @override
  ConsumerState<RecordSignModal> createState() => _RecordSignModalState();
}

class _RecordSignModalState extends ConsumerState<RecordSignModal>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _cameraError;
  StreamController<CameraImage>? _imageStreamController;

  bool _isRecording = false;
  final List<List<LandmarkPoint>> _recordedFrames = [];
  List<LandmarkPoint>? _currentLandmarks;
  StreamSubscription<List<LandmarkPoint>>? _landmarkSub;

  List<SignEntry> _existingSamples = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _initCamera();
    _loadExistingSamples();
  }

  Future<void> _loadExistingSamples() async {
    final List<SignEntry> samples = await ref
        .read(signLibraryRepositoryProvider)
        .getSamplesForSign(widget.signName);
    if (mounted) {
      setState(() => _existingSamples = samples);
    }
  }

  Future<void> _initCamera() async {
    try {
      final CameraService cameraService = ref.read(cameraServiceProvider);
      final List<CameraDescription> cameras = await cameraService.initialize();

      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'No camera found.');
        return;
      }

      // Prefer front camera for sign capture
      final CameraDescription selectedCamera = cameras.firstWhere(
        (CameraDescription c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final CameraController controller =
          await cameraService.startPreview(selectedCamera);

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _cameraReady = true;
        });
      }

      // Start streaming images to HandLandmarkService
      final HandLandmarkService landmarkService =
          ref.read(handLandmarkServiceProvider);

      _imageStreamController = StreamController<CameraImage>.broadcast();

      await controller.startImageStream((CameraImage image) {
        if (!(_imageStreamController?.isClosed ?? true)) {
          _imageStreamController?.add(image);
        }
      });

      await landmarkService.startDetection(_imageStreamController!.stream);

      // Listen to detected landmarks
      _landmarkSub = landmarkService.landmarkStream.listen((landmarks) {
        if (!mounted) return;
        setState(() => _currentLandmarks = landmarks);

        if (_isRecording && landmarks.length == 21) {
          _recordedFrames.add(landmarks);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Camera init failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _landmarkSub?.cancel();
    _imageStreamController?.close();
    // Stop image stream and preview cleanly
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    ref.read(cameraServiceProvider).stopPreview();
    ref.read(handLandmarkServiceProvider).stopDetection();
    super.dispose();
  }

  void _onStartRecording() {
    setState(() {
      _isRecording = true;
      _recordedFrames.clear();
    });
  }

  Future<void> _onStopRecording() async {
    setState(() => _isRecording = false);

    if (_recordedFrames.length < 8) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recording too short (${_recordedFrames.length} frames). '
            'Hold the button for at least 0.5s while performing the sign.',
          ),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    final SignEntry newEntry = SignEntry(
      signName: widget.signName,
      landmarkSequence: List<List<LandmarkPoint>>.from(_recordedFrames),
      dateRecorded: DateTime.now().toUtc(),
    );

    await ref.read(signLibraryRepositoryProvider).saveSign(newEntry);
    await ref.read(activityLogServiceProvider).log(
      EventType.signRecorded,
      'Recorded sample #${_existingSamples.length + 1} for ${widget.signName} '
      '(${_recordedFrames.length} frames)',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved sample #${_existingSamples.length + 1} for ${widget.signName} '
          '(${_recordedFrames.length} frames)!',
        ),
        backgroundColor: AppTheme.statusConnected,
      ),
    );

    await _loadExistingSamples();
  }

  Future<void> _deleteSample(SignEntry entry) async {
    await ref.read(signLibraryRepositoryProvider).deleteSample(entry);
    await _loadExistingSamples();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Record "${widget.signName}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Camera Preview with Landmarks ─────────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isRecording
                        ? AppTheme.statusError
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: _isRecording ? 3 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_cameraReady && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else if (_cameraError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _cameraError!,
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),

                    // Hand skeleton overlay
                    if (_currentLandmarks != null)
                      CustomPaint(
                        painter: HandLandmarkPainter(
                          landmarks: _currentLandmarks,
                          isFrontCamera: true,
                        ),
                      ),

                    // Hand presence indicator
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentLandmarks != null &&
                                        _currentLandmarks!.isNotEmpty
                                    ? AppTheme.statusConnected
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentLandmarks != null &&
                                      _currentLandmarks!.isNotEmpty
                                  ? 'Hand Detected'
                                  : 'Position hand in frame',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recording indicator banner
                    if (_isRecording)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: FadeTransition(
                          opacity: _pulseController,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.statusError,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'REC ${_recordedFrames.length}f',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Hold-to-Record Button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: GestureDetector(
                onTapDown: (_) => _onStartRecording(),
                onTapUp: (_) => _onStopRecording(),
                onTapCancel: () => _onStopRecording(),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppTheme.statusError
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording
                                ? AppTheme.statusError
                                : theme.colorScheme.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRecording
                            ? Icons.fiber_manual_record
                            : Icons.touch_app_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isRecording
                            ? 'RECORDING (${_recordedFrames.length} frames) — Release to Save'
                            : 'HOLD TO RECORD SIGN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Existing Samples List ─────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recorded Samples (${_existingSamples.length})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Multi-sample improves DTW',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _existingSamples.isEmpty
                          ? Center(
                              child: Text(
                                'No samples recorded yet.\nHold the button above to record.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _existingSamples.length,
                              itemBuilder: (BuildContext context, int i) {
                                final SignEntry sample = _existingSamples[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 14,
                                      child: Text('${i + 1}'),
                                    ),
                                    title: Text('Sample #${i + 1}'),
                                    subtitle: Text(
                                      '${sample.frameCount} frames · '
                                      '${sample.dateRecorded.toLocal().toString().substring(0, 16)}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                      ),
                                      color: AppTheme.statusError,
                                      onPressed: () => _deleteSample(sample),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
