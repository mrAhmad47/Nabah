import 'package:flutter/material.dart';
import '../../core/theme/nebah_colors.dart';
import '../../models/community_hierarchy.dart';
import '../../services/community_service.dart';
import '../../services/community_detection_service.dart';
import '../../services/geolocation_service.dart';
import '../../services/zone_chat_service.dart';
import '../../services/geofencing_service.dart';
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

  // Data
  List<CommunityNode> _hierarchyNodes = [];
  List<CommunityAnnouncement> _announcements = [];
  CommunityDetectionResult? _detectedZone;
  List<Map<String, dynamic>> _zoneEvents = [];
  bool _isLoading = true;

  // Services
  final CommunityDetectionService _detectionService = CommunityDetectionService();
  final GeolocationService _geoService = GeolocationService();
  final ZoneChatService _chatService = ZoneChatService();
  final GeofencingService _geofencingService = GeofencingService();

  // Chat state
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isSendingMessage = false;
  // Current user identity (simplified — in production from auth)
  static const String _myUserId = 'current_user';
  static const String _myName = 'You';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    // 1. Detect real GPS-based zone
    final location = await _geoService.getCurrentLocation();
    if (location != null) {
      final zone = await _detectionService.detectCommunity(
        location.latitude,
        location.longitude,
      );
      if (mounted) setState(() => _detectedZone = zone);

      // Join zone chat and start geofencing
      await _chatService.joinZone(zone.communityId);
      _geofencingService.setHomeZone(zone.communityId);
      await _geofencingService.startMonitoring();

      // Load zone events for alerts tab
      final events = await _geofencingService.getZoneEvents(zone.communityId);
      if (mounted) setState(() => _zoneEvents = events);
    } else {
      // GPS not available — use fallback zone
      const fallbackZoneId = 'zone_sarkin_yama';
      await _chatService.joinZone(fallbackZoneId);
    }

    // 2. Load hierarchy nodes and announcements
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

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);
    _chatController.clear();

    await _chatService.sendMessage(
      senderName: _myName,
      senderId: _myUserId,
      message: text,
    );

    setState(() => _isSendingMessage = false);

    // Scroll to bottom
    if (_chatScrollController.hasClients) {
      await Future.delayed(const Duration(milliseconds: 100));
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Neighbourhood'),
        backgroundColor: isDark ? NebahColors.navyBackground : Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined, color: NebahColors.cobaltBlue),
            tooltip: 'Vigilante Digital ID',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VigilanteIdScreen(
                  communityService: widget.communityService,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NebahColors.cobaltBlue,
          labelColor: NebahColors.cobaltBlue,
          unselectedLabelColor: isDark ? NebahColors.slateGrey : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.home_work_outlined, size: 18), text: 'My Zone'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Zone Chat'),
            Tab(icon: Icon(Icons.warning_amber_outlined, size: 18), text: 'Alerts'),
            Tab(icon: Icon(Icons.campaign_outlined, size: 18), text: 'Announcements'),
            Tab(icon: Icon(Icons.account_tree_outlined, size: 18), text: 'Hierarchy'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(isDark)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyZoneTab(isDark),
                _buildZoneChatTab(isDark),
                _buildZoneAlertsTab(isDark),
                _buildAnnouncementsTab(isDark),
                _buildHierarchyTreeTab(isDark),
              ],
            ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: NebahColors.cobaltBlue),
          const SizedBox(height: 16),
          Text(
            'Detecting your neighbourhood...',
            style: TextStyle(
              color: isDark ? NebahColors.slateGrey : Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 1: MY ZONE
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMyZoneTab(bool isDark) {
    final zone = _detectedZone;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Zone Detection Banner
          _buildZoneBanner(zone, isDark),
          const SizedBox(height: 20),

          // Safety Status Card
          _buildSafetyStatusCard(isDark),
          const SizedBox(height: 16),

          // Stats Grid
          _buildStatsGrid(isDark),
          const SizedBox(height: 16),

          // Geofencing Status Card
          _buildGeofencingStatusCard(isDark),
          const SizedBox(height: 16),

          // Quick Actions
          _buildQuickActions(isDark),
        ],
      ),
    );
  }

  Widget _buildZoneBanner(CommunityDetectionResult? zone, bool isDark) {
    final zoneName = zone?.name ?? 'Detecting zone...';
    final lga = zone?.lga ?? '—';
    final state = zone?.state ?? '—';
    final isMapped = zone?.isMapped ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NebahColors.cobaltBlue,
            NebahColors.cobaltBlue.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NebahColors.cobaltBlue.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(

            children: [
              const Icon(Icons.my_location, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isMapped ? 'YOUR REGISTERED ZONE' : 'AUTO-DETECTED ZONE',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zoneName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$lga • $state',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isMapped
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMapped ? Colors.greenAccent : Colors.orangeAccent,
                    width: 1,
                  ),
                ),
                child: Text(
                  isMapped ? '✅ MAPPED' : '🔍 UNREGISTERED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMapped ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),

          if (!isMapped) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your neighbourhood is not registered yet. Ask your Mai Anguwa to register on Nebah.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? NebahColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NebahColors.safetyEmerald.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NebahColors.safetyEmerald.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('78', style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: NebahColors.safetyEmerald,
              )),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zone Safety Score',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : NebahColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '🟢 Moderate — 2 incidents in last 7 days',
                  style: TextStyle(fontSize: 12, color: NebahColors.slateGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    final node = _hierarchyNodes.isNotEmpty ? _hierarchyNodes.first : null;
    return Row(
      children: [
        _buildStatTile(
          isDark,
          icon: Icons.people_alt_outlined,
          value: node != null ? '${node.memberCount}' : '—',
          label: 'Residents',
          color: NebahColors.cobaltBlue,
        ),
        const SizedBox(width: 12),
        _buildStatTile(
          isDark,
          icon: Icons.local_police_outlined,
          value: node != null ? '${node.activeVigilantesCount}' : '—',
          label: 'On Patrol',
          color: NebahColors.safetyEmerald,
        ),
        const SizedBox(width: 12),
        _buildStatTile(
          isDark,
          icon: Icons.shield_moon_outlined,
          value: _zoneEvents.where((e) => e['is_night_time'] == true).length.toString(),
          label: 'Night Events',
          color: Colors.amber.shade700,
        ),
      ],
    );
  }

  Widget _buildStatTile(bool isDark, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? NebahColors.slate800 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : NebahColors.deepNavy,
            )),
            Text(label, style: const TextStyle(
              fontSize: 10,
              color: NebahColors.slateGrey,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofencingStatusCard(bool isDark) {
    final isActive = _geofencingService.isRunning;
    final isNight = GeofencingService.isNightAlertWindow();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? NebahColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? NebahColors.safetyEmerald.withValues(alpha: 0.4)
              : NebahColors.slateGrey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radar,
                color: isActive ? NebahColors.safetyEmerald : NebahColors.slateGrey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Zone Boundary Monitor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : NebahColors.deepNavy,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? NebahColors.safetyEmerald.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? '● ACTIVE' : '○ INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? NebahColors.safetyEmerald : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isActive
                ? 'Silently monitoring who enters and exits your zone.'
                : 'Background location permission needed to monitor zone.',
            style: const TextStyle(fontSize: 12, color: NebahColors.slateGrey),
          ),
          if (isNight) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_moon, color: Colors.amber, size: 14),
                  SizedBox(width: 6),
                  Text(
                    '🌙 NIGHT ALERT MODE ACTIVE (12AM–5AM)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildActionButton(
              label: 'Zone Chat',
              icon: Icons.chat_bubble_outline,
              color: NebahColors.cobaltBlue,
              onTap: () => _tabController.animateTo(1),
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              label: 'Zone Alerts',
              icon: Icons.warning_amber_outlined,
              color: Colors.amber.shade700,
              onTap: () => _tabController.animateTo(2),
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              label: 'My Vigilante ID',
              icon: Icons.badge_outlined,
              color: NebahColors.safetyEmerald,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VigilanteIdScreen(communityService: widget.communityService),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? NebahColors.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 2: ZONE CHAT
  // ─────────────────────────────────────────────────────────────────
  Widget _buildZoneChatTab(bool isDark) {
    final zoneName = _detectedZone?.name ?? 'Your Zone';
    return Column(
      children: [
        // Zone chat header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? NebahColors.slate800 : const Color(0xFFEFF6FF),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble, color: NebahColors.cobaltBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$zoneName — Residents Only',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : NebahColors.deepNavy,
                  ),
                ),
              ),
              const Text(
                '🔒 Private',
                style: TextStyle(fontSize: 11, color: NebahColors.slateGrey),
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: StreamBuilder<List<ZoneMessage>>(
            stream: _chatService.messagesStream,
            initialData: _chatService.messages,
            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48,
                          color: isDark ? NebahColors.slateGrey : Colors.black26),
                      const SizedBox(height: 12),
                      Text(
                        'No messages yet.\nBe the first to greet your neighbours!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? NebahColors.slateGrey : Colors.black45,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (ctx, i) => _buildMessageBubble(messages[i], isDark),
              );
            },
          ),
        ),

        // Message input bar
        _buildChatInputBar(isDark),
      ],
    );
  }

  Widget _buildMessageBubble(ZoneMessage msg, bool isDark) {
    final isMe = msg.senderId == _myUserId;
    final time =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: msg.isLeader
                  ? NebahColors.cobaltBlue
                  : NebahColors.slate800,
              child: Text(
                msg.senderName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Row(
                      children: [
                        Text(
                          msg.senderName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: NebahColors.slateGrey,
                          ),
                        ),
                        if (msg.isLeader) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: NebahColors.cobaltBlue,
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? NebahColors.cobaltBlue
                        : msg.isLeader
                            ? NebahColors.cobaltBlue.withValues(alpha: 0.15)
                            : (isDark ? NebahColors.slate800 : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: msg.isLeader && !isMe
                        ? Border.all(
                            color: NebahColors.cobaltBlue.withValues(alpha: 0.3),
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isMe
                          ? Colors.white
                          : (isDark ? Colors.white : NebahColors.deepNavy),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: NebahColors.slateGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? NebahColors.slate800 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? NebahColors.navyBackground : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _chatController,
                maxLines: 3,
                minLines: 1,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Message your neighbours...',
                  hintStyle: TextStyle(
                    color: NebahColors.slateGrey,
                    fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendChatMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSendingMessage ? null : _sendChatMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSendingMessage
                    ? NebahColors.slateGrey
                    : NebahColors.cobaltBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSendingMessage ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 3: ZONE ALERTS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildZoneAlertsTab(bool isDark) {
    final nightEvents = _zoneEvents
        .where((e) => e['is_night_time'] == true && e['is_resident'] == false)
        .toList();
    final visitorEvents =
        _zoneEvents.where((e) => e['is_resident'] == false).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Night Movement Alert Banner
          if (nightEvents.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_moon, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${nightEvents.length} suspicious movement(s) detected between 12AM–5AM in the last 24 hours.',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Summary Stats
          Row(
            children: [
              _buildAlertStat('Total Entries', _zoneEvents.length.toString(),
                  NebahColors.cobaltBlue, isDark),
              const SizedBox(width: 12),
              _buildAlertStat('Visitors', visitorEvents.length.toString(),
                  Colors.amber.shade700, isDark),
              const SizedBox(width: 12),
              _buildAlertStat('Night Events', nightEvents.length.toString(),
                  NebahColors.crimsonRed, isDark),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Recent Zone Events',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : NebahColors.deepNavy,
            ),
          ),
          const SizedBox(height: 10),

          if (_zoneEvents.isEmpty)
            _buildEmptyAlerts(isDark)
          else
            ..._zoneEvents.take(20).map((e) => _buildEventRow(e, isDark)),

          const SizedBox(height: 20),
          // Demo sample events when empty
          if (_zoneEvents.isEmpty) _buildDemoAlerts(isDark),
        ],
      ),
    );
  }

  Widget _buildAlertStat(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? NebahColors.slate800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            )),
            Text(label, style: const TextStyle(
              fontSize: 10,
              color: NebahColors.slateGrey,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEventRow(Map<String, dynamic> event, bool isDark) {
    final isNight = event['is_night_time'] == true;
    final isResident = event['is_resident'] == true;
    final eventType = event['event_type'] ?? 'enter';
    final createdAt = event['created_at'] != null
        ? DateTime.tryParse(event['created_at']) ?? DateTime.now()
        : DateTime.now();
    final time =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    Color dotColor = isResident
        ? NebahColors.safetyEmerald
        : isNight
            ? NebahColors.crimsonRed
            : Colors.amber.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? NebahColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNight && !isResident
              ? NebahColors.crimsonRed.withValues(alpha: 0.3)
              : (isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${eventType.toUpperCase()} — ${isResident ? "Resident" : isNight ? "⚠️ Night Visitor" : "Visitor"}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              ),
            ),
          ),
          Text(time, style: const TextStyle(
            fontSize: 11,
            color: NebahColors.slateGrey,
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyAlerts(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No zone events yet. Events appear as residents\nenter and exit the neighbourhood boundary.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? NebahColors.slateGrey : Colors.black45,
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAlerts(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sample Events (Live data appears when geofencing is active)',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? NebahColors.slateGrey : Colors.black38,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        _buildEventRow({
          'event_type': 'enter',
          'is_resident': true,
          'is_night_time': false,
          'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        }, isDark),
        _buildEventRow({
          'event_type': 'enter',
          'is_resident': false,
          'is_night_time': true,
          'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        }, isDark),
        _buildEventRow({
          'event_type': 'exit',
          'is_resident': false,
          'is_night_time': true,
          'created_at': DateTime.now().subtract(const Duration(hours: 2, minutes: 45)).toIso8601String(),
        }, isDark),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 4: ANNOUNCEMENTS (existing, improved)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAnnouncementsTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      itemBuilder: (ctx, index) {
        final ann = _announcements[index];
        final isEmergency = ann.priority == 'emergency' || ann.priority == 'urgent';
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? NebahColors.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmergency
                  ? NebahColors.crimsonRed.withValues(alpha: 0.5)
                  : (isDark ? Colors.white10 : Colors.black12),
              width: isEmergency ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? NebahColors.crimsonRed.withValues(alpha: 0.15)
                          : NebahColors.cobaltBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ann.priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isEmergency ? NebahColors.crimsonRed : NebahColors.cobaltBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ann.communityName,
                    style: const TextStyle(fontSize: 11, color: NebahColors.slateGrey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(ann.title, style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              )),
              const SizedBox(height: 6),
              Text(ann.content, style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: NebahColors.slateGrey,
              )),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.verified, size: 13, color: NebahColors.safetyEmerald),
                  const SizedBox(width: 4),
                  Text(
                    '${ann.authorName} • ${ann.authorRole}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 5: HIERARCHY TREE (existing, kept intact)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHierarchyTreeTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ..._hierarchyNodes.map((node) => _buildNodeCard(node, isDark)),
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
        color: isDark ? NebahColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: node.level == HierarchyLevel.subNeighbourhood
              ? tierColor
              : (isDark ? Colors.white10 : Colors.black12),
          width: node.level == HierarchyLevel.subNeighbourhood ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(node.name, style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NebahColors.deepNavy,
            )),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 18, color: NebahColors.cobaltBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          node.leaderName ?? 'Community Leader',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (node.isVerifiedLeader) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 16, color: NebahColors.safetyEmerald),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              node.leaderRole ?? 'Administrative Head',
              style: const TextStyle(fontSize: 12, color: NebahColors.slateGrey),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 16, color: NebahColors.slateGrey),
                    const SizedBox(width: 6),
                    Text('${node.memberCount} Residents',
                        style: const TextStyle(fontSize: 12, color: NebahColors.slateGrey)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_police_outlined, size: 16, color: NebahColors.safetyEmerald),
                    const SizedBox(width: 6),
                    Text('${node.activeVigilantesCount} Active Security',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: NebahColors.safetyEmerald,
                        )),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
