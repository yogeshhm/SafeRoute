import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_theme.dart';

class TripStopScreen extends StatefulWidget {
  const TripStopScreen({super.key, required this.tripId, required this.stopId});
  final String tripId;
  final String stopId;

  @override
  State<TripStopScreen> createState() => _TripStopScreenState();
}

class _TripStopScreenState extends State<TripStopScreen> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _trip;
  List<Map<String, dynamic>> _stops = [];
  Map<String, dynamic>? _currentStop;
  List<Map<String, dynamic>> _children = [];
  Map<String, String> _childStatus = {};
  bool _loading = true;
  bool _submitting = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final trip = await _db
          .from('trips')
          .select('id, type, status, route_id, driver_user_id')
          .eq('id', widget.tripId)
          .single();

      final isMorning = trip['type'] == 'morning_pickup';

      final stopsRaw = await _db
          .from('route_stops')
          .select('id, name, address, morning_sequence, evening_sequence, is_school')
          .eq('route_id', trip['route_id'])
          .eq('is_active', true)
          .order(isMorning ? 'morning_sequence' : 'evening_sequence');

      final stops = List<Map<String, dynamic>>.from(stopsRaw);

      // Find current stop
      Map<String, dynamic> currentStop;
      int currentIndex = 0;

      if (widget.stopId == 'next') {
        final departed = await _db
            .from('trip_stop_events')
            .select('route_stop_id')
            .eq('trip_id', widget.tripId)
            .eq('event_type', 'departed');

        final departedIds =
            (departed as List).map((e) => e['route_stop_id'] as String).toSet();

        currentIndex = stops.indexWhere((s) => !departedIds.contains(s['id']));
        if (currentIndex == -1) currentIndex = stops.length - 1;
        currentStop = stops[currentIndex];
      } else {
        currentIndex = stops.indexWhere((s) => s['id'] == widget.stopId);
        if (currentIndex == -1) currentIndex = 0;
        currentStop = stops[currentIndex];
      }

      // Load children at this stop
      final childrenField =
          isMorning ? 'morning_pickup_stop_id' : 'evening_drop_stop_id';
      final childrenRaw = await _db
          .from('students')
          .select('id, full_name, grade, section')
          .eq(childrenField, currentStop['id'])
          .eq('is_active', true);

      final children = List<Map<String, dynamic>>.from(childrenRaw);

      // Default status
      final statusMap = <String, String>{};
      for (final child in children) {
        statusMap[child['id']] = isMorning ? 'boarded' : 'dropped';
      }

      if (mounted) {
        setState(() {
          _trip = trip;
          _stops = stops;
          _currentStop = currentStop;
          _currentIndex = currentIndex;
          _children = children;
          _childStatus = statusMap;
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

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    try {
      // Insert student events
      if (_children.isNotEmpty) {
        final events = _children
            .map((child) => {
                  'trip_id': widget.tripId,
                  'student_id': child['id'],
                  'route_stop_id': _currentStop!['id'],
                  'status': _childStatus[child['id']],
                  'marked_by_user_id': _trip!['driver_user_id'],
                })
            .toList();
        await _db.from('student_trip_events').insert(events);
      }

      // Mark stop departed
      await _db.from('trip_stop_events').insert({
        'trip_id': widget.tripId,
        'route_stop_id': _currentStop!['id'],
        'event_type': 'departed',
      });

      if (!mounted) return;

      final isLast = _currentIndex >= _stops.length - 1;

      if (isLast) {
        // Complete trip
        await _db.from('trips').update({
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.tripId);

        // Stop GPS
        await LocationService.instance.stopTracking();

        if (mounted) {
          _showTripCompleteDialog();
        }
      } else {
        if (mounted) {
          context.go('/driver/trip/${widget.tripId}/stop/next');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showTripCompleteDialog() {
    final isMorning = _trip?['type'] == 'morning_pickup';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.green, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              isMorning ? 'Morning Trip Complete!' : 'Return Trip Complete!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isMorning
                  ? 'All children have been delivered safely to school.'
                  : 'All children have been dropped at their stops.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/driver');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final isMorning = _trip?['type'] == 'morning_pickup';
    final isSchool = _currentStop?['is_school'] == true;
    final total = _stops.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App bar row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.go('/driver'),
                        ),
                        Expanded(
                          child: Text(
                            isMorning ? 'Morning Pickup' : 'Return Trip',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  // Current stop name
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      _currentStop?['name'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Step indicator
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: List.generate(total, (i) {
                        final isPast = i < _currentIndex;
                        final isCurrent = i == _currentIndex;
                        return Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isPast || isCurrent
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              if (i < total - 1) const SizedBox(width: 4),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, right: 20),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Stop ${_currentIndex + 1} of $total',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: isSchool
                ? _SchoolArrivalView(
                    isMorning: isMorning,
                    onComplete: _confirm,
                    submitting: _submitting,
                  )
                : _children.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.child_care,
                                size: 48, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text(
                              'No children at this stop',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _children.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final child = _children[i];
                          final status = _childStatus[child['id']] ??
                              (isMorning ? 'boarded' : 'dropped');
                          return _ChildCard(
                            child: child,
                            status: status,
                            isMorning: isMorning,
                            onStatusChanged: (s) =>
                                setState(() => _childStatus[child['id']] = s),
                          );
                        },
                      ),
          ),

          // Bottom button
          if (!isSchool)
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              child: FilledButton(
                onPressed: _submitting ? null : _confirm,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _currentIndex < _stops.length - 2
                            ? 'Confirm & Next Stop'
                            : 'Confirm & Arrive at School',
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.status,
    required this.isMorning,
    required this.onStatusChanged,
  });
  final Map<String, dynamic> child;
  final String status;
  final bool isMorning;
  final ValueChanged<String> onStatusChanged;

  Color _statusColor() {
    switch (status) {
      case 'boarded':
      case 'dropped':
        return AppColors.green;
      case 'absent':
        return AppColors.orange;
      case 'still_onboard':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final options = isMorning
        ? [('boarded', 'Boarded'), ('absent', 'Absent')]
        : [('dropped', 'Dropped'), ('still_onboard', 'Still Onboard')];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  child['full_name'].toString()[0].toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child['full_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'boarded'
                      ? 'Boarded'
                      : status == 'absent'
                          ? 'Absent'
                          : status == 'dropped'
                              ? 'Dropped'
                              : 'Onboard',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: options.map((opt) {
              final isSelected = status == opt.$1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: opt == options.first ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => onStatusChanged(opt.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _optColor(opt.$1)
                            : const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? _optColor(opt.$1)
                              : const Color(0xFFDDE1EE),
                        ),
                      ),
                      child: Text(
                        opt.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _optColor(String s) {
    if (s == 'boarded' || s == 'dropped') return AppColors.green;
    if (s == 'absent') return AppColors.orange;
    return AppColors.primary;
  }
}

class _SchoolArrivalView extends StatelessWidget {
  const _SchoolArrivalView({
    required this.isMorning,
    required this.onComplete,
    required this.submitting,
  });
  final bool isMorning;
  final VoidCallback onComplete;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMorning ? Icons.school_rounded : Icons.home_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          Text(
            isMorning ? 'Arrived at School' : 'Route Complete',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMorning
                ? 'All children have been delivered to school safely.'
                : 'All children have been dropped at their stops.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: submitting ? null : onComplete,
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(isMorning
                    ? 'Complete Morning Trip'
                    : 'Complete Return Trip'),
          ),
        ],
      ),
    );
  }
}
