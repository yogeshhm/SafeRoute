import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/demo_service.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_picker_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/driver/screens/driver_home_screen.dart';
import '../../features/driver/screens/trip_stop_screen.dart';
import '../../features/parent/screens/parent_home_screen.dart';
import '../../features/parent/screens/trip_tracking_screen.dart';
import '../../features/shared/screens/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/login' || loc == '/signup' || loc == '/demo';

    if (session == null && !DemoService.isDemo) {
      return isAuthRoute ? null : '/login';
    }

    // Logged in + on auth screen → redirect by role
    if (session != null && isAuthRoute) {
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
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
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
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
