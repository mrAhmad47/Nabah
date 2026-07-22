import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding Service for managing first-time launch state.
/// 
/// Ensures onboarding runs ONLY on initial app install.
class OnboardingService {
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding_v3';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Check if the user has completed onboarding before
  Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool? fromPrefs = prefs.getBool(_keyHasCompletedOnboarding);
      if (fromPrefs == true) return true;

      // Fallback check secure storage
      final String? fromSecure = await _secureStorage.read(key: _keyHasCompletedOnboarding);
      return fromSecure == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Mark onboarding as completed so returning users bypass it
  Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasCompletedOnboarding, true);
      await _secureStorage.write(key: _keyHasCompletedOnboarding, value: 'true');
    } catch (e) {
      // Ignored if non-fatal
    }
  }

  /// Reset onboarding state (for testing/debug)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHasCompletedOnboarding);
    await _secureStorage.delete(key: _keyHasCompletedOnboarding);
  }
}
