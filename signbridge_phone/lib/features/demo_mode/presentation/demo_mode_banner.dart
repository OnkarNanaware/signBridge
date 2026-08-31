import 'package:flutter/material.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';

/// A prominent yellow banner displayed when the app is running in Demo Mode
/// (i.e. `useMockServices = true`).
///
/// Alerts users and evaluators that no real hardware or AI pipeline is active.
class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppTheme.demoBannerBg,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_rounded,
              size: 16,
              color: AppTheme.demoBannerFg,
            ),
            SizedBox(width: 8),
            Text(
              'DEMO MODE — Mock services active. No hardware or AI pipeline running.',
              style: TextStyle(
                color: AppTheme.demoBannerFg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
}
