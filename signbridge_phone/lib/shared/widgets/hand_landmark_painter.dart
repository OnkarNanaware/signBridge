import 'package:flutter/material.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';

/// CustomPainter that overlays 21 MediaPipe hand landmarks and skeleton bones
/// over the camera preview widget for visual feedback and live debugging.
class HandLandmarkPainter extends CustomPainter {
  const HandLandmarkPainter({
    required this.landmarks,
    this.isFrontCamera = true,
    this.jointColor = const Color(0xFF00E5FF), // Cyan accent
    this.boneColor = const Color(0xCC00E5FF),
    this.wristColor = const Color(0xFFFFD600), // Yellow accent
  });

  final List<LandmarkPoint>? landmarks;
  final bool isFrontCamera;
  final Color jointColor;
  final Color boneColor;
  final Color wristColor;

  // MediaPipe Hand landmark connection pairs
  static const List<List<int>> _connections = [
    // Thumb
    [0, 1], [1, 2], [2, 3], [3, 4],
    // Index
    [0, 5], [5, 6], [6, 7], [7, 8],
    // Middle
    [0, 9], [9, 10], [10, 11], [11, 12],
    // Ring
    [0, 13], [13, 14], [14, 15], [15, 16],
    // Pinky
    [0, 17], [17, 18], [18, 19], [19, 20],
    // Palm base knuckles
    [5, 9], [9, 13], [13, 17],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null || landmarks!.isEmpty) return;

    final Paint bonePaint = Paint()
      ..color = boneColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint jointPaint = Paint()
      ..color = jointColor
      ..style = PaintingStyle.fill;

    final Paint wristPaint = Paint()
      ..color = wristColor
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Convert normalized [0, 1] coords to pixel coordinates
    Offset toPixelOffset(LandmarkPoint p) {
      final double x = isFrontCamera ? (1.0 - p.x) * size.width : p.x * size.width;
      final double y = p.y * size.height;
      return Offset(x, y);
    }

    final Map<int, Offset> offsets = {};
    for (final LandmarkPoint lm in landmarks!) {
      offsets[lm.landmarkIndex] = toPixelOffset(lm);
    }

    // Draw connection bones
    for (final List<int> connection in _connections) {
      final Offset? start = offsets[connection[0]];
      final Offset? end = offsets[connection[1]];
      if (start != null && end != null) {
        canvas.drawLine(start, end, bonePaint);
      }
    }

    // Draw landmark joint dots
    for (final LandmarkPoint lm in landmarks!) {
      final Offset? pt = offsets[lm.landmarkIndex];
      if (pt != null) {
        final bool isWrist = lm.landmarkIndex == 0;
        final double radius = isWrist ? 6.0 : 4.5;

        canvas.drawCircle(pt, radius, isWrist ? wristPaint : jointPaint);
        canvas.drawCircle(pt, radius, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HandLandmarkPainter oldDelegate) =>
      oldDelegate.landmarks != landmarks ||
      oldDelegate.isFrontCamera != isFrontCamera;
}
