import 'package:flutter/material.dart';
import 'package:signbridge_dashboard/core/theme/app_theme.dart';

enum CaptionSize { large, medium, small }

/// High-contrast caption text widget for the dashboard.
/// Font size ≥ 24sp at all times.
class CaptionText extends StatelessWidget {
  const CaptionText(
    this.text, {
    super.key,
    this.size = CaptionSize.large,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final CaptionSize size;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final SignBridgeColors colors = SignBridgeColors.of(context);

    final double fontSize = switch (size) {
      CaptionSize.large => 48,
      CaptionSize.medium => 32,
      CaptionSize.small => 24,
    };
    final FontWeight fw = switch (size) {
      CaptionSize.large => FontWeight.w800,
      CaptionSize.medium => FontWeight.w700,
      CaptionSize.small => FontWeight.w600,
    };

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fw,
        color: colors.captionText,
        letterSpacing: size == CaptionSize.large ? 2.0 : 0.5,
        height: 1.25,
      ),
    );
  }
}
