import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poultri_sense/providers/device_provider.dart';
import 'package:poultri_sense/screens/about/about_screen.dart';
import 'package:poultri_sense/screens/dashboard/dashboard_screen.dart';
import 'package:poultri_sense/screens/events/events_screen.dart';
import 'package:poultri_sense/screens/history/history_screen.dart';
import 'package:poultri_sense/screens/live/live_screen.dart';
import 'package:poultri_sense/screens/sensors/sensor_readings_screen.dart';
import 'package:poultri_sense/screens/setup/device_setup_screen.dart';
import 'package:poultri_sense/screens/shell/app_shell.dart';
import 'package:poultri_sense/screens/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) => notifier.redirect(state),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const DeviceSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/shell/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/shell/live',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LiveScreen()),
          ),
          GoRoute(
            path: '/shell/sensors',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SensorReadingsScreen()),
          ),
          GoRoute(
            path: '/shell/events',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EventsScreen()),
          ),
          GoRoute(
            path: '/shell/history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: '/shell/about',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AboutScreen()),
          ),
        ],
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // Whenever deviceProvider changes, tell go_router to re-evaluate
    // redirect. Covers: deviceId set after setup, deviceId cleared on re-pair.
    _ref.listen<DeviceState>(deviceProvider, (_, _) => notifyListeners());
  }

  String? redirect(GoRouterState state) {
  final deviceState = _ref.read(deviceProvider);
  final onSplash = state.matchedLocation == '/';
  final onSetup = state.matchedLocation == '/setup';

  if (onSplash) return null;                               // splash owns its navigation
  if (!deviceState.isInitialized) return null;             // hold until prefs read
  if (!deviceState.isSetupComplete && !onSetup) return '/setup'; // guard only
  return null;
  
}
}