import 'package:flutter/material.dart';
import 'package:signbridge_dashboard/shared/widgets/panel_card.dart';

/// Speech playback control panel.
///
/// Phase 1: mock toggle UI with volume slider.
/// Phase 2: connects to audioplayers to replay TTS audio piped from the phone.
class SpeechPlaybackPanel extends StatefulWidget {
  const SpeechPlaybackPanel({super.key});

  @override
  State<SpeechPlaybackPanel> createState() => _SpeechPlaybackPanelState();
}

class _SpeechPlaybackPanelState extends State<SpeechPlaybackPanel> {
  bool _isPlaying = false;
  double _volume = 0.8;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PanelCard(
      title: 'Speech Playback',
      icon: Icons.volume_up_rounded,
      trailing: Chip(
        label: const Text('Phase 2', style: TextStyle(fontSize: 10)),
        backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.12),
        side: BorderSide(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
        labelStyle: TextStyle(color: theme.colorScheme.secondary),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      child: Column(
        children: [
          // Play / Pause
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _isPlaying = !_isPlaying);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isPlaying
                            ? 'Speech playback: ON (mock)'
                            : 'Speech playback: OFF (mock)',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPlaying
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    boxShadow: _isPlaying
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 30,
                    color: _isPlaying
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Volume slider
          Row(
            children: [
              Icon(
                Icons.volume_down_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (double v) => setState(() => _volume = v),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
              Icon(
                Icons.volume_up_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_volume * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Phase 2: real-time TTS audio from phone over bridge.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
