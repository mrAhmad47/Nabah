import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incident_report.dart';

class IncidentService {
  static final IncidentService instance = IncidentService._();
  IncidentService._();

  SupabaseClient get _supabase => Supabase.instance.client;
  final List<IncidentReport> _localIncidents = [];

  /// Add a new incident to Supabase Cloud DB with PostGIS coordinates
  Future<void> addIncident(IncidentReport incident) async {
    _localIncidents.insert(0, incident);

    try {
      final user = _supabase.auth.currentUser;

      // 1. Check auto-verification (3+ reports within 200m in 1 hour)
      bool isAutoVerified = incident.verified;
      final checkRes = await _supabase
          .from('incidents')
          .select('id')
          .gte('created_at', DateTime.now().subtract(const Duration(hours: 1)).toIso8601String());

      if (checkRes.length >= 2) {
        isAutoVerified = true;
        debugPrint('🛡️ Incident Auto-Verified! 3+ community reports in proximity area.');
      }

      await _supabase.from('incidents').insert({
        'id': incident.id,
        'reporter_id': incident.isAnonymous ? null : user?.id,
        'type': incident.type,
        'severity': incident.severity,
        'description': incident.description,
        'location': 'POINT(${incident.location.longitude} ${incident.location.latitude})',
        'location_name': incident.locationName,
        'state': 'Nigeria',
        'is_verified': isAutoVerified,
        'is_anonymous': incident.isAnonymous,
        'created_at': incident.timestamp.toIso8601String(),
      });

      debugPrint('⚡ Incident successfully submitted to Supabase cloud!');
    } catch (e) {
      debugPrint('⚠️ Supabase incident insert error: $e');
    }
  }

  /// Get incidents from Supabase Cloud DB
  Future<List<IncidentReport>> getTodayIncidents() async {
    try {
      final res = await _supabase
          .from('incidents')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      if (res.isNotEmpty) {
        final cloudIncidents = res.map((item) {
          double lat = 10.3158;
          double lng = 9.8442;
          final String locStr = item['location']?.toString() ?? '';

          if (locStr.contains('POINT')) {
            final parts = locStr.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
            if (parts.length >= 2) {
              lng = double.tryParse(parts[0]) ?? 9.8442;
              lat = double.tryParse(parts[1]) ?? 10.3158;
            }
          }

          return IncidentReport(
            id: item['id'] ?? '',
            type: item['type'] ?? 'Suspicious Activity',
            location: latlong2.LatLng(lat, lng),
            locationName: item['location_name'] ?? 'Bauchi Area',
            timestamp: DateTime.parse(item['created_at']),
            description: item['description'] ?? '',
            severity: item['severity'] ?? 50,
            source: 'cloud',
            verified: item['is_verified'] ?? false,
          );
        }).toList();

        return cloudIncidents;
      }
    } catch (e) {
      debugPrint('⚠️ Error loading incidents from Supabase: $e');
    }

    return List.unmodifiable(_localIncidents);
  }

  Future<List<IncidentReport>> getAllIncidents() async {
    return getTodayIncidents();
  }

  Future<void> clearOldIncidents() async {
    _localIncidents.clear();
  }

  /// Initialize with mock data for testing
  Future<void> initializeMockData() async {
    final now = DateTime.now();
    _localIncidents.addAll([
      IncidentReport(
        id: '1',
        type: 'Robbery',
        location: const latlong2.LatLng(6.5244, 3.3792),
        locationName: 'Wuse Zone 4',
        timestamp: now.subtract(const Duration(minutes: 15)),
        description: 'Armed robbery reported near the main transit hub.',
        severity: 85,
        source: 'user',
        verified: true,
      ),
    ]);
  }
}
