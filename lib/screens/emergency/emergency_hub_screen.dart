import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/nebah_colors.dart';
import '../../services/sos_service.dart';
import 'categorized_sos_dialog.dart';

class EmergencyHubScreen extends StatefulWidget {
  final SosService sosService;

  const EmergencyHubScreen({
    Key? key,
    required this.sosService,
  }) : super(key: key);

  @override
  State<EmergencyHubScreen> createState() => _EmergencyHubScreenState();
}

class _EmergencyHubScreenState extends State<EmergencyHubScreen> {
  bool _isHardwarePanicEnabled = true;
  String _panicTriggerGesture = 'Volume Triple Click';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Emergency Response Hub'),
        backgroundColor: isDark ? NebahColors.navyBackground : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BIG CATEGORIZED SOS TRIGGER BANNER
            GestureDetector(
              onTap: () => CategorizedSosDialog.show(
                context,
                sosService: widget.sosService,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE02424),
                      Color(0xFF9B1C1C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: NebahColors.crimsonRed.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.touch_app_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INTERACTIVE SOS',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Select Intruders, Medical, Fire, or Accident & alert local vigilantes',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // HARDWARE BUTTON PANIC CONFIGURATION (OUTSIDE ANDROID PANIC)
            Text(
              'Hardware Panic (Outside Android SOS)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hardware_outlined, color: NebahColors.cobaltBlue),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stealth Hardware Panic',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : NebahColors.deepNavy,
                                ),
                              ),
                              Text(
                                'Triggers without phone interaction',
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
                        value: _isHardwarePanicEnabled,
                        activeThumbColor: NebahColors.cobaltBlue,
                        onChanged: (val) {
                          setState(() {
                            _isHardwarePanicEnabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trigger Gesture:',
                        style: TextStyle(fontSize: 13, color: NebahColors.slateGrey),
                      ),
                      DropdownButton<String>(
                        value: _panicTriggerGesture,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : NebahColors.deepNavy,
                          fontWeight: FontWeight.bold,
                        ),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Volume Triple Click',
                            child: Text('Volume Triple Click'),
                          ),
                          DropdownMenuItem(
                            value: 'Power Button 3x Press',
                            child: Text('Power Button 3x Press'),
                          ),
                          DropdownMenuItem(
                            value: 'Volume Long Press (3s)',
                            child: Text('Volume Long Press (3s)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _panicTriggerGesture = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await widget.sosService.triggerHardwarePanic(
                          userId: 'usr_101',
                          userName: 'Audu Bello',
                          userPhone: '+234 802 999 1122',
                        );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('⚡ Test Hardware Panic Dispatched Successfully!'),
                            backgroundColor: NebahColors.crimsonRed,
                          ),
                        );
                      },
                      icon: const Icon(Icons.bolt, color: NebahColors.crimsonRed),
                      label: const Text(
                        'TEST HARDWARE PANIC DISPATCH',
                        style: TextStyle(
                          color: NebahColors.crimsonRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: NebahColors.crimsonRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // DIRECT EMERGENCY DIALERS
            Text(
              'Direct Security & Emergency Dialers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDialerCard(
                    icon: Icons.local_police,
                    color: NebahColors.cobaltBlue,
                    title: 'Police Force',
                    number: '112 / 08031234567',
                    isDark: isDark,
                    onTap: () => widget.sosService.makeEmergencyCall('112'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDialerCard(
                    icon: Icons.shield,
                    color: NebahColors.safetyEmerald,
                    title: 'Local Vigilante',
                    number: '+234 805 444 8899',
                    isDark: isDark,
                    onTap: () => widget.sosService.makeEmergencyCall('+2348054448899'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // EMERGENCY MEDICAL & IDENTITY QR CARD
            Text(
              'Emergency Medical & Identity QR Card',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medical_information, color: Colors.red, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Audu Bello (O+ Positive)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : NebahColors.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Emergency Contact: Alhaji Danladi (+2348031234567)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? NebahColors.slateGrey : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  QrImageView(
                    data: 'NEBAH-EMERGENCY-CARD|AUDU_BELLO|BLOOD_O_POS|CONTACT_2348031234567|SAKRN_YAMA',
                    version: QrVersions.auto,
                    size: 140.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'First responders scan this QR card for medical data & emergency contact info',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: NebahColors.slateGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialerCard({
    required IconData icon,
    required Color color,
    required String title,
    required String number,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              number,
              style: const TextStyle(fontSize: 11, color: NebahColors.slateGrey),
            ),
          ],
        ),
      ),
    );
  }
}
