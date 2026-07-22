/// Represents the 4 tiers of Nebah's traditional & administrative community hierarchy.
enum HierarchyLevel {
  subNeighbourhood(1, 'Sub-Neighbourhood (Mai Anguwa)'),
  district(2, 'District / Sector (Sarkin Yama)'),
  lga(3, 'City / LGA Command'),
  state(4, 'State Command / SEMA');

  final int value;
  final String label;
  const HierarchyLevel(this.value, this.label);

  static HierarchyLevel fromInt(int val) {
    return HierarchyLevel.values.firstWhere(
      (e) => e.value == val,
      orElse: () => HierarchyLevel.subNeighbourhood,
    );
  }
}

/// Node representing a community in the 4-tier tree hierarchy.
class CommunityNode {
  final String id;
  final String name;
  final HierarchyLevel level;
  final String? parentId;
  final String? leaderName;
  final String? leaderRole; // e.g., "Mai Anguwa", "Sarkin District"
  final bool isVerifiedLeader;
  final String locationAddress;
  final int memberCount;
  final int activeVigilantesCount;

  CommunityNode({
    required this.id,
    required this.name,
    required this.level,
    this.parentId,
    this.leaderName,
    this.leaderRole,
    this.isVerifiedLeader = true,
    required this.locationAddress,
    this.memberCount = 0,
    this.activeVigilantesCount = 0,
  });

  factory CommunityNode.fromJson(Map<String, dynamic> json) {
    return CommunityNode(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      level: HierarchyLevel.fromInt(json['level'] ?? 1),
      parentId: json['parent_id'],
      leaderName: json['leader_name'],
      leaderRole: json['leader_role'],
      isVerifiedLeader: json['is_verified_leader'] ?? true,
      locationAddress: json['location_address'] ?? '',
      memberCount: json['member_count'] ?? 0,
      activeVigilantesCount: json['active_vigilantes_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level.value,
      'parent_id': parentId,
      'leader_name': leaderName,
      'leader_role': leaderRole,
      'is_verified_leader': isVerifiedLeader,
      'location_address': locationAddress,
      'member_count': memberCount,
      'active_vigilantes_count': activeVigilantesCount,
    };
  }
}

/// Official announcement broadcast by verified community leaders.
class CommunityAnnouncement {
  final String id;
  final String communityId;
  final String communityName;
  final String authorName;
  final String authorRole;
  final String title;
  final String content;
  final String priority; // 'normal', 'urgent', 'emergency'
  final DateTime createdAt;
  final bool isPinned;

  CommunityAnnouncement({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.authorName,
    required this.authorRole,
    required this.title,
    required this.content,
    this.priority = 'normal',
    required this.createdAt,
    this.isPinned = false,
  });

  factory CommunityAnnouncement.fromJson(Map<String, dynamic> json) {
    return CommunityAnnouncement(
      id: json['id'] ?? '',
      communityId: json['community_id'] ?? '',
      communityName: json['community_name'] ?? '',
      authorName: json['author_name'] ?? '',
      authorRole: json['author_role'] ?? 'Community Leader',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      priority: json['priority'] ?? 'normal',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isPinned: json['is_pinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'community_name': communityName,
      'author_name': authorName,
      'author_role': authorRole,
      'title': title,
      'content': content,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'is_pinned': isPinned,
    };
  }
}

/// Represents a registered Vigilante or Private Security Group.
class VigilanteGroup {
  final String id;
  final String communityId;
  final String groupName;
  final String commanderName;
  final String badgePrefix;
  final bool isVerified;
  final int totalMembers;
  final int activeOnPatrol;

  VigilanteGroup({
    required this.id,
    required this.communityId,
    required this.groupName,
    required this.commanderName,
    this.badgePrefix = 'NEB-VIG',
    this.isVerified = true,
    this.totalMembers = 0,
    this.activeOnPatrol = 0,
  });

  factory VigilanteGroup.fromJson(Map<String, dynamic> json) {
    return VigilanteGroup(
      id: json['id'] ?? '',
      communityId: json['community_id'] ?? '',
      groupName: json['group_name'] ?? '',
      commanderName: json['commander_name'] ?? '',
      badgePrefix: json['badge_prefix'] ?? 'NEB-VIG',
      isVerified: json['is_verified'] ?? true,
      totalMembers: json['total_members'] ?? 0,
      activeOnPatrol: json['active_on_patrol'] ?? 0,
    );
  }
}

/// Represents a Vigilante Officer's Digital ID Card data.
class VigilanteMember {
  final String id;
  final String groupId;
  final String groupName;
  final String communityName;
  final String memberName;
  final String badgeNumber;
  final String rankTitle;
  final String photoUrl;
  final String qrData;
  final bool isPatrolActive;
  final DateTime issuedAt;
  final DateTime expiresAt;

  VigilanteMember({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.communityName,
    required this.memberName,
    required this.badgeNumber,
    this.rankTitle = 'Patrol Officer',
    this.photoUrl = '',
    required this.qrData,
    this.isPatrolActive = false,
    required this.issuedAt,
    required this.expiresAt,
  });

  factory VigilanteMember.fromJson(Map<String, dynamic> json) {
    return VigilanteMember(
      id: json['id'] ?? '',
      groupId: json['group_id'] ?? '',
      groupName: json['group_name'] ?? '',
      communityName: json['community_name'] ?? '',
      memberName: json['member_name'] ?? '',
      badgeNumber: json['badge_number'] ?? '',
      rankTitle: json['rank_title'] ?? 'Patrol Officer',
      photoUrl: json['photo_url'] ?? '',
      qrData: json['qr_data'] ?? '',
      isPatrolActive: json['is_patrol_active'] ?? false,
      issuedAt: json['issued_at'] != null
          ? DateTime.parse(json['issued_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(days: 365)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'group_name': groupName,
      'community_name': communityName,
      'member_name': memberName,
      'badge_number': badgeNumber,
      'rank_title': rankTitle,
      'photo_url': photoUrl,
      'qr_data': qrData,
      'is_patrol_active': isPatrolActive,
      'issued_at': issuedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}
