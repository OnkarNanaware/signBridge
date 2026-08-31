import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/features/bridge_connection/presentation/connection_status_badge.dart';
import 'package:signbridge_phone/features/demo_mode/presentation/demo_mode_banner.dart';
import 'package:signbridge_phone/features/sign_capture/presentation/sign_capture_panel.dart';
import 'package:signbridge_phone/features/speech_capture/presentation/speech_capture_panel.dart';

/// The main home screen of the SignBridge phone app.
///
/// Layout (top → bottom):
///   1. Demo Mode Banner (if mock services active)
///   2. App Bar with connection badge
///   3. Sign → Text panel (large, prominent)
///   4. Speech → Text panel
///   5. Bottom navigation bar
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.sign_language_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text('SignBridge'),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(),
          ),
        ],
        bottom: useMockServices
            ? const PreferredSize(
                preferredSize: Size.fromHeight(34),
                child: DemoModeBanner(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Sign → Text ───────────────────────────────────────────────
              const SignCapturePanel(),
              const SizedBox(height: 4),
              // ── Speech → Text ─────────────────────────────────────────────
              const SpeechCapturePanel(),
              const SizedBox(height: 4),
              // ── Quick stats row ───────────────────────────────────────────
              _QuickStatsRow(),
              const SizedBox(height: 80), // bottom nav padding
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (int index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/library');
            case 2:
              context.go('/bridge');
            case 3:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.laptop_outlined),
            selectedIcon: Icon(Icons.laptop_rounded),
            label: 'Bridge',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Row of quick-glance metrics beneath the main panels.
class _QuickStatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(theme, Icons.sign_language_rounded, 'Signs', '25'),
            _divider(theme),
            _stat(theme, Icons.speed_rounded, 'Target Latency', '<500ms'),
            _divider(theme),
            _stat(theme, Icons.lock_outline_rounded, 'Privacy', 'Local only'),
          ],
        ),
      ),
    );
  }

  Widget _stat(ThemeData theme, IconData icon, String label, String value) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
        ],
      );

  Widget _divider(ThemeData theme) => SizedBox(
        height: 40,
        child: VerticalDivider(
          thickness: 1,
          color: theme.dividerColor,
          width: 1,
        ),
      );
}
