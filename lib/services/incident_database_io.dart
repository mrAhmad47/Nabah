import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/incident_report.dart';

/// Native (io) implementation of IncidentDatabase using sqflite
class IncidentDatabasePlatform {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('incidents.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE incidents (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        locationName TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        description TEXT NOT NULL,
        severity INTEGER NOT NULL,
        source TEXT NOT NULL,
        verified INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertIncident(IncidentReport report) async {
    final db = await database;
    await db.insert(
      'incidents',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<IncidentReport>> getIncidents({int? daysBack}) async {
    final db = await database;
    
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (daysBack != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
      whereClause = 'timestamp >= ?';
      whereArgs = [cutoffDate.toIso8601String()];
    }

    final maps = await db.query(
      'incidents',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => IncidentReport.fromMap(map)).toList();
  }

  Future<List<IncidentReport>> getIncidentsNear({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int? daysBack,
  }) async {
    final allIncidents = await getIncidents(daysBack: daysBack);
    // Filter incidents within the specified radius using Haversine approximation
    return allIncidents.where((incident) {
      final dlat = (incident.location.latitude - latitude) * 111.32; // ~111km per degree lat
      final dlng = (incident.location.longitude - longitude) * 111.32 *
          _cosApprox(latitude);
      final distKm = _sqrt(dlat * dlat + dlng * dlng);
      return distKm <= radiusKm;
    }).toList();
  }

  // Simple cosine approximation for latitude-based longitude scaling
  static double _cosApprox(double latDeg) {
    final rad = latDeg * 3.14159265 / 180.0;
    return 1.0 - (rad * rad / 2.0); // Taylor series approximation
  }

  // Avoid importing dart:math just for sqrt — simple Newton's method
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2.0;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2.0;
    }
    return guess;
  }

  Future<void> deleteOldIncidents({required int daysOld}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    await db.delete(
      'incidents',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('incidents');
  }

  Future close() async {
    final db = await database;
    await db.close();
  }
}
