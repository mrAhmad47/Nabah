import '../models/incident_report.dart';

// Conditional import: sqflite only on non-web platforms
import 'incident_database_stub.dart'
    if (dart.library.io) 'incident_database_io.dart';

/// Platform-aware Incident Database
/// 
/// On mobile/desktop: uses sqflite for local storage
/// On web: uses in-memory storage (no sqflite support)
class IncidentDatabase {
  static final IncidentDatabase instance = IncidentDatabase._init();
  
  final IncidentDatabasePlatform _platform = IncidentDatabasePlatform();

  IncidentDatabase._init();

  /// Insert a new incident report
  Future<void> insertIncident(IncidentReport report) async {
    await _platform.insertIncident(report);
  }

  /// Get all incidents (optionally filtered by recency)
  Future<List<IncidentReport>> getIncidents({int? daysBack}) async {
    return await _platform.getIncidents(daysBack: daysBack);
  }

  /// Get incidents near a location (within radius in kilometers)
  Future<List<IncidentReport>> getIncidentsNear({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int? daysBack,
  }) async {
    return await _platform.getIncidentsNear(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      daysBack: daysBack,
    );
  }

  /// Delete old incidents (cleanup task)
  Future<void> deleteOldIncidents({required int daysOld}) async {
    await _platform.deleteOldIncidents(daysOld: daysOld);
  }

  /// Clear all incidents (for testing)
  Future<void> clearAll() async {
    await _platform.clearAll();
  }

  /// Close database
  Future close() async {
    await _platform.close();
  }
}
