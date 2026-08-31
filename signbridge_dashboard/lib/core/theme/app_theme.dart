import 'package:flutter/material.dart';

/// SignBridge Dashboard app theme — system-adaptive (dark + light) with
/// high-contrast overrides. Optimised for a large laptop display.
class AppTheme {
  AppTheme._();

  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color _brandTeal = Color(0xFF00C9A7);
  static const Color _brandTealDark = Color(0xFF009E80);
  static const Color _brandAccent = Color(0xFF6C63FF);

  // ── Dark ───────────────────────────────────────────────────────────────────
  static const Color _darkBg = Color(0xFF0D1117);
  static const Color _darkSurface = Color(0xFF161B22);
  static const Color _darkSurface2 = Color(0xFF21262D);
  static const Color _darkOnBg = Color(0xFFE6EDF3);
  static const Color _darkOnSurface = Color(0xFFCDD9E5);
  static const Color _darkCaption = Color(0xFFFFFFFF);

  // ── Light ──────────────────────────────────────────────────────────────────
  static const Color _lightBg = Color(0xFFF6F8FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurface2 = Color(0xFFEAEFF5);
  static const Color _lightOnBg = Color(0xFF1C2128);
  static const Color _lightCaption = Color(0xFF0D1117);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color statusConnected = Color(0xFF3FB950);
  static const Color statusSearching = Color(0xFFD29922);
  static const Color statusError = Color(0xFFF85149);
  static const Color demoBannerBg = Color(0xFFFFC107);
  static const Color demoBannerFg = Color(0xFF1C2128);

  static const String _fontFamily = 'Roboto';

  static TextTheme _buildTextTheme(Color onBg) => TextTheme(
        displayLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 56,
          fontWeight: FontWeight.w800,
          color: onBg,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: onBg,
        ),
        headlineLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: onBg,
        ),
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: onBg,
        ),
        titleLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onBg,
        ),
        titleMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onBg,
        ),
        bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, color: onBg),
        bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, color: onBg),
        labelLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: onBg,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: _fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: _brandTeal,
          primaryContainer: _brandTealDark,
          secondary: _brandAccent,
          surface: _darkSurface,
          onSurface: _darkOnSurface,
          error: statusError,
        ),
        scaffoldBackgroundColor: _darkBg,
        cardColor: _darkSurface,
        textTheme: _buildTextTheme(_darkOnBg),
        cardTheme: CardThemeData(
          color: _darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _darkSurface2, width: 1),
          ),
          margin: const EdgeInsets.all(6),
        ),
        dividerColor: _darkSurface2,
        iconTheme: const IconThemeData(color: _darkOnSurface),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBg,
          foregroundColor: _darkOnBg,
          elevation: 0,
          centerTitle: false,
        ),
        extensions: const [
          SignBridgeColors(
            captionText: _darkCaption,
            panelBorder: _darkSurface2,
            surface2: _darkSurface2,
          ),
        ],
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: _fontFamily,
        colorScheme: const ColorScheme.light(
          primary: _brandTealDark,
          primaryContainer: _brandTeal,
          secondary: _brandAccent,
          surface: _lightSurface,
          onSurface: _lightOnBg,
          error: statusError,
        ),
        scaffoldBackgroundColor: _lightBg,
        cardColor: _lightSurface,
        textTheme: _buildTextTheme(_lightOnBg),
        cardTheme: CardThemeData(
          color: _lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          margin: const EdgeInsets.all(6),
        ),
        dividerColor: _lightSurface2,
        appBarTheme: const AppBarTheme(
          backgroundColor: _lightSurface,
          foregroundColor: _lightOnBg,
          elevation: 0,
          centerTitle: false,
        ),
        extensions: [
          SignBridgeColors(
            captionText: _lightCaption,
            panelBorder: Colors.grey.shade200,
            surface2: _lightSurface2,
          ),
        ],
      );
}

@immutable
class SignBridgeColors extends ThemeExtension<SignBridgeColors> {
  const SignBridgeColors({
    required this.captionText,
    required this.panelBorder,
    required this.surface2,
  });

  final Color captionText;
  final Color panelBorder;
  final Color surface2;

  @override
  SignBridgeColors copyWith({Color? captionText, Color? panelBorder, Color? surface2}) =>
      SignBridgeColors(
        captionText: captionText ?? this.captionText,
        panelBorder: panelBorder ?? this.panelBorder,
        surface2: surface2 ?? this.surface2,
      );

  @override
  SignBridgeColors lerp(SignBridgeColors? other, double t) {
    if (other == null) return this;
    return SignBridgeColors(
      captionText: Color.lerp(captionText, other.captionText, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
    );
  }

  static SignBridgeColors of(BuildContext context) =>
      Theme.of(context).extension<SignBridgeColors>()!;
}
