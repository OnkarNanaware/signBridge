import 'package:flutter/material.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';

/// Reusable card container for dashboard panels.
///
/// Wraps children in a [Card] with the SignBridge surface colour and a
/// subtle border, with a standardised header row (icon + title + optional
/// trailing widget).
class PanelCard extends StatelessWidget {
  const PanelCard({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
    this.headerPadding = const EdgeInsets.fromLTRB(16, 12, 12, 0),
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry headerPadding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SignBridgeColors colors = SignBridgeColors.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: headerPadding,
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          Divider(
            thickness: 1,
            color: colors.panelBorder,
            height: 16,
          ),
          // Content
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
