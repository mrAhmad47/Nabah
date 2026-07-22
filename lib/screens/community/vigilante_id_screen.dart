import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/nebah_colors.dart';
import '../../models/community_hierarchy.dart';
import '../../services/community_service.dart';

class VigilanteIdScreen extends StatefulWidget {
  final CommunityService communityService;

  const VigilanteIdScreen({
    Key? key,
    required this.communityService,
  }) : super(key: key);

  @override
  State<VigilanteIdScreen> createState() => _VigilanteIdScreenState();
}

class _VigilanteIdScreenState extends State<VigilanteIdScreen> {
  VigilanteMember? _member;
  bool _isLoading = true;
  bool _isPatrolActive = true;

  @override
  void initState() {
    super.initState();
    _loadVigilanteData();
  }

  Future<void> _loadVigilanteData() async {
    final member = await widget.communityService.getVigilanteMemberProfile('usr_current');
    if (mounted) {
      setState(() {
        _member = member;
        _isPatrolActive = member.isPatrolActive;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Digital Security ID Card'),
        backgroundColor: isDark ? NebahColors.navyBackground : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Patrol Status Toggle Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _isPatrolActive
                                    ? NebahColors.safetyEmerald
                                    : NebahColors.slateGrey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPatrolActive ? 'ACTIVE ON PATROL' : 'OFF DUTY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : NebahColors.deepNavy,
                                  ),
                                ),
                                Text(
                                  _isPatrolActive
                                      ? 'Receiving neighbourhood SOS dispatches'
                                      : 'Patrol alerts paused',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? NebahColors.slateGrey : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isPatrolActive,
                          activeThumbColor: NebahColors.safetyEmerald,
                          onChanged: (val) {
                            setState(() {
                              _isPatrolActive = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // DIGITAL ID CARD BADGE UI
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1E3A8A),
                          Color(0xFF0F172A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: NebahColors.cobaltBlue.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NebahColors.cobaltBlue.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Card Header & Verified Stamp
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.shield, color: NebahColors.cobaltBlue, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'NEBAH VIGILANTE ID',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: NebahColors.safetyEmerald.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: NebahColors.safetyEmerald),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified, color: NebahColors.safetyEmerald, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'VERIFIED',
                                    style: TextStyle(
                                      color: NebahColors.safetyEmerald,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 32),

                        // Officer Photo Avatar Placeholder
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: NebahColors.cobaltBlue.withValues(alpha: 0.3),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Member Name & Rank
                        Text(
                          _member?.memberName ?? 'Commander Kabir Abubakar',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _member?.rankTitle ?? 'Chief Patrol Commander',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: NebahColors.slateGrey,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Badge Number Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Text(
                            'BADGE #: ${_member?.badgeNumber ?? "NEB-VIG-2026-084"}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Jurisdiction Details
                        _buildCardDetailRow('Group:', _member?.groupName ?? 'Sarkin Yama Watch Squad'),
                        const SizedBox(height: 6),
                        _buildCardDetailRow('Jurisdiction:', _member?.communityName ?? 'Sarkin Yama Quarter'),
                        const SizedBox(height: 6),
                        _buildCardDetailRow('Issuer:', 'Bauchi District Traditional Security Council'),

                        const Divider(color: Colors.white24, height: 32),

                        // QR Code Verification
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _member?.qrData ?? 'NEBAH-VERIFIED-VIGILANTE-084',
                            version: QrVersions.auto,
                            size: 160.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Scan with Nebah app to verify authentic officer credentials',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCardDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: NebahColors.slateGrey, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
