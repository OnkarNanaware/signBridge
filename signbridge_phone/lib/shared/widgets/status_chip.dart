import 'package:flutter/material.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';

/// A small status indicator chip with a coloured dot and a label.
///
/// Used for connection state, recording state, and service status badges.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.color,
    super.key,
    this.icon,
    this.animate = false,
  });

  /// Status label text.
  final String label;

  /// Colour of the indicator dot. Use [AppTheme.statusConnected] etc.
  final Color color;

  /// Optional icon shown before the dot.
  final IconData? icon;

  /// If true, the dot pulses to indicate an active/searching state.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SignBridgeColors colors = SignBridgeColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          _PulseDot(color: color, animate: animate),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              color: colors.captionText.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.animate});

  final Color color;
  final bool animate;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      );
}
