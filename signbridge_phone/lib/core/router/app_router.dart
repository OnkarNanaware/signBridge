import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signbridge_phone/features/bridge_connection/presentation/bridge_connection_screen.dart';
import 'package:signbridge_phone/features/demo_mode/presentation/demo_screen.dart';
import 'package:signbridge_phone/features/home/presentation/home_screen.dart';
import 'package:signbridge_phone/features/offline_proof/presentation/proof_of_offline_screen.dart';
import 'package:signbridge_phone/features/settings/presentation/settings_screen.dart';
import 'package:signbridge_phone/features/sign_library_manager/presentation/sign_library_screen.dart';

/// Application router using GoRouter.
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
    GoRoute(
      path: '/offline-proof',
      name: 'offline-proof',
      builder: (BuildContext context, GoRouterState state) =>
          const ProofOfOfflineScreen(),
    ),
    GoRoute(
      path: '/demo',
      name: 'demo',
      builder: (BuildContext context, GoRouterState state) =>
          const DemoScreen(),
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    body: Center(
      child: Text('Route not found: ${state.uri}'),
    ),
  ),
);
