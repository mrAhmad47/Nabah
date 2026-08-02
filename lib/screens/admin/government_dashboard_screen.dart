import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/nebah_colors.dart';
import '../../models/community_hierarchy.dart';
import '../../services/community_service.dart';

class GovernmentDashboardScreen extends StatefulWidget {
  final CommunityService communityService;

  const GovernmentDashboardScreen({
    Key? key,
    required this.communityService,
  }) : super(key: key);

  @override
  State<GovernmentDashboardScreen> createState() => _GovernmentDashboardScreenState();
}

class _GovernmentDashboardScreenState extends State<GovernmentDashboardScreen> {
  final _annTitleController = TextEditingController();
  final _annContentController = TextEditingController();
  String _annPriority = 'normal';

  @override
  void dispose() {
    _annTitleController.dispose();
    _annContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Leader Command & Control Portal'),
        backgroundColor: isDark ? NebahColors.navyBackground : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WELCOME HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NebahColors.cobaltBlue.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: NebahColors.cobaltBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sarkin Yama Command Portal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Mai Anguwa Usman • Bauchi District Command',
                          style: TextStyle(fontSize: 12, color: NebahColors.slateGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // METRICS STATS ROW
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Active Patrols', '18 Officers', Icons.local_police, NebahColors.safetyEmerald, isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Pending SOS', '0 Active', Icons.warning_amber, NebahColors.cobaltBlue, isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Avg Response', '3.4 Mins', Icons.timer, Colors.amber.shade700, isDark),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // PUBLISH LEADER ANNOUNCEMENT FORM
            Text(
              'Publish Broadcast Advisory',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _annTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Advisory Title',
                      hintText: 'e.g. Night Patrol & Curfew Advisory',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _annContentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Advisory Content',
                      hintText: 'Enter details for residents in Sarkin Yama Quarter...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: _annPriority,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent Priority')),
                          DropdownMenuItem(value: 'emergency', child: Text('EMERGENCY ALERT')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _annPriority = val);
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_annTitleController.text.isNotEmpty) {
                            final messenger = ScaffoldMessenger.of(context);
                            final ann = CommunityAnnouncement(
                              id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
                              communityId: 'node_tier1_01',
                              communityName: 'Sarkin Yama Quarter',
                              authorName: 'Mallam Usman Danlami',
                              authorRole: 'Mai Anguwa (Leader)',
                              title: _annTitleController.text,
                              content: _annContentController.text,
                              priority: _annPriority,
                              createdAt: DateTime.now(),
                            );
                            await widget.communityService.postAnnouncement(ann);

                            // Insert into Supabase cloud DB
                            try {
                              await Supabase.instance.client.from('announcements').insert({
                                'id': ann.id,
                                'community_id': ann.communityId,
                                'author_name': ann.authorName,
                                'author_role': ann.authorRole,
                                'title': ann.title,
                                'content': ann.content,
                                'priority': ann.priority,
                                'created_at': ann.createdAt.toIso8601String(),
                              });
                              debugPrint('⚡ Broadcast advisory inserted into Supabase cloud DB!');
                            } catch (e) {
                              debugPrint('⚠️ Supabase announcement insert error: $e');
                            }

                            _annTitleController.clear();
                            _annContentController.clear();

                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('📢 Leader Announcement Broadcasted Successfully!'),
                                backgroundColor: NebahColors.safetyEmerald,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('BROADCAST'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NebahColors.cobaltBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : NebahColors.deepNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: NebahColors.slateGrey),
          ),
        ],
      ),
    );
  }
}
