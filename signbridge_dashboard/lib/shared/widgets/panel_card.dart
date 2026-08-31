import 'package:flutter/material.dart';
import 'package:signbridge_dashboard/core/theme/app_theme.dart';

/// Reusable panel card for the dashboard layout.
class PanelCard extends StatelessWidget {
  const PanelCard({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
    this.trailing,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.headerPadding = const EdgeInsets.fromLTRB(16, 14, 12, 0),
    this.fillHeight = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry headerPadding;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SignBridgeColors colors = SignBridgeColors.of(context);

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
        ),
        Divider(thickness: 1, color: colors.panelBorder, height: 16),
        Padding(
          padding: contentPadding,
          child: fillHeight ? Expanded(child: child) : child,
        ),
      ],
    );

    return Card(
      child: fillHeight
          ? IntrinsicHeight(child: content)
          : content,
    );
  }
}
