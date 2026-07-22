import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/nebah_colors.dart';
import '../../services/sos_service.dart';

class QuickTileSosScreen extends StatefulWidget {
  final SosService sosService;

  const QuickTileSosScreen({
    Key? key,
    required this.sosService,
  }) : super(key: key);

  @override
  State<QuickTileSosScreen> createState() => _QuickTileSosScreenState();
}

class _QuickTileSosScreenState extends State<QuickTileSosScreen> {
  bool _isTileEnabled = true;
  bool _isWidgetEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isTileEnabled = prefs.getBool('nebah_sos_tile_enabled') ?? true;
        _isWidgetEnabled = prefs.getBool('nebah_sos_widget_enabled') ?? true;
      });
    }
  }

  Future<void> _saveTileSetting(bool val) async {
    setState(() => _isTileEnabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nebah_sos_tile_enabled', val);
  }

  Future<void> _saveWidgetSetting(bool val) async {
    setState(() => _isWidgetEnabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nebah_sos_widget_enabled', val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quick Tile & Widget SOS'),
        backgroundColor: isDark ? NebahColors.navyBackground : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: NebahColors.crimsonRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.widgets_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero-Tap System Quick Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : NebahColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trigger silent panic directly from your Android Quick Settings shade or Home Screen widget.',
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
            ),
            const SizedBox(height: 24),

            // TOGGLE 1: QUICK SETTINGS TILE
            SwitchListTile.adaptive(
              value: _isTileEnabled,
              activeThumbColor: NebahColors.crimsonRed,
              title: Text(
                'Android Quick Settings SOS Tile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NebahColors.deepNavy,
                ),
              ),
              subtitle: const Text('Add "NEBAH PANIC" tile to phone swipe-down notification shade.'),
              onChanged: _saveTileSetting,
            ),
            const Divider(),

            // TOGGLE 2: HOME SCREEN WIDGET
            SwitchListTile.adaptive(
              value: _isWidgetEnabled,
              activeThumbColor: NebahColors.crimsonRed,
              title: Text(
                'Home Screen Panic Widget',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NebahColors.deepNavy,
                ),
              ),
              subtitle: const Text('1x1 emergency panic button on Android launcher.'),
              onChanged: _saveWidgetSetting,
            ),
            const SizedBox(height: 32),

            // TEST BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
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
                      content: Text('⚡ Quick Settings Panic Tile Triggered Successfully!'),
                      backgroundColor: NebahColors.crimsonRed,
                    ),
                  );
                },
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: const Text(
                  'SIMULATE QUICK TILE PANIC PRESS',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NebahColors.crimsonRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
