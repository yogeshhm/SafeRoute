import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripTrackingScreen extends StatefulWidget {
  const TripTrackingScreen({super.key, required this.tripId});
  final String tripId;

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final _db = Supabase.instance.client;
  GoogleMapController? _mapController;
  StreamSubscription<List<Map<String, dynamic>>>? _locationSub;

  Map<String, dynamic>? _trip;
  List<Map<String, dynamic>> _stops = [];
  LatLng? _busLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final trip = await _db
        .from('trips')
        .select('id, type, status, route_id')
        .eq('id', widget.tripId)
        .single();

    final stops = await _db
        .from('route_stops')
        .select('id, name, latitude, longitude, morning_sequence, evening_sequence, is_school')
        .eq('route_id', trip['route_id'])
        .eq('is_active', true)
        .order('morning_sequence');

    // Latest bus location
    final latest = await _db
        .from('trip_locations')
        .select('latitude, longitude')
        .eq('trip_id', widget.tripId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final stopList = List<Map<String, dynamic>>.from(stops);
    final busLatLng = latest != null
        ? LatLng(
            (latest['latitude'] as num).toDouble(),
            (latest['longitude'] as num).toDouble(),
          )
        : null;

    _buildMapOverlays(stopList, busLatLng);

    if (mounted) {
      setState(() {
        _trip = trip;
        _stops = stopList;
        _busLocation = busLatLng;
        _loading = false;
      });
    }

    _subscribeToLocation();
  }

  void _subscribeToLocation() {
    _locationSub = _db
        .from('trip_locations')
        .stream(primaryKey: ['id'])
        .eq('trip_id', widget.tripId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .listen((rows) {
          if (rows.isEmpty) return;
          final row = rows.first;
          final latLng = LatLng(
            (row['latitude'] as num).toDouble(),
            (row['longitude'] as num).toDouble(),
          );
          _buildMapOverlays(_stops, latLng);
          if (mounted) {
            setState(() => _busLocation = latLng);
            _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
          }
        });
  }

  void _buildMapOverlays(List<Map<String, dynamic>> stops, LatLng? busLatLng) {
    final markers = <Marker>{};
    final polylinePoints = <LatLng>[];

    for (final stop in stops) {
      final latLng = LatLng(
        (stop['latitude'] as num).toDouble(),
        (stop['longitude'] as num).toDouble(),
      );
      polylinePoints.add(latLng);
      markers.add(
        Marker(
          markerId: MarkerId(stop['id']),
          position: latLng,
          infoWindow: InfoWindow(title: stop['name']),
          icon: stop['is_school'] == true
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    if (busLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('bus'),
          position: busLatLng,
          infoWindow: const InfoWindow(title: 'Bus'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    final polylines = polylinePoints.length >= 2
        ? {
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylinePoints,
              color: const Color(0xFF1A56DB),
              width: 4,
            ),
          }
        : <Polyline>{};

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  LatLng get _initialCameraTarget {
    if (_busLocation != null) return _busLocation!;
    if (_stops.isNotEmpty) {
      return LatLng(
        (_stops.first['latitude'] as num).toDouble(),
        (_stops.first['longitude'] as num).toDouble(),
      );
    }
    return const LatLng(12.9466, 77.6220); // NPS Koramangala default
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isMorning = _trip?['type'] == 'morning_pickup';

    return Scaffold(
      appBar: AppBar(
        title: Text(isMorning ? 'Morning Pickup' : 'Return Trip'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCameraTarget,
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapController = c,
          ),

          // Stop list panel at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Stops',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_busLocation == null)
                          Text(
                            'Waiting for bus location...',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Live',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _stops.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final stop = _stops[i];
                        return _StopChip(stop: stop);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopChip extends StatelessWidget {
  const _StopChip({required this.stop});
  final Map<String, dynamic> stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSchool = stop['is_school'] == true;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSchool
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSchool
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSchool ? Icons.school_rounded : Icons.location_on_outlined,
            size: 20,
            color: isSchool
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 6),
          Text(
            stop['name'],
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSchool
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
