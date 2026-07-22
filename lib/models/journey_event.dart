enum JourneyStatus {
  active('ACTIVE', 'Journey in Progress'),
  delayed('DELAYED', 'Delayed / Unexpected Stop'),
  deviated('DEVIATED', 'Route Deviation Alert'),
  arrived('ARRIVED', 'Arrived Safely');

  final String code;
  final String label;
  const JourneyStatus(this.code, this.label);
}

class JourneyEvent {
  final String id;
  final String originName;
  final String destinationName;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final DateTime startTime;
  final DateTime estimatedArrival;
  final int totalDistanceKm;
  final JourneyStatus status;
  final double currentProgressPercent; // 0.0 to 1.0
  final List<String> emergencyContactsNotified;

  JourneyEvent({
    required this.id,
    required this.originName,
    required this.destinationName,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.startTime,
    required this.estimatedArrival,
    required this.totalDistanceKm,
    this.status = JourneyStatus.active,
    this.currentProgressPercent = 0.0,
    this.emergencyContactsNotified = const [],
  });

  int get remainingMinutes {
    final now = DateTime.now();
    if (now.isAfter(estimatedArrival)) return 0;
    return estimatedArrival.difference(now).inMinutes;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'origin_name': originName,
        'destination_name': destinationName,
        'start_time': startTime.toIso8601String(),
        'estimated_arrival': estimatedArrival.toIso8601String(),
        'total_distance_km': totalDistanceKm,
        'status': status.code,
        'current_progress': currentProgressPercent,
        'emergency_contacts': emergencyContactsNotified,
      };
}
