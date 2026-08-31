import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_dashboard/core/theme/app_theme.dart';
import 'package:signbridge_dashboard/features/dashboard/presentation/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NOTE: Hive initialisation will be added in Phase 2 when the real
  // ActivityLogService writes to disk. In Phase 1 the mock service uses
  // in-memory storage only.
  // TODO(phase2): await Hive.initFlutter(); + register adapters + open boxes.

  runApp(
    const ProviderScope(
      child: SignBridgeDashboardApp(),
    ),
  );
}

/// Root application widget for the Windows desktop dashboard.
class SignBridgeDashboardApp extends StatelessWidget {
  const SignBridgeDashboardApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SignBridge Dashboard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const DashboardScreen(),
      );
}
