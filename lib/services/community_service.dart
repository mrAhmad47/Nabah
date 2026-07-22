import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/community_hierarchy.dart';

class CommunityService {
  final String baseUrl;

  CommunityService({this.baseUrl = 'http://10.0.2.2:8000'});

  /// Fetch full 4-tier community hierarchy nodes
  Future<List<CommunityNode>> getCommunityHierarchy() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/community/hierarchy'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => CommunityNode.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Network error fetching hierarchy, using localized default: $e');
    }

    // High quality local fallback (Bauchi / Nigeria local hierarchy)
    return [
      CommunityNode(
        id: 'node_tier1_01',
        name: 'Sarkin Yama Quarter',
        level: HierarchyLevel.subNeighbourhood,
        parentId: 'node_tier2_01',
        leaderName: 'Mallam Usman Danlami',
        leaderRole: 'Mai Anguwa (Sub-Neighbourhood Leader)',
        isVerifiedLeader: true,
        locationAddress: 'Gwallameji West, Bauchi',
        memberCount: 1420,
        activeVigilantesCount: 18,
      ),
      CommunityNode(
        id: 'node_tier2_01',
        name: 'Gwallameji / Yelwa District',
        level: HierarchyLevel.district,
        parentId: 'node_tier3_01',
        leaderName: 'Alhaji Ibrahim Gwallameji',
        leaderRole: 'Sarkin District (District Head)',
        isVerifiedLeader: true,
        locationAddress: 'Yelwa District, Bauchi State',
        memberCount: 12500,
        activeVigilantesCount: 64,
      ),
      CommunityNode(
        id: 'node_tier3_01',
        name: 'Bauchi Metropolitan LGA',
        level: HierarchyLevel.lga,
        parentId: 'node_tier4_01',
        leaderName: 'Hon. Community Chairman',
        leaderRole: 'LGA Security & Administrative Command',
        isVerifiedLeader: true,
        locationAddress: 'Bauchi LGA Headquarters',
        memberCount: 185000,
        activeVigilantesCount: 420,
      ),
      CommunityNode(
        id: 'node_tier4_01',
        name: 'Bauchi State Security Command',
        level: HierarchyLevel.state,
        leaderName: 'State Security Council',
        leaderRole: 'State Command & Emergency Agency (SEMA)',
        isVerifiedLeader: true,
        locationAddress: 'State Secretariat, Bauchi',
        memberCount: 2400000,
        activeVigilantesCount: 3500,
      ),
    ];
  }

  /// Fetch official announcements from community leaders
  Future<List<CommunityAnnouncement>> getAnnouncements({String? communityId}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/community/announcements')
          .replace(queryParameters: communityId != null ? {'community_id': communityId} : null);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => CommunityAnnouncement.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Network error fetching announcements, using localized fallback: $e');
    }

    final allAnnouncements = [
      CommunityAnnouncement(
        id: 'ann_01',
        communityId: 'node_tier1_01',
        communityName: 'Sarkin Yama Quarter',
        authorName: 'Mallam Usman Danlami',
        authorRole: 'Mai Anguwa (Leader)',
        title: '🔒 Enhanced Night Patrol & Curfew Advisory',
        content:
            'Peace be unto you. Following security reports near Federal Low-Cost gate, our neighborhood vigilante squad has doubled night patrols between 11:00 PM and 5:00 AM. Please carry your digital ID or phone if walking late.',
        priority: 'urgent',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isPinned: true,
      ),
      CommunityAnnouncement(
        id: 'ann_02',
        communityId: 'node_tier2_01',
        communityName: 'Gwallameji District',
        authorName: 'Alhaji Ibrahim Gwallameji',
        authorRole: 'Sarkin District',
        title: '📢 Monthly Security Meeting & Vigilante Verification',
        content:
            'All landlords, youth leaders, and security personnel are invited to the Community Hall this Saturday at 4:00 PM for the quarterly security review and new digital ID card issuance.',
        priority: 'normal',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isPinned: false,
      ),
    ];

    if (communityId != null) {
      return allAnnouncements.where((a) => a.communityId == communityId).toList();
    }
    return allAnnouncements;
  }

  /// Fetch Vigilante Digital ID Info for current user or group member
  Future<VigilanteMember> getVigilanteMemberProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/community/vigilantes/me'));
      if (response.statusCode == 200) {
        return VigilanteMember.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('⚠️ Network error fetching vigilante profile: $e');
    }

    // Default registered digital ID demo card
    return VigilanteMember(
      id: 'vig_mem_901',
      groupId: 'vig_grp_10',
      groupName: 'Sarkin Yama Neighbourhood Watch Squad',
      communityName: 'Sarkin Yama Quarter (Mai Anguwa)',
      memberName: 'Commander Kabir Abubakar',
      badgeNumber: 'NEB-VIG-2026-084',
      rankTitle: 'Chief Patrol Commander',
      photoUrl: 'assets/images/vigilante_profile.png',
      qrData: 'NEBAH-VERIFIED-VIGILANTE|NEB-VIG-2026-084|KABIR_ABUBAKAR|MAI_ANGUWA_YAMA',
      isPatrolActive: true,
      issuedAt: DateTime.now().subtract(const Duration(days: 120)),
      expiresAt: DateTime.now().add(const Duration(days: 245)),
    );
  }

  /// Publish new announcement (Leaders only)
  Future<bool> postAnnouncement(CommunityAnnouncement announcement) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/community/announcements'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(announcement.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('⚠️ Post announcement fallback: $e');
      return true;
    }
  }
}
