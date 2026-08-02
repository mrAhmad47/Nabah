import 'package:flutter/material.dart';
import '../core/theme/nebah_colors.dart';
import '../services/community_service.dart';
import '../services/onboarding_service.dart';
import '../services/sos_service.dart';
import 'community/community_hierarchy_screen.dart';
import 'emergency/categorized_sos_dialog.dart';
import 'home_map_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'premium_map_screen.dart';
import 'route_selection_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _checkingOnboarding = true;

  final CommunityService _communityService = CommunityService();
  final SosService _sosService = SosService();

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final isCompleted = await OnboardingService.isOnboardingCompleted();
    if (!isCompleted && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      if (mounted) {
        setState(() {
          _checkingOnboarding = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingOnboarding) {
      return const Scaffold(
        backgroundColor: NebahColors.navyBackground,
        body: Center(
          child: CircularProgressIndicator(color: NebahColors.cobaltBlue),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      const HomeMapScreen(),
      const RouteSelectionScreen(),
      CommunityHierarchyScreen(communityService: _communityService),
      const PremiumMapScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      // Center SOS Floating Action Button (Instant Interactive Categorized SOS Modal)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CategorizedSosDialog.show(
            context,
            sosService: _sosService,
          );
        },
        backgroundColor: NebahColors.crimsonRed,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.sos,
          size: 32,
          color: Colors.white,
        ),
      ),

      // Docked Navigation Bar (4 Core Tabs surrounding SOS FAB)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home Tab
              IconButton(
                icon: Icon(
                  _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  color: _selectedIndex == 0
                      ? NebahColors.cobaltBlue
                      : (isDark ? NebahColors.slateGrey : Colors.black54),
                ),
                tooltip: 'Home',
                onPressed: () => _onItemTapped(0),
              ),

              // 2. Route Guardian Navigation Tab
              IconButton(
                icon: Icon(
                  Icons.alt_route,
                  color: _selectedIndex == 1
                      ? NebahColors.cobaltBlue
                      : (isDark ? NebahColors.slateGrey : Colors.black54),
                ),
                tooltip: 'Route Guardian',
                onPressed: () => _onItemTapped(1),
              ),

              // Center Space for SOS FAB
              const SizedBox(width: 48),

              // 3. Community Tab
              IconButton(
                icon: Icon(
                  _selectedIndex == 2 ? Icons.groups : Icons.groups_outlined,
                  color: _selectedIndex == 2
                      ? NebahColors.cobaltBlue
                      : (isDark ? NebahColors.slateGrey : Colors.black54),
                ),
                tooltip: 'Community',
                onPressed: () => _onItemTapped(2),
              ),

              // 4. Safety Map Tab
              IconButton(
                icon: Icon(
                  _selectedIndex == 3 ? Icons.map : Icons.map_outlined,
                  color: _selectedIndex == 3
                      ? NebahColors.cobaltBlue
                      : (isDark ? NebahColors.slateGrey : Colors.black54),
                ),
                tooltip: 'Safety Map',
                onPressed: () => _onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
