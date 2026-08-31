import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/core/models/sign_entry.dart';
import 'package:signbridge_phone/core/router/app_router.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive initialisation ────────────────────────────────────────────────────
  await Hive.initFlutter();

  // Register Hive adapters (hand-written .g.dart files — no build_runner needed
  // in Phase 1).
  if (!Hive.isAdapterRegistered(kLandmarkPointTypeId)) {
    Hive.registerAdapter(LandmarkPointAdapter());
  }
  if (!Hive.isAdapterRegistered(kSignEntryTypeId)) {
    Hive.registerAdapter(SignEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(kActivityLogEntryTypeId)) {
    Hive.registerAdapter(ActivityLogEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    // EventType adapter has typeId = 3
    Hive.registerAdapter(EventTypeAdapter());
  }

  // Open Hive boxes — mock services use in-memory storage in Phase 1,
  // but we open the boxes now so real implementations can use them without
  // any changes to main().
  await Hive.openBox<SignEntry>(kSignLibraryBox);
  await Hive.openBox<ActivityLogEntry>(kActivityLogBox);

  runApp(
    const ProviderScope(
      child: SignBridgeApp(),
    ),
  );
}

/// Root application widget.
class SignBridgeApp extends StatelessWidget {
  const SignBridgeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'SignBridge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      );
}
