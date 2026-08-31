import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signbridge_phone/features/bridge_connection/presentation/bridge_connection_screen.dart';
import 'package:signbridge_phone/features/home/presentation/home_screen.dart';
import 'package:signbridge_phone/features/settings/presentation/settings_screen.dart';
import 'package:signbridge_phone/features/sign_library_manager/presentation/sign_library_screen.dart';

/// Application router using GoRouter.
///
/// Routes:
///   /           → HomeScreen (Sign→Text + Speech→Text + connection badge)
///   /library    → SignLibraryScreen (manage reference signs)
///   /bridge     → BridgeConnectionScreen (Office Kit connection details)
///   /settings   → SettingsScreen
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: '/library',
      name: 'sign-library',
      builder: (BuildContext context, GoRouterState state) =>
          const SignLibraryScreen(),
    ),
    GoRoute(
      path: '/bridge',
      name: 'bridge-connection',
      builder: (BuildContext context, GoRouterState state) =>
          const BridgeConnectionScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    body: Center(
      child: Text('Route not found: ${state.uri}'),
    ),
  ),
);
