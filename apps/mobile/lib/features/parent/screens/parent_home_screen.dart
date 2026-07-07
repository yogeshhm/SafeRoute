import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_theme.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _children = [];
  Map<String, Map<String, dynamic>?> _activeTrips = {};
  Map<String, Map<String, dynamic>?> _latestEvents = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await UserService.getParentProfile();

      final childrenRaw = await _db.from('students').select(
            'id, full_name, grade, section, route_id, '
            'morning_pickup_stop_id, evening_drop_stop_id',
          ).eq('parent_user_id', profile['id']).eq('is_active', true);

      final children = List<Map<String, dynamic>>.from(childrenRaw);

      final Map<String, Map<String, dynamic>?> trips = {};
      final Map<String, Map<String, dynamic>?> events = {};

      for (final child in children) {
        // Get bus for this child's route
        final route = await _db
            .from('routes')
            .select('id, name, bus_id')
            .eq('id', child['route_id'])
            .maybeSingle();

        Map<String, dynamic>? trip;
        if (route?['bus_id'] != null) {
          trip = await _db
              .from('trips')
              .select('id, type, status, started_at, bus_id')
              .eq('bus_id', route!['bus_id'])
              .eq('status', 'active')
              .maybeSingle();
        }
        trips[child['id']] = trip;

        // Latest event for this child in active trip
        if (trip != null) {
          final event = await _db
              .from('student_trip_events')
              .select('status, occurred_at')
              .eq('trip_id', trip['id'])
              .eq('student_id', child['id'])
              .order('occurred_at', ascending: false)
              .limit(1)
              .maybeSingle();
          events[child['id']] = event;
        }
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _children = children;
          _activeTrips = trips;
          _latestEvents = events;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () => context.push('/profile'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
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
                      colors: [Color(0xFF0D5C3A), Color(0xFF12B76A)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Hello, ${_profile?['full_name'] ?? 'Parent'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_children.length} ${_children.length == 1 ? 'child' : 'children'} linked',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
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
                  if (_children.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No children linked to your account.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...(_children.map((child) {
                      final trip = _activeTrips[child['id']];
                      final event = _latestEvents[child['id']];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ChildCard(
                          child: child,
                          activeTrip: trip,
                          latestEvent: event,
                          onTrack: trip != null
                              ? () => context.go('/parent/track/${trip['id']}')
                              : null,
                        ),
                      );
                    })),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.activeTrip,
    required this.latestEvent,
    required this.onTrack,
  });
  final Map<String, dynamic> child;
  final Map<String, dynamic>? activeTrip;
  final Map<String, dynamic>? latestEvent;
  final VoidCallback? onTrack;

  String _statusLabel(String s) {
    switch (s) {
      case 'boarded':
        return 'Boarded the bus';
      case 'absent':
        return 'Marked absent';
      case 'reached_school':
        return 'Reached school';
      case 'dropped':
        return 'Dropped at stop';
      case 'still_onboard':
        return 'Still on bus';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'boarded':
      case 'reached_school':
      case 'dropped':
        return AppColors.green;
      case 'absent':
        return AppColors.orange;
      default:
        return AppColors.primary;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'boarded':
        return Icons.directions_bus_rounded;
      case 'absent':
        return Icons.person_off_outlined;
      case 'reached_school':
        return Icons.school_rounded;
      case 'dropped':
        return Icons.home_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMorning = activeTrip?['type'] == 'morning_pickup';
    final eventStatus = latestEvent?['status'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D5C3A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      child['full_name'].toString()[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D5C3A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child['full_name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Grade ${child['grade']} · Section ${child['section']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (activeTrip != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isMorning ? 'Pickup' : 'Return',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (eventStatus != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(_statusIcon(eventStatus),
                      size: 18, color: _statusColor(eventStatus)),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(eventStatus),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(eventStatus),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (activeTrip == null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    'No active trip right now',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],

          if (activeTrip != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: onTrack,
                icon: const Icon(Icons.location_on_rounded, size: 18),
                label: const Text('Track Bus Live'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
