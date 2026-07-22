import 'package:flutter/material.dart';
import '../../core/theme/nebah_colors.dart';
import '../../models/community_hierarchy.dart';
import '../../services/community_service.dart';
import 'vigilante_id_screen.dart';

class CommunityHierarchyScreen extends StatefulWidget {
  final CommunityService communityService;

  const CommunityHierarchyScreen({
    Key? key,
    required this.communityService,
  }) : super(key: key);

  @override
  State<CommunityHierarchyScreen> createState() => _CommunityHierarchyScreenState();
}

class _CommunityHierarchyScreenState extends State<CommunityHierarchyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CommunityNode> _hierarchyNodes = [];
  List<CommunityAnnouncement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCommunityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunityData() async {
    final nodes = await widget.communityService.getCommunityHierarchy();
    final ann = await widget.communityService.getAnnouncements();

    if (mounted) {
      setState(() {
        _hierarchyNodes = nodes;
        _announcements = ann;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Community Safety & Governance'),
        backgroundColor: isDark ? NebahColors.navyBackground : Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined, color: NebahColors.cobaltBlue),
            tooltip: 'Vigilante Digital ID',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VigilanteIdScreen(
                    communityService: widget.communityService,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NebahColors.cobaltBlue,
          labelColor: NebahColors.cobaltBlue,
          unselectedLabelColor: isDark ? NebahColors.slateGrey : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Hierarchy Tree'),
            Tab(text: 'Leader Announcements'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHierarchyTreeTab(isDark),
                _buildAnnouncementsTab(isDark),
              ],
            ),
    );
  }

  /// Tab 1: 4-Tier Community Hierarchy Tree
  Widget _buildHierarchyTreeTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NebahColors.cobaltBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: NebahColors.cobaltBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_tree_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '4-Tier Traditional & Command Structure',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : NebahColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From your Mai Anguwa quarter to State Emergency Command.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? NebahColors.slateGrey : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Hierarchy Node Cards (Ordered 1 to 4)
          ..._hierarchyNodes.map((node) => _buildNodeCard(node, isDark)).toList(),
        ],
      ),
    );
  }

  Widget _buildNodeCard(CommunityNode node, bool isDark) {
    Color tierColor;
    IconData tierIcon;

    switch (node.level) {
      case HierarchyLevel.subNeighbourhood:
        tierColor = NebahColors.safetyEmerald;
        tierIcon = Icons.home_work_outlined;
        break;
      case HierarchyLevel.district:
        tierColor = NebahColors.cobaltBlue;
        tierIcon = Icons.holiday_village_outlined;
        break;
      case HierarchyLevel.lga:
        tierColor = Colors.amber.shade700;
        tierIcon = Icons.location_city_outlined;
        break;
      case HierarchyLevel.state:
        tierColor = NebahColors.crimsonRed;
        tierIcon = Icons.account_balance_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: node.level == HierarchyLevel.subNeighbourhood
              ? tierColor
              : (isDark ? Colors.white10 : Colors.black12),
          width: node.level == HierarchyLevel.subNeighbourhood ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(tierIcon, size: 14, color: tierColor),
                      const SizedBox(width: 6),
                      Text(
                        'TIER ${node.level.value}: ${node.level.label}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tierColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (node.level == HierarchyLevel.subNeighbourhood)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: NebahColors.safetyEmerald,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'YOUR QUARTER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              node.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              ),
            ),
            const SizedBox(height: 6),

            // Leader Info
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 18, color: NebahColors.cobaltBlue),
                const SizedBox(width: 8),
                Text(
                  node.leaderName ?? 'Community Leader',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                if (node.isVerifiedLeader)
                  const Icon(Icons.verified, size: 16, color: NebahColors.safetyEmerald),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              node.leaderRole ?? 'Administrative Head',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? NebahColors.slateGrey : Colors.black54,
              ),
            ),

            const Divider(height: 24),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 16, color: NebahColors.slateGrey),
                    const SizedBox(width: 6),
                    Text(
                      '${node.memberCount} Residents',
                      style: const TextStyle(fontSize: 12, color: NebahColors.slateGrey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.local_police_outlined, size: 16, color: NebahColors.safetyEmerald),
                    const SizedBox(width: 6),
                    Text(
                      '${node.activeVigilantesCount} Active Security',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: NebahColors.safetyEmerald,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tab 2: Leader Broadcast Announcements
  Widget _buildAnnouncementsTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: _announcements.length,
      itemBuilder: (ctx, index) {
        final ann = _announcements[index];
        final isEmergency = ann.priority == 'emergency' || ann.priority == 'urgent';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmergency
                  ? NebahColors.crimsonRed
                  : (isDark ? Colors.white10 : Colors.black12),
              width: isEmergency ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? NebahColors.crimsonRed.withValues(alpha: 0.15)
                          : NebahColors.cobaltBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ann.priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isEmergency ? NebahColors.crimsonRed : NebahColors.cobaltBlue,
                      ),
                    ),
                  ),
                  Text(
                    ann.communityName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? NebahColors.slateGrey : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ann.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NebahColors.deepNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ann.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 14, color: NebahColors.safetyEmerald),
                      const SizedBox(width: 4),
                      Text(
                        '${ann.authorName} (${ann.authorRole})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white60 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${ann.createdAt.hour}:${ann.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: NebahColors.slateGrey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
