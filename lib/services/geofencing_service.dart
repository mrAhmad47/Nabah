import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Zone entry/exit event logged silently to Supabase
class ZoneEvent {
  final String zoneId;
  final String zoneName;
  final String eventType; // 'enter', 'exit', or 'dwell'
  final bool isResident;
  final bool isNightTime; // 12AM–5AM window
  final double lat;
  final double lng;
  final DateTime createdAt;

  ZoneEvent({
    required this.zoneId,
    required this.zoneName,
    required this.eventType,
    required this.isResident,
    required this.isNightTime,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'zone_id': zoneId,
    'zone_name': zoneName,
    'event_type': eventType,
    'is_resident': isResident,
    'is_night_time': isNightTime,
    'lat': lat,
    'lng': lng,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Represents a active community zone boundary to monitor
class ZoneBoundary {
  final String id;
  final String name;
  final latlong2.LatLng center;
  final double radiusMeters;
  bool isInside;

  ZoneBoundary({
    required this.id,
    required this.name,
    required this.center,
    this.radiusMeters = 250.0,
    this.isInside = false,
  });
}

/// GeofencingService — Native GPS-based zone boundary detection engine.
///
/// Uses standard Geolocator position stream + LatLong2 distance math.
/// Requires NO external plugins, zero AGP issues, and compiles 100% offline.
/// Silently logs ENTER/EXIT events to Supabase zone_events table.
/// Flags suspicious movement between 12:00AM – 5:00AM.
class GeofencingService {
  static final GeofencingService _instance = GeofencingService._internal();
  factory GeofencingService() => _instance;
  GeofencingService._internal();

  final latlong2.Distance _distanceCalc = const latlong2.Distance();
  final List<ZoneBoundary> _activeZones = [];
  StreamSubscription<Position>? _positionSubscription;

  String? _userHomeZoneId;
  bool _isRunning = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Set the user's home zone so we can tag visitors correctly
  void setHomeZone(String zoneId) {
    _userHomeZoneId = zoneId;
    debugPrint('🏠 Home zone set: $zoneId');
  }

  /// Load zone boundaries and start GPS stream monitoring
  Future<void> startMonitoring() async {
    if (_isRunning) return;

    try {
      debugPrint('🛡️ Starting native geofence monitoring...');

      // 1. Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied — geofencing disabled');
          return;
        }
      }

      // 2. Load community zones from Supabase (or demo fallback)
      await _loadZonesFromSupabase();

      if (_activeZones.isEmpty) {
        debugPrint('⚠️ No zones loaded — geofencing skipped');
        return;
      }

      // 3. Start position stream (checks every 10 meters)
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(_onPositionUpdated);

      _isRunning = true;
      debugPrint('✅ Native Geofencing active — monitoring ${_activeZones.length} zones');
    } catch (e) {
      debugPrint('⚠️ Geofencing start error: $e');
    }
  }

  /// Stop position stream monitoring
  Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isRunning = false;
    debugPrint('🛑 Geofencing stopped');
  }

  /// Load zone boundaries from Supabase or fallback
  Future<void> _loadZonesFromSupabase() async {
    _activeZones.clear();
    try {
      final response = await _supabase
          .from('communities')
          .select('id, name, level, center_lat, center_lng')
          .eq('level', 'sub_neighbourhood')
          .not('center_lat', 'is', null)
          .limit(50);

      for (final zone in (response as List)) {
        final lat = (zone['center_lat'] as num?)?.toDouble();
        final lng = (zone['center_lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        _activeZones.add(
          ZoneBoundary(
            id: zone['id'] as String,
            name: zone['name'] as String? ?? zone['id'],
            center: latlong2.LatLng(lat, lng),
            radiusMeters: 250.0,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Loading zones fallback to demo zones: $e');
    }

    // Default demo zones if list is empty
    if (_activeZones.isEmpty) {
      _activeZones.addAll([
        ZoneBoundary(
          id: 'zone_sarkin_yama',
          name: 'Sarkin Yama Quarter',
          center: const latlong2.LatLng(10.3158, 9.8442),
          radiusMeters: 300.0,
        ),
        ZoneBoundary(
          id: 'zone_gwallameji',
          name: 'Gwallameji Quarter',
          center: const latlong2.LatLng(10.3200, 9.8500),
          radiusMeters: 300.0,
        ),
      ]);
    }

    debugPrint('📍 Loaded ${_activeZones.length} active zone boundaries');
  }

  /// Evaluated whenever GPS position updates
  void _onPositionUpdated(Position position) {
    final currentPos = latlong2.LatLng(position.latitude, position.longitude);
    final now = DateTime.now();
    final isNightTime = now.hour >= 0 && now.hour < 5;

    for (final zone in _activeZones) {
      // Calculate distance between user and zone center in meters
      final distanceInMeters = _distanceCalc.as(
        latlong2.LengthUnit.Meter,
        currentPos,
        zone.center,
      );

      final isCurrentlyInside = distanceInMeters <= zone.radiusMeters;

      // Detect ENTER event
      if (isCurrentlyInside && !zone.isInside) {
        zone.isInside = true;
        _onZoneEventTriggered(
          zone: zone,
          eventType: 'enter',
          lat: position.latitude,
          lng: position.longitude,
          isNightTime: isNightTime,
          now: now,
        );
      }
      // Detect EXIT event
      else if (!isCurrentlyInside && zone.isInside) {
        zone.isInside = false;
        _onZoneEventTriggered(
          zone: zone,
          eventType: 'exit',
          lat: position.latitude,
          lng: position.longitude,
          isNightTime: isNightTime,
          now: now,
        );
      }
    }
  }

  /// Triggered on zone boundary crossing
  void _onZoneEventTriggered({
    required ZoneBoundary zone,
    required String eventType,
    required double lat,
    required double lng,
    required bool isNightTime,
    required DateTime now,
  }) {
    final isResident = _userHomeZoneId == zone.id;

    debugPrint(
      '🔔 Zone event: $eventType | Zone: ${zone.name} (${zone.id}) | '
      'Resident: $isResident | Night: $isNightTime',
    );

    // Silently log to Supabase
    _logZoneEvent(
      ZoneEvent(
        zoneId: zone.id,
        zoneName: zone.name,
        eventType: eventType,
        isResident: isResident,
        isNightTime: isNightTime,
        lat: lat,
        lng: lng,
        createdAt: now,
      ),
    );
  }

  /// Silently insert zone event into Supabase zone_events table
  Future<void> _logZoneEvent(ZoneEvent event) async {
    try {
      await _supabase.from('zone_events').insert(event.toJson());
      debugPrint('✅ Zone event logged: ${event.eventType} | ${event.zoneId}');
    } catch (e) {
      debugPrint('⚠️ Could not log zone event: $e');
    }
  }

  /// Get recent zone events for a specific zone
  Future<List<Map<String, dynamic>>> getZoneEvents(String zoneId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('zone_events')
          .select()
          .eq('zone_id', zoneId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('⚠️ Error fetching zone events: $e');
      return [];
    }
  }

  /// Get suspicious night-time movement events in the last 24h
  Future<List<Map<String, dynamic>>> getNightAlerts(String zoneId) async {
    try {
      final since = DateTime.now().subtract(const Duration(hours: 24));
      final response = await _supabase
          .from('zone_events')
          .select()
          .eq('zone_id', zoneId)
          .eq('is_night_time', true)
          .eq('is_resident', false)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('⚠️ Error fetching night alerts: $e');
      return [];
    }
  }

  /// Whether monitoring is active
  bool get isRunning => _isRunning;

  /// Check if current hour is 12AM–5AM
  static bool isNightAlertWindow() {
    final hour = DateTime.now().hour;
    return hour >= 0 && hour < 5;
  }

  /// Center point utility
  static latlong2.LatLng geofenceCenterFromId(String geofenceId) {
    return const latlong2.LatLng(10.3158, 9.8442);
  }
}
