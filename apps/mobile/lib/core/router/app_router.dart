import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_picker_screen.dart';
import '../../features/driver/screens/driver_home_screen.dart';
import '../../features/driver/screens/trip_stop_screen.dart';
import '../../features/parent/screens/parent_home_screen.dart';
import '../../features/parent/screens/trip_tracking_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = state.matchedLocation == '/login' ||
        state.matchedLocation == '/demo';

    if (session == null) {
      return isAuth ? null : '/login';
    }

    // If logged in and on auth screen, redirect by role
    if (isAuth) {
      final profile = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('auth_user_id', session.user.id)
          .maybeSingle();
      final role = profile?['role'] as String?;
      if (role == 'driver') return '/driver';
      return '/parent';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/demo',
      builder: (context, state) => const RolePickerScreen(),
    ),
    GoRoute(
      path: '/driver',
      builder: (context, state) => const DriverHomeScreen(),
      routes: [
        GoRoute(
          path: 'trip/:tripId/stop/:stopId',
          builder: (context, state) => TripStopScreen(
            tripId: state.pathParameters['tripId']!,
            stopId: state.pathParameters['stopId']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/parent',
      builder: (context, state) => const ParentHomeScreen(),
      routes: [
        GoRoute(
          path: 'track/:tripId',
          builder: (context, state) => TripTrackingScreen(
            tripId: state.pathParameters['tripId']!,
          ),
        ),
      ],
    ),
  ],
);
