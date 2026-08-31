import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/models/bridge_message.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';
import 'package:signbridge_phone/shared/widgets/panel_card.dart';
import 'package:signbridge_phone/shared/widgets/status_chip.dart';

/// Scripted Demo Runner screen guiding the presenter through a flawless
/// 4-step live jury demonstration.
class DemoScreen extends ConsumerStatefulWidget {
  const DemoScreen({super.key});

  @override
  ConsumerState<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends ConsumerState<DemoScreen> {
  int _currentStep = 0;
  String? _step1Recognized;
  String? _step2ReceivedText;
  StreamSubscription<BridgeMessage>? _bridgeMsgSub;

  @override
  void initState() {
    super.initState();
    // Listen for incoming dashboard messages
    _bridgeMsgSub = ref
        .read(bridgeServiceProvider)
        .incomingMessageStream
        .listen((BridgeMessage msg) {
      if (msg.type == 'dashboard_message') {
        if (mounted) {
          setState(() {
            _step2ReceivedText = msg.text;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _bridgeMsgSub?.cancel();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _resetDemo() {
    setState(() {
      _currentStep = 0;
      _step1Recognized = null;
      _step2ReceivedText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<BridgeConnectionState> bridgeState =
        ref.watch(bridgeConnectionStateProvider);

    final bool isBridgeConnected = bridgeState.valueOrNull == BridgeConnectionState.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Jury Demo Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset Demo',
            onPressed: _resetDemo,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step progress bar
            _buildStepIndicator(theme),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: switch (_currentStep) {
                  0 => _buildStep1SignToCaption(theme, isBridgeConnected),
                  1 => _buildStep2DashboardToPhone(theme, isBridgeConnected),
                  2 => _buildStep3ArchitectureFlash(theme),
                  _ => _buildStep4ImpactClose(theme),
                },
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: _prevStep,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _currentStep < 3 ? _nextStep : _resetDemo,
                    icon: Icon(
                      _currentStep < 3
                          ? Icons.arrow_forward_rounded
                          : Icons.replay_rounded,
                    ),
                    label: Text(_currentStep < 3 ? 'Next Step' : 'Restart Demo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < 4; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i <= _currentStep
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── STEP 1: Sign Detection → Dashboard Caption ────────────────────────────
  Widget _buildStep1SignToCaption(ThemeData theme, bool isBridgeConnected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cueCard(
          theme,
          stepNumber: 1,
          title: 'Sign Detection → Dashboard Live Caption',
          presenterCue:
              'Presenter: Perform "Hello" or "Thank You" in front of the phone camera. '
              'Point to the Windows Dashboard to show the caption appear in <100ms.',
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Live Recognition Monitor',
          icon: Icons.sign_language_rounded,
          trailing: StatusChip(
            label: isBridgeConnected ? 'Bridge Linked' : 'Bridge Searching',
            color: isBridgeConnected ? AppTheme.statusConnected : AppTheme.statusSearching,
          ),
          child: Column(
            children: [
              Text(
                'Recognized Gesture Output:',
                style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                child: Text(
                  _step1Recognized ?? 'Perform sign or tap test button below',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _step1Recognized = 'HELLO (94% confidence)');
                  await ref.read(bridgeServiceProvider).sendMessage(
                        BridgeMessage.signCaption('HELLO', confidence: 0.94),
                      );
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Simulate "HELLO" Match to Bridge'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 2: Dashboard Input → Phone Speech Playback ───────────────────────
  Widget _buildStep2DashboardToPhone(ThemeData theme, bool isBridgeConnected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cueCard(
          theme,
          stepNumber: 2,
          title: 'Dashboard Typing → Phone Speech Playback',
          presenterCue:
              'Presenter: On the Windows laptop, type a message in Session Controls '
              '(e.g. "Welcome to SignBridge!") and click Send. '
              'The phone will immediately speak it aloud on its speaker.',
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Speech Playback Receiver',
          icon: Icons.record_voice_over_rounded,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.statusConnected.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.statusConnected),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.volume_up_rounded, size: 36, color: AppTheme.statusConnected),
                    const SizedBox(height: 8),
                    Text(
                      _step2ReceivedText != null
                          ? '"$_step2ReceivedText"'
                          : 'Waiting for dashboard message...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.statusConnected,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  const String sample = 'Welcome to the meeting, we can begin now.';
                  setState(() => _step2ReceivedText = sample);
                  await ref.read(ttsServiceProvider).speak(sample);
                },
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('Simulate Incoming Speech Test'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 3: Architecture & Privacy Flash ──────────────────────────────────
  Widget _buildStep3ArchitectureFlash(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cueCard(
          theme,
          stepNumber: 3,
          title: 'On-Device Architecture & Privacy Flash',
          presenterCue:
              'Presenter: Explain the 4-layer edge pipeline. '
              'Emphasize: Zero cloud calls. Zero latency jitter. Complete air-gap privacy.',
        ),
        const SizedBox(height: 16),
        _archLayer(
          theme,
          step: '1',
          title: 'Camera Ingestion',
          desc: 'Front Camera streams frames at 30 FPS locally',
          icon: Icons.camera_front_rounded,
        ),
        _archLayer(
          theme,
          step: '2',
          title: 'MediaPipe HandLandmarker',
          desc: '21 3D landmarks extracted in Native Kotlin background thread (~22ms)',
          icon: Icons.fingerprint_rounded,
        ),
        _archLayer(
          theme,
          step: '3',
          title: 'Pure Dart DTW Matcher',
          desc: 'Sakoe-Chiba normalized matching on background Isolate (~8ms)',
          icon: Icons.bolt_rounded,
        ),
        _archLayer(
          theme,
          step: '4',
          title: 'Office Kit Shelf Bridge',
          desc: 'Two-way WebSocket server (Port 8765) over Wi-Fi / USB (<15ms)',
          icon: Icons.lan_rounded,
          isLast: true,
        ),
      ],
    );
  }

  // ── STEP 4: Impact & Summary Close ────────────────────────────────────────
  Widget _buildStep4ImpactClose(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cueCard(
          theme,
          stepNumber: 4,
          title: 'Impact & Benchmark Summary',
          presenterCue:
              'Presenter: Conclude with key numbers: Sub-50ms pipeline latency, '
              '100% offline privacy, battery-efficient edge execution.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _statBox(theme, '50ms', 'Measured Pipeline Latency (<500ms target)'),
            const SizedBox(width: 10),
            _statBox(theme, '0 KB', 'Cloud Bandwidth Used (Air-Gapped)'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statBox(theme, '25 Signs', 'Pre-seeded Curated Vocabulary'),
            const SizedBox(width: 10),
            _statBox(theme, '100%', 'Privacy: Stays on Device Pair'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.statusConnected.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.statusConnected.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppTheme.statusConnected, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SignBridge is ready for hybrid meetings without internet infrastructure.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cueCard(
    ThemeData theme, {
    required int stepNumber,
    required String title,
    required String presenterCue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            presenterCue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _archLayer(
    ThemeData theme, {
    required String step,
    required String title,
    required String desc,
    required IconData icon,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(ThemeData theme, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
