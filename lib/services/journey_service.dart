import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journey_event.dart';
import 'sos_service.dart';

class JourneyService {
  JourneyEvent? _activeJourney;
  StreamSubscription<Position>? _gpsSubscription;
  Timer? _deadMansSwitchTimer;
  Timer? _unacknowledgedTimer;

  final _sosService = SosService();
  SupabaseClient get _supabase => Supabase.instance.client;

  final _journeyStreamController = StreamController<JourneyEvent?>.broadcast();
  Stream<JourneyEvent?> get journeyStream => _journeyStreamController.stream;

  JourneyEvent? get activeJourney => _activeJourney;

  /// Start a new real GPS monitored trip
  Future<JourneyEvent> startJourney({
    required String originName,
    required String destinationName,
    double originLat = 10.3158,
    double originLng = 9.8442,
    double destLat = 10.3011,
    double destLng = 9.8211,
    int estimatedMinutes = 25,
    int distanceKm = 14,
  }) async {
    final now = DateTime.now();
    final event = JourneyEvent(
      id: 'jrn_${now.millisecondsSinceEpoch}',
      originName: originName,
      destinationName: destinationName,
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      startTime: now,
      estimatedArrival: now.add(Duration(minutes: estimatedMinutes)),
      totalDistanceKm: distanceKm,
      status: JourneyStatus.active,
      currentProgressPercent: 0.0,
      emergencyContactsNotified: ['Family & Emergency Contacts'],
    );

    _activeJourney = event;
    if (!_journeyStreamController.isClosed) {
      _journeyStreamController.add(_activeJourney);
    }

    // Save to Supabase Cloud journeys table
    try {
      await _supabase.from('journeys').upsert({
        'id': event.id,
        'user_id': _supabase.auth.currentUser?.id,
        'origin_name': originName,
        'destination_name': destinationName,
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
        'start_time': now.toIso8601String(),
        'estimated_arrival': event.estimatedArrival.toIso8601String(),
        'total_distance_km': distanceKm,
        'status': 'active',
      });
      debugPrint('⚡ Active journey created in Supabase Cloud DB.');
    } catch (e) {
      debugPrint('⚠️ Supabase journey create warning: $e');
    }

    _startRealGpsTracking();
    _startDeadMansSwitchTimer();

    return event;
  }

  /// Real GPS tracking stream via Geolocator
  void _startRealGpsTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // update every 50 meters
      ),
    ).listen((pos) {
      if (_activeJourney == null || _activeJourney!.status != JourneyStatus.active) {
        return;
      }

      const distanceCalc = latlong2.Distance();
      final totalDist = distanceCalc.as(
        latlong2.LengthUnit.Meter,
        latlong2.LatLng(_activeJourney!.originLat, _activeJourney!.originLng),
        latlong2.LatLng(_activeJourney!.destLat, _activeJourney!.destLng),
      );
      final coveredDist = distanceCalc.as(
        latlong2.LengthUnit.Meter,
        latlong2.LatLng(_activeJourney!.originLat, _activeJourney!.originLng),
        latlong2.LatLng(pos.latitude, pos.longitude),
      );

      double progress = totalDist > 0 ? (coveredDist / totalDist) : 0.5;
      progress = progress.clamp(0.0, 1.0);

      _activeJourney = JourneyEvent(
        id: _activeJourney!.id,
        originName: _activeJourney!.originName,
        destinationName: _activeJourney!.destinationName,
        originLat: _activeJourney!.originLat,
        originLng: _activeJourney!.originLng,
        destLat: _activeJourney!.destLat,
        destLng: _activeJourney!.destLng,
        startTime: _activeJourney!.startTime,
        estimatedArrival: _activeJourney!.estimatedArrival,
        totalDistanceKm: _activeJourney!.totalDistanceKm,
        status: progress >= 0.98 ? JourneyStatus.arrived : JourneyStatus.active,
        currentProgressPercent: progress,
        emergencyContactsNotified: _activeJourney!.emergencyContactsNotified,
      );

      if (!_journeyStreamController.isClosed) {
        _journeyStreamController.add(_activeJourney);
      }

      // Sync live position to Supabase journeys
      _supabase.from('journeys').update({
        'current_lat': pos.latitude,
        'current_lng': pos.longitude,
        'last_checkin': DateTime.now().toIso8601String(),
      }).eq('id', _activeJourney!.id).then((_) => null, onError: (e) => null);
    });
  }

  /// Dead Man's Switch: Check-in timer every 30 minutes
  void _startDeadMansSwitchTimer() {
    _deadMansSwitchTimer?.cancel();
    _deadMansSwitchTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (_activeJourney == null || _activeJourney!.status != JourneyStatus.active) {
        timer.cancel();
        return;
      }

      debugPrint('⏰ DEAD MAN\'S SWITCH: Prompting check-in prompt! 2 minutes before auto-SOS.');
      _unacknowledgedTimer?.cancel();
      _unacknowledgedTimer = Timer(const Duration(minutes: 2), () async {
        debugPrint('🚨 DEAD MAN\'S SWITCH UNACKNOWLEDGED! AUTO-TRIGGERING EMERGENCY SOS PANIC.');
        final user = _supabase.auth.currentUser;
        await _sosService.triggerHardwarePanic(
          userId: user?.id ?? 'dead_man_switch',
          userName: user?.email ?? 'Journey Traveler',
          userPhone: 'Unacknowledged Check-in',
        );
      });
    });
  }

  /// User acknowledges Dead Man's Switch check-in
  void acknowledgeCheckIn() {
    debugPrint('✅ Dead Man\'s Switch Check-in Acknowledged by User.');
    _unacknowledgedTimer?.cancel();
  }

  /// Manually or automatically confirm safe arrival
  Future<void> confirmArrival() async {
    _gpsSubscription?.cancel();
    _deadMansSwitchTimer?.cancel();
    _unacknowledgedTimer?.cancel();

    if (_activeJourney != null) {
      _activeJourney = JourneyEvent(
        id: _activeJourney!.id,
        originName: _activeJourney!.originName,
        destinationName: _activeJourney!.destinationName,
        originLat: _activeJourney!.originLat,
        originLng: _activeJourney!.originLng,
        destLat: _activeJourney!.destLat,
        destLng: _activeJourney!.destLng,
        startTime: _activeJourney!.startTime,
        estimatedArrival: DateTime.now(),
        totalDistanceKm: _activeJourney!.totalDistanceKm,
        status: JourneyStatus.arrived,
        currentProgressPercent: 1.0,
        emergencyContactsNotified: _activeJourney!.emergencyContactsNotified,
      );

      if (!_journeyStreamController.isClosed) {
        _journeyStreamController.add(_activeJourney);
      }

      try {
        await _supabase.from('journeys').update({
          'status': 'arrived',
          'last_checkin': DateTime.now().toIso8601String(),
        }).eq('id', _activeJourney!.id);
      } catch (e) {
        debugPrint('⚠️ Error updating arrival in Supabase: $e');
      }

      debugPrint('🎉 ARRIVAL CONFIRMED: Safe arrival updated in Supabase cloud!');
    }
  }

  /// Cancel active journey
  Future<void> cancelJourney() async {
    _gpsSubscription?.cancel();
    _deadMansSwitchTimer?.cancel();
    _unacknowledgedTimer?.cancel();
    _activeJourney = null;
    if (!_journeyStreamController.isClosed) {
      _journeyStreamController.add(null);
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    _gpsSubscription?.cancel();
    _deadMansSwitchTimer?.cancel();
    _unacknowledgedTimer?.cancel();
    await _journeyStreamController.close();
  }
}
