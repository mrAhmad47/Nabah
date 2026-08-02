import 'package:flutter/material.dart';
import '../../core/theme/nebah_colors.dart';
import '../../services/onboarding_service.dart';
import '../main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _contactNameController =
      TextEditingController(text: 'Alhaji Danladi (Father)');
  final TextEditingController _contactPhoneController =
      TextEditingController(text: '+234 803 123 4567');

  String _selectedCommunityId = 'node_tier1_01';
  String _selectedCommunityName = 'Sarkin Yama Quarter (Mai Anguwa)';

  final List<Map<String, String>> _neighbourhoodOptions = [
    {
      'id': 'node_tier1_01',
      'name': 'Sarkin Yama Quarter (Mai Anguwa Usman)',
      'district': 'Gwallameji West, Bauchi',
    },
    {
      'id': 'node_tier1_02',
      'name': 'Federal Low-Cost Quarter (Mai Anguwa Bala)',
      'district': 'Low-Cost District, Bauchi',
    },
    {
      'id': 'node_tier1_03',
      'name': 'Yelwa Makaranta Quarter (Mai Anguwa Kabir)',
      'district': 'Yelwa Axis, Bauchi',
    },
    {
      'id': 'node_tier1_04',
      'name': 'GRA Sub-Sector (Mai Anguwa Ahmadu)',
      'district': 'GRA Core, Bauchi',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Logo & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NebahColors.cobaltBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: NebahColors.cobaltBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'NEBAH',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: isDark ? Colors.white : NebahColors.deepNavy,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark ? NebahColors.slateGrey : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page View Carousel
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomeSlide(isDark),
                  _buildCommunitySelectionSlide(isDark),
                  _buildEmergencyContactsSlide(isDark),
                ],
              ),
            ),

            // Bottom Navigation Indicators & Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? NebahColors.cobaltBlue
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Action Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NebahColors.cobaltBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == 2 ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == 2 ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
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

  /// Slide 1: Welcome & Features Overview
  Widget _buildWelcomeSlide(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: NebahColors.cobaltBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 90,
                  color: NebahColors.cobaltBlue.withValues(alpha: 0.2),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 56,
                      color: NebahColors.cobaltBlue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'AI-Powered Community Safety Ecosystem',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : NebahColors.deepNavy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Welcome to Nebah',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NebahColors.deepNavy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Protecting your journeys and connecting community vigilantes, traditional leaders, and citizens for instant emergency response.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? NebahColors.slateGrey : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureRow(
            icon: Icons.flash_on_rounded,
            color: NebahColors.crimsonRed,
            title: 'Dual-Mode SOS Panic',
            subtitle: 'Stealth hardware button trigger & categorized emergency selection.',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            icon: Icons.account_tree_outlined,
            color: NebahColors.cobaltBlue,
            title: '4-Tier Community Hierarchy',
            subtitle: 'Direct connection from Mai Anguwa to Sarkin District & LGA Command.',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            icon: Icons.badge_outlined,
            color: NebahColors.safetyEmerald,
            title: 'Vigilante Digital ID Cards',
            subtitle: 'Verified local security outfits with live patrol status & QR verification.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Slide 2: Neighbourhood / Mai Anguwa Quarter Selection
  Widget _buildCommunitySelectionSlide(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            'Select Your Neighbourhood Quarter',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NebahColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nebah connects you directly to your local traditional leader (Mai Anguwa) and local security team for fast emergency dispatches.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? NebahColors.slateGrey : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ..._neighbourhoodOptions.map((opt) {
            final isSelected = _selectedCommunityId == opt['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCommunityId = opt['id']!;
                  _selectedCommunityName = opt['name']!;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? NebahColors.cobaltBlue.withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? NebahColors.cobaltBlue
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? NebahColors.cobaltBlue
                            : (isDark ? Colors.white10 : Colors.grey.shade200),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.home_work_outlined,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['name']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : NebahColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt['district']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? NebahColors.slateGrey : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: NebahColors.cobaltBlue,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Slide 3: Emergency Contacts Setup
  Widget _buildEmergencyContactsSlide(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            'Emergency Contacts & SOS Setup',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NebahColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you trigger Hardware Panic or In-App SOS, your live location and emergency card will automatically be sent to this trusted contact.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? NebahColors.slateGrey : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Primary Emergency Contact Name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? NebahColors.slateGrey : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _contactNameController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. Alhaji Danladi (Father)',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              prefixIcon: const Icon(Icons.person_outline, color: NebahColors.cobaltBlue),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Phone Number (SMS Enabled)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? NebahColors.slateGrey : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _contactPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. +234 803 123 4567',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              prefixIcon: const Icon(Icons.phone_outlined, color: NebahColors.cobaltBlue),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NebahColors.crimsonRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: NebahColors.crimsonRed.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_outlined, color: NebahColors.crimsonRed, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Outside Android SOS: You can trigger silent panic anytime by triple-clicking your Volume Button.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
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

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NebahColors.deepNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? NebahColors.slateGrey : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _finishOnboarding() async {
    await OnboardingService.saveUserCommunity(_selectedCommunityId, _selectedCommunityName);
    await OnboardingService.setOnboardingCompleted(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }
}
