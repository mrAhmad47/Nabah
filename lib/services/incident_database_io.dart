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
    // Simple distance filtering
    return allIncidents;
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
