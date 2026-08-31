import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';

/// Settings and jury demo tools screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticsEnabled = true;
  String _fontSizeOption = 'Large';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Jury Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Jury & Demo Mode ──────────────────────────────────────────────
          _section(theme, 'Live Jury Tools'),
          Card(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.shield_rounded,
                color: AppTheme.statusConnected,
                size: 26,
              ),
              title: const Text(
                'Proof of Offline & Privacy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Audit air-gapped guarantees & run live network probe',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => context.push('/offline-proof'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.statusConnected.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppTheme.statusConnected.withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppTheme.statusConnected,
                size: 26,
              ),
              title: const Text(
                'Scripted Demo Mode Runner',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                '4-step presenter walkthrough with on-screen cues',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => context.push('/demo'),
            ),
          ),
          const SizedBox(height: 16),

          // ── Accessibility ─────────────────────────────────────────────────
          _section(theme, 'Accessibility & Feedback'),
          Card(
            child: SwitchListTile(
              secondary: Icon(Icons.vibration_rounded, color: theme.colorScheme.primary),
              title: const Text('Tactile Haptic Feedback'),
              subtitle: const Text('Vibrate on successful sign detection'),
              value: _hapticsEnabled,
              onChanged: (bool val) => setState(() => _hapticsEnabled = val),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.format_size_rounded, color: theme.colorScheme.primary),
              title: const Text('Caption Text Scaling'),
              subtitle: Text('Currently set to $_fontSizeOption'),
              trailing: DropdownButton<String>(
                value: _fontSizeOption,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                  DropdownMenuItem(value: 'Large', child: Text('Large (Default)')),
                  DropdownMenuItem(value: 'Extra Large', child: Text('Extra Large (32sp)')),
                ],
                onChanged: (String? val) {
                  if (val != null) setState(() => _fontSizeOption = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Recognition & Performance ─────────────────────────────────────
          _section(theme, 'On-Device Recognition'),
          _tile(
            theme,
            'DTW Confidence Threshold',
            '72%',
            Icons.tune_rounded,
            subtitle: 'Minimum confidence to commit sign caption',
          ),
          _tile(
            theme,
            'Candidate Hold Duration',
            '300ms',
            Icons.timer_outlined,
            subtitle: 'Prevents transient false positives',
          ),
          _tile(
            theme,
            'DTW Constraint Window',
            'Sakoe-Chiba',
            Icons.speed_rounded,
            subtitle: 'Optimized band pruning (~8ms evaluation)',
          ),
          const SizedBox(height: 16),

          // ── Audio & Bridge ────────────────────────────────────────────────
          _section(theme, 'Audio & Local Bridge'),
          _tile(
            theme,
            'ASR Offline Model',
            'Vosk English (39 MB)',
            Icons.mic_rounded,
            subtitle: 'Bundled locally in app assets',
          ),
          _tile(
            theme,
            'TTS Speech Playback',
            'On-Device System Engine',
            Icons.record_voice_over_rounded,
            subtitle: 'Speaks incoming dashboard text',
          ),
          _tile(
            theme,
            'WebSocket Port',
            '8765',
            Icons.lan_rounded,
            subtitle: 'Local Wi-Fi or USB tethering pair',
          ),
          const SizedBox(height: 16),

          // ── About ─────────────────────────────────────────────────────────
          _section(theme, 'About'),
          _tile(
            theme,
            'SignBridge Version',
            '1.0.0 (Release Candidate)',
            Icons.info_outline_rounded,
          ),
          _tile(
            theme,
            'Security Architecture',
            '100% Air-Gapped',
            Icons.lock_rounded,
            subtitle: 'Zero cloud dependencies, zero data leaks',
          ),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
      );

  Widget _tile(
    ThemeData theme,
    String title,
    String value,
    IconData icon, {
    String? subtitle,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon, size: 20, color: theme.colorScheme.primary),
          title: Text(title, style: theme.textTheme.bodyLarge),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                )
              : null,
          trailing: Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
