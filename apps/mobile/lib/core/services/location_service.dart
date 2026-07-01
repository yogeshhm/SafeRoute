import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._();
  static LocationService get instance => _instance;
  LocationService._();

  final _db = Supabase.instance.client;
  StreamSubscription<Position>? _subscription;
  String? _activeTripId;
  String? _activeBusId;

  bool get isTracking => _subscription != null;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> startTracking({
    required String tripId,
    required String busId,
  }) async {
    if (_subscription != null) await stopTracking();

    final granted = await requestPermission();
    if (!granted) return;

    _activeTripId = tripId;
    _activeBusId = busId;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // send update every 10 metres
    );

    _subscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition, onError: (_) {});
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _activeTripId = null;
    _activeBusId = null;
  }

  Future<void> _onPosition(Position pos) async {
    if (_activeTripId == null || _activeBusId == null) return;
    try {
      await _db.from('trip_locations').insert({
        'trip_id': _activeTripId,
        'bus_id': _activeBusId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'speed_kmph': pos.speed >= 0 ? pos.speed * 3.6 : null,
        'heading': pos.heading >= 0 ? pos.heading : null,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
