import 'package:latlong2/latlong.dart';

class IncidentReport {
  final String id;
  final String type; // 'Robbery', 'Harassment', 'Accident', etc.
  final LatLng location;
  final String locationName;
  final DateTime timestamp;
  final String description;
  final int severity; // 1-100, where 100 is most severe
  final String source; // 'user' or 'news' or 'ai'
  final bool verified;
  final bool isAnonymous;

  IncidentReport({
    required this.id,
    required this.type,
    required this.location,
    required this.locationName,
    required this.timestamp,
    required this.description,
    required this.severity,
    this.source = 'user',
    this.verified = false,
    this.isAnonymous = false,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'locationName': locationName,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'severity': severity,
      'source': source,
      'verified': verified ? 1 : 0,
    };
  }

  // Create from database Map
  factory IncidentReport.fromMap(Map<String, dynamic> map) {
    return IncidentReport(
      id: map['id'],
      type: map['type'],
      location: LatLng(map['latitude'], map['longitude']),
      locationName: map['locationName'],
      timestamp: DateTime.parse(map['timestamp']),
      description: map['description'],
      severity: map['severity'],
      source: map['source'],
      verified: map['verified'] == 1,
    );
  }

  // Calculate intensity for heatmap (0.0 to 1.0)
  double get heatmapIntensity {
    // Recent reports weighted more heavily
    final daysSinceReport = DateTime.now().difference(timestamp).inDays;
    final recencyFactor = daysSinceReport < 1 ? 1.0 
                        : daysSinceReport < 7 ? 0.8
                        : daysSinceReport < 30 ? 0.5
                        : 0.3;
    
    // Combine severity and recency
    return (severity / 100.0) * recencyFactor;
  }
}
