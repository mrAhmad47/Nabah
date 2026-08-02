import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityDetectionResult {
  final bool isMapped;
  final String communityId;
  final String name;
  final String level;
  final String lga;
  final String state;
  final String? leaderName;

  CommunityDetectionResult({
    required this.isMapped,
    required this.communityId,
    required this.name,
    required this.level,
    required this.lga,
    required this.state,
    this.leaderName,
  });
}

class CommunityDetectionService {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Auto-detect community hierarchy from GPS coordinates via PostGIS
  Future<CommunityDetectionResult> detectCommunity(double lat, double lng) async {
    try {
      debugPrint('📍 Detecting community at GPS: ($lat, $lng) via PostGIS RPC...');

      // 1. Query PostGIS RPC function `find_community_at_location`
      final dynamic rpcRes = await _supabase.rpc(
        'find_community_at_location',
        params: {'lat': lat, 'lng': lng},
      );

      if (rpcRes != null && rpcRes is Map<String, dynamic> && rpcRes['id'] != null) {
        debugPrint('✅ Found mapped community: ${rpcRes['name']} (${rpcRes['level']})');
        return CommunityDetectionResult(
          isMapped: true,
          communityId: rpcRes['id'],
          name: rpcRes['name'],
          level: rpcRes['level'],
          lga: rpcRes['lga'] ?? 'LGA Command',
          state: rpcRes['state'] ?? 'Nigeria',
          leaderName: rpcRes['leader_name'],
        );
      }
    } catch (e) {
      debugPrint('⚠️ PostGIS RPC detection warning: $e');
    }

    // 2. Unclaimed Mode Fallback: Free reverse geocode via Nominatim OSM
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final response = await http.get(url, headers: {'User-Agent': 'NebahSafetyApp/1.0'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] ?? {};
        final lga = address['county'] ?? address['city'] ?? address['town'] ?? 'Bauchi LGA';
        final state = address['state'] ?? 'Bauchi State';

        debugPrint('🌍 Unclaimed Location Auto-Detected via OSM: $lga, $state');
        return CommunityDetectionResult(
          isMapped: false,
          communityId: 'unclaimed_${lga.toLowerCase().replaceAll(' ', '_')}',
          name: '$lga Quarter',
          level: 'lga',
          lga: lga,
          state: state,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Nominatim OSM reverse geocode error: $e');
    }

    return CommunityDetectionResult(
      isMapped: false,
      communityId: 'unclaimed_default',
      name: 'Bauchi Central Quarter',
      level: 'sub_neighbourhood',
      lga: 'Bauchi LGA',
      state: 'Bauchi State',
    );
  }

  /// Expand community boundary polygon dynamically when a new border member joins
  Future<void> expandBoundaryForMember({
    required String communityId,
    required double lat,
    required double lng,
  }) async {
    try {
      debugPrint('📐 Expanding PostGIS convex hull boundary for community: $communityId');
      await _supabase.rpc(
        'expand_community_boundary_for_member',
        params: {
          'community_id_param': communityId,
          'member_lat': lat,
          'member_lng': lng,
        },
      );
    } catch (e) {
      debugPrint('⚠️ PostGIS boundary expansion RPC error: $e');
    }
  }
}
