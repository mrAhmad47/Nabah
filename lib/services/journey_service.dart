import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/journey_event.dart';

class JourneyService {
  JourneyEvent? _activeJourney;
  Timer? _simulationTimer;

  final _journeyStreamController = StreamController<JourneyEvent?>.broadcast();
  Stream<JourneyEvent?> get journeyStream => _journeyStreamController.stream;

  JourneyEvent? get activeJourney => _activeJourney;

  /// Start a new monitored trip
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
      currentProgressPercent: 0.05,
      emergencyContactsNotified: ['Alhaji Danladi (+2348031234567)'],
    );

    _activeJourney = event;
    if (!_journeyStreamController.isClosed) {
      _journeyStreamController.add(_activeJourney);
    }
    _startSimulatedProgress();
    return event;
  }

  /// Simulate live GPS progression along route
  void _startSimulatedProgress() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_activeJourney == null || _activeJourney!.status == JourneyStatus.arrived) {
        timer.cancel();
        return;
      }

      double nextProgress = _activeJourney!.currentProgressPercent + 0.05;
      if (nextProgress >= 1.0) {
        nextProgress = 1.0;
        timer.cancel();
        confirmArrival();
      } else {
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
          status: JourneyStatus.active,
          currentProgressPercent: nextProgress,
          emergencyContactsNotified: _activeJourney!.emergencyContactsNotified,
        );
        if (!_journeyStreamController.isClosed) {
          _journeyStreamController.add(_activeJourney);
        }
      }
    });
  }

  /// Manually or automatically confirm safe arrival
  Future<void> confirmArrival() async {
    _simulationTimer?.cancel();
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
      debugPrint('🎉 ARRIVAL CONFIRMED: Safe arrival SMS dispatched to emergency contacts!');
    }
  }

  /// Cancel active journey
  Future<void> cancelJourney() async {
    _simulationTimer?.cancel();
    _activeJourney = null;
    if (!_journeyStreamController.isClosed) {
      _journeyStreamController.add(null);
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    _simulationTimer?.cancel();
    await _journeyStreamController.close();
  }
}
