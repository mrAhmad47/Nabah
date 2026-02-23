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
    // Simple filter — return all for now (proper distance calc on web is fine)
    return all;
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
