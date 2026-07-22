import 'package:flutter/material.dart';
import '../../../core/theme/nebah_colors.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../screens/main_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.darkBackground : NebahColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Brand & Icon
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? NebahColors.darkPrimary.withValues(alpha: 0.15) : NebahColors.lightPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? NebahColors.darkPrimary : NebahColors.lightPrimary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 54,
                      color: isDark ? NebahColors.darkPrimary : NebahColors.lightPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'NEBAH',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: isDark ? NebahColors.darkTextPrimary : NebahColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-Powered Community Safety Ecosystem',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? NebahColors.darkTextSecondary : NebahColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),

              // Feature Highlights
              Column(
                children: [
                  _buildFeatureRow(
                    icon: Icons.sos,
                    title: 'Dual-Mode SOS Response',
                    subtitle: 'Instant silent panic button & categorised in-app SOS',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureRow(
                    icon: Icons.groups_outlined,
                    title: 'Traditional Community Network',
                    subtitle: 'Connected from Mai Anguwa quarters to state level',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureRow(
                    icon: Icons.psychology_outlined,
                    title: 'AI Risk Intelligence',
                    subtitle: 'Real-time hazard prediction & safe travel routing',
                    isDark: isDark,
                  ),
                ],
              ),

              // Action Button
              ElevatedButton(
                onPressed: () async {
                  await OnboardingService().markOnboardingCompleted();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? NebahColors.darkPrimary : NebahColors.lightPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? NebahColors.darkSurface : NebahColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDark ? NebahColors.darkPrimary : NebahColors.lightPrimary,
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? NebahColors.darkTextPrimary : NebahColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? NebahColors.darkTextSecondary : NebahColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
