import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';
import 'package:signbridge_phone/shared/widgets/caption_text.dart';
import 'package:signbridge_phone/shared/widgets/panel_card.dart';
import 'package:signbridge_phone/shared/widgets/status_chip.dart';

/// Panel that displays live sign recognition results from the DTW matcher.
///
/// Shows the current matched sign in large caption text with a confidence
/// badge. Animates on each new match event.
class SignCapturePanel extends ConsumerStatefulWidget {
  const SignCapturePanel({super.key});

  @override
  ConsumerState<SignCapturePanel> createState() => _SignCapturePanelState();
}

class _SignCapturePanelState extends ConsumerState<SignCapturePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;

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
  }

  @override
  void dispose() {
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

    return PanelCard(
      title: 'Sign → Text',
      icon: Icons.sign_language_rounded,
      trailing: StatusChip(
        label: useMockServices ? 'Demo' : 'Live',
        color: useMockServices
            ? AppTheme.demoBannerBg
            : AppTheme.statusConnected,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main caption display
          AnimatedBuilder(
            animation: _flashOpacity,
            builder: (BuildContext context, Widget? child) => Container(
              decoration: BoxDecoration(
                color: hasMatch
                    ? theme.colorScheme.primary
                        .withValues(alpha: _flashOpacity.value * 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: child,
            ),
            child: CaptionText(
              signText,
              size: CaptionSize.large,
            ),
          ),
          const SizedBox(height: 12),
          // Confidence bar
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
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Waiting for sign…',
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
