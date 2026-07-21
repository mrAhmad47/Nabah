import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../components/neon_button.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // App Icon/Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonGreen.withValues(alpha: 0.1),
                  border: Border.all(color: AppTheme.neonGreen, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 60,
                  color: AppTheme.neonGreen,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // App Name
              Text(
                'RouteGuardian',
                textAlign: TextAlign.center,
                style: AppTheme.titleStyle.copyWith(
                  fontSize: 32,
                  letterSpacing: 2.0,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Tagline
              Text(
                'AI-Powered Safety Routing\nfor Nigeria & Africa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Feature highlights
              _buildFeature(Icons.route, 'Find the safest routes'),
              const SizedBox(height: 16),
              _buildFeature(Icons.warning_amber, 'Real-time incident alerts'),
              const SizedBox(height: 16),
              _buildFeature(Icons.auto_awesome, 'AI-powered safety analysis'),
              
              const Spacer(),
              
              // Get Started Button
              NeonButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppTheme.neonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.accentBlue, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
