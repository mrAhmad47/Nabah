import '../models/incident_report.dart';

/// Web (stub) implementation of IncidentDatabase
/// Uses in-memory storage since sqflite is not available on web
class IncidentDatabasePlatform {
  final List<IncidentReport> _memoryStore = [];

  Future<void> insertIncident(IncidentReport report) async {
    // Remove existing with same id
    _memoryStore.removeWhere((i) => i.id == report.id);
    _memoryStore.add(report);
  }

  Future<List<IncidentReport>> getIncidents({int? daysBack}) async {
    if (daysBack != null) {
      final cutoff = DateTime.now().subtract(Duration(days: daysBack));
      return _memoryStore
          .where((i) => i.timestamp.isAfter(cutoff))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return List.from(_memoryStore)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<List<IncidentReport>> getIncidentsNear({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int? daysBack,
  }) async {
    final all = await getIncidents(daysBack: daysBack);
    // Filter by approximate distance using equirectangular projection
    return all.where((incident) {
      final dlat = (incident.location.latitude - latitude) * 111.32;
      final dlng = (incident.location.longitude - longitude) * 111.32 *
          _cosApprox(latitude);
      final distKm = _sqrt(dlat * dlat + dlng * dlng);
      return distKm <= radiusKm;
    }).toList();
  }

  static double _cosApprox(double latDeg) {
    final rad = latDeg * 3.14159265 / 180.0;
    return 1.0 - (rad * rad / 2.0);
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2.0;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2.0;
    }
    return guess;
  }

  Future<void> deleteOldIncidents({required int daysOld}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    _memoryStore.removeWhere((i) => i.timestamp.isBefore(cutoff));
  }

  Future<void> clearAll() async {
    _memoryStore.clear();
  }

  Future<void> close() async {
    // No-op on web
  }
}
