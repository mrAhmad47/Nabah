/// Represents traditional & administrative community levels in Nebah.
/// 
/// Hierarchy Levels:
/// 1: Sub-Neighbourhood / Mai Anguwa (e.g. Street Quarter level)
/// 2: District / Sarkin Yama (e.g. Cluster of quarters / Gwallameji)
/// 3: City / Emirate / LGA (e.g. Bauchi LGA)
/// 4: State / Regional Command (e.g. Bauchi State Command)
enum CommunityLevel {
  subNeighbourhood(1, 'Sub-Neighbourhood / Mai Anguwa'),
  district(2, 'District / Sarkin Yama'),
  cityLga(3, 'City / Emirate / LGA'),
  state(4, 'State Command');

  final int value;
  final String label;
  const CommunityLevel(this.value, this.label);
}

class CommunityNode {
  final String id;
  final String name;
  final CommunityLevel level;
  final String? parentId;
  final String leaderName;
  final String leaderTitle; // e.g. "Mai Anguwa", "Sarkin Yama", "LGA Chairman"
  final bool isVerified;
  final int memberCount;

  CommunityNode({
    required this.id,
    required this.name,
    required this.level,
    this.parentId,
    required this.leaderName,
    required this.leaderTitle,
    this.isVerified = true,
    this.memberCount = 0,
  });

  factory CommunityNode.fromJson(Map<String, dynamic> json) {
    return CommunityNode(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      level: CommunityLevel.values.firstWhere(
        (l) => l.value == (json['level'] ?? 1),
        orElse: () => CommunityLevel.subNeighbourhood,
      ),
      parentId: json['parentId'],
      leaderName: json['leaderName'] ?? 'Community Chief',
      leaderTitle: json['leaderTitle'] ?? 'Mai Anguwa',
      isVerified: json['isVerified'] ?? true,
      memberCount: json['memberCount'] ?? 0,
    );
  }
}

class CommunityAnnouncement {
  final String id;
  final String communityId;
  final String communityName;
  final String authorName;
  final String authorTitle;
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isUrgent;

  CommunityAnnouncement({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.authorName,
    required this.authorTitle,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isUrgent = false,
  });
}
