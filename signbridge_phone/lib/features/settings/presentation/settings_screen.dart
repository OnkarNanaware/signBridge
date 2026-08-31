import 'package:flutter/material.dart';

/// Placeholder settings screen for Phase 1.
/// Phase 2 will add: DTW threshold slider, sign vocabulary editor,
/// ASR model selection, TTS voice/rate, and bridge port override.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(theme, 'Recognition'),
          _tile(
            theme,
            'DTW Confidence Threshold',
            '72% (default)',
            Icons.tune_rounded,
            subtitle: 'Phase 2: adjustable slider',
          ),
          _tile(
            theme,
            'Sign Hold Duration',
            '300ms (default)',
            Icons.timer_outlined,
            subtitle: 'Phase 2: adjustable',
          ),
          const SizedBox(height: 16),
          _section(theme, 'Audio'),
          _tile(
            theme,
            'TTS Voice',
            'Default system voice',
            Icons.record_voice_over_rounded,
            subtitle: 'Phase 2: voice picker',
          ),
          _tile(
            theme,
            'TTS Speed',
            '1.0× (default)',
            Icons.speed_rounded,
            subtitle: 'Phase 2: adjustable',
          ),
          const SizedBox(height: 16),
          _section(theme, 'Bridge'),
          _tile(
            theme,
            'Bridge Port',
            '8765 (default)',
            Icons.lan_rounded,
            subtitle: 'Phase 2: editable',
          ),
          const SizedBox(height: 16),
          _section(theme, 'About'),
          _tile(
            theme,
            'Version',
            '1.0.0 (Phase 1)',
            Icons.info_outline_rounded,
          ),
          _tile(
            theme,
            'Mode',
            'Demo (mock services)',
            Icons.science_rounded,
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
              ? Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),)
              : null,
          trailing: Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
}
