import 'package:flutter/material.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';

/// High-contrast caption widget. Font size is always ≥ 24sp per the
/// accessibility requirements of the SignBridge spec.
///
/// [size] overrides the default. Use [CaptionSize.large] for the main
/// caption on the live panel, [CaptionSize.medium] for secondary labels.
enum CaptionSize {
  /// 48sp — primary live caption display.
  large,

  /// 32sp — secondary or queued captions.
  medium,

  /// 24sp — minimum accessible label size.
  small,
}

/// A styled text widget for displaying sign/speech captions.
///
/// Uses the [SignBridgeColors.captionText] token from the theme for
/// high-contrast rendering against any background.
class CaptionText extends StatelessWidget {
  const CaptionText(
    this.text, {
    super.key,
    this.size = CaptionSize.large,
    this.textAlign = TextAlign.center,
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
    final FontWeight fontWeight = switch (size) {
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
        fontWeight: fontWeight,
        color: colors.captionText,
        letterSpacing: size == CaptionSize.large ? 1.5 : 0.5,
        height: 1.2,
      ),
    );
  }
}
