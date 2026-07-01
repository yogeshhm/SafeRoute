import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_theme.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _bus;
  Map<String, dynamic>? _route;
  List<Map<String, dynamic>> _stops = [];
  Map<String, dynamic>? _activeTrip;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await UserService.getDriverProfile();

      final bus = await _db
          .from('buses')
          .select('id, school_id, bus_number, registration_number, capacity')
          .eq('driver_user_id', profile['id'])
          .eq('is_active', true)
          .maybeSingle();

      Map<String, dynamic>? route;
      List<Map<String, dynamic>> stops = [];
      Map<String, dynamic>? activeTrip;

      if (bus != null) {
        route = await _db
            .from('routes')
            .select('id, name, description')
            .eq('bus_id', bus['id'])
            .maybeSingle();

        if (route != null) {
          final stopsRaw = await _db
              .from('route_stops')
              .select('id, name, morning_sequence, evening_sequence, is_school')
              .eq('route_id', route['id'])
              .eq('is_active', true)
              .order('morning_sequence');
          stops = List<Map<String, dynamic>>.from(stopsRaw);
        }

        activeTrip = await _db
            .from('trips')
            .select('id, type, status, started_at')
            .eq('bus_id', bus['id'])
            .eq('status', 'active')
            .maybeSingle();
      }

      // Resume GPS if trip was already active
      if (activeTrip != null && bus != null &&
          !LocationService.instance.isTracking) {
        LocationService.instance.startTracking(
          tripId: activeTrip['id'],
          busId: bus['id'],
        );
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _bus = bus;
          _route = route;
          _stops = stops;
          _activeTrip = activeTrip;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _startTrip(String tripType) async {
    if (_bus == null || _route == null) return;
    setState(() => _starting = true);
    try {
      final trip = await _db.from('trips').insert({
        'school_id': _bus!['school_id'],
        'route_id': _route!['id'],
        'bus_id': _bus!['id'],
        'driver_user_id': _profile!['id'],
        'type': tripType,
        'status': 'active',
        'started_at': DateTime.now().toIso8601String(),
      }).select().single();

      if (mounted) {
        setState(() => _activeTrip = trip);
      }
      // Start GPS tracking
      await LocationService.instance.startTracking(
        tripId: trip['id'],
        busId: _bus!['id'],
      );
      if (mounted) {
        context.go('/driver/trip/${trip['id']}/stop/next', extra: trip);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/login'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await LocationService.instance.stopTracking();
                    await UserService.signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${_greeting()},',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _profile?['full_name'] ?? 'Driver',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_bus == null) ...[
                    _EmptyCard(
                      icon: Icons.directions_bus_outlined,
                      title: 'No bus assigned',
                      subtitle: 'Contact your school admin',
                    ),
                  ] else ...[
                    // Bus info
                    _SectionLabel('Your Bus'),
                    const SizedBox(height: 10),
                    _BusInfoCard(bus: _bus!, route: _route),
                    const SizedBox(height: 20),

                    // Route stops
                    if (_stops.isNotEmpty) ...[
                      _SectionLabel('Route Stops'),
                      const SizedBox(height: 10),
                      _RouteStopsList(stops: _stops),
                      const SizedBox(height: 20),
                    ],

                    // Trip actions
                    _SectionLabel('Trip'),
                    const SizedBox(height: 10),

                    if (_activeTrip != null) ...[
                      _ActiveTripBanner(
                        trip: _activeTrip!,
                        onContinue: () => context.go(
                          '/driver/trip/${_activeTrip!['id']}/stop/next',
                        ),
                      ),
                    ] else ...[
                      FilledButton.icon(
                        onPressed: _starting ? null : () => _startTrip('morning_pickup'),
                        icon: const Icon(Icons.wb_sunny_outlined),
                        label: const Text('Begin Morning Pickup'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _starting ? null : () => _startTrip('evening_drop'),
                        icon: const Icon(Icons.nights_stay_outlined),
                        label: const Text('Begin Return Trip'),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _BusInfoCard extends StatelessWidget {
  const _BusInfoCard({required this.bus, required this.route});
  final Map<String, dynamic> bus;
  final Map<String, dynamic>? route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_bus_rounded,
                  color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bus ${bus['bus_number']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (bus['registration_number'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      bus['registration_number'],
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                  if (route != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      route!['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStopsList extends StatelessWidget {
  const _RouteStopsList({required this.stops});
  final List<Map<String, dynamic>> stops;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: stops.asMap().entries.map((entry) {
            final i = entry.key;
            final stop = entry.value;
            final isLast = i == stops.length - 1;
            final isSchool = stop['is_school'] == true;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSchool
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isSchool
                                ? const Icon(Icons.school, size: 14, color: Colors.white)
                                : Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 12, bottom: isLast ? 12 : 20, right: 16),
                      child: Text(
                        stop['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSchool ? FontWeight.bold : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ActiveTripBanner extends StatelessWidget {
  const _ActiveTripBanner({required this.trip, required this.onContinue});
  final Map<String, dynamic> trip;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isMorning = trip['type'] == 'morning_pickup';
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isMorning ? 'Morning Pickup' : 'Return Trip',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'In Progress',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue Trip',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
