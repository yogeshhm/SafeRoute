import 'package:go_router/go_router.dart';
import '../../features/auth/screens/role_picker_screen.dart';
import '../../features/driver/screens/driver_home_screen.dart';
import '../../features/driver/screens/trip_stop_screen.dart';
import '../../features/parent/screens/parent_home_screen.dart';
import '../../features/parent/screens/trip_tracking_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const RolePickerScreen()),
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
