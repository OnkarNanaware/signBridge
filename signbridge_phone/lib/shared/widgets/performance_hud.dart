import 'package:flutter/material.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';

/// Real-time Performance HUD overlay showing jury on-device processing metrics.
class PerformanceHud extends StatelessWidget {
  const PerformanceHud({
    super.key,
    required this.fps,
    required this.landmarkTimeMs,
    required this.dtwTimeMs,
    required this.totalLatencyMs,
    this.delegate = 'MediaPipe Native Kotlin',
    this.isolateStatus = 'Dart Isolate (Active)',
  });

  final int fps;
  final int landmarkTimeMs;
  final int dtwTimeMs;
  final int totalLatencyMs;
  final String delegate;
  final String isolateStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.statusConnected.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.speed_rounded,
                size: 14,
                color: AppTheme.statusConnected,
              ),
              const SizedBox(width: 6),
              const Text(
                'ON-DEVICE INFERENCE HUD',
                style: TextStyle(
                  color: AppTheme.statusConnected,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.statusConnected.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$fps FPS',
                  style: const TextStyle(
                    color: AppTheme.statusConnected,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metricPill('Landmark', '${landmarkTimeMs}ms'),
              const SizedBox(width: 6),
              _metricPill('DTW Isolate', '${dtwTimeMs}ms'),
              const SizedBox(width: 6),
              _metricPill('Total Pipeline', '${totalLatencyMs}ms', highlight: true),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delegate: $delegate',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
              const Text(
                'Cloud: 0% (AIR-GAPPED)',
                style: TextStyle(
                  color: AppTheme.statusConnected,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: highlight
              ? AppTheme.statusConnected.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: highlight ? AppTheme.statusConnected : Colors.white60,
                fontSize: 9,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: highlight ? AppTheme.statusConnected : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
