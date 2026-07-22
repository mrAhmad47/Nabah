import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _kOnboardingCompletedKey = 'nebah_onboarding_completed_v1';
  static const String _kSelectedCommunityKey = 'nebah_user_community_id';
  static const String _kSelectedCommunityNameKey = 'nebah_user_community_name';

  /// Check if the user has already completed onboarding
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingCompletedKey) ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompletedKey, value);
  }

  /// Save selected community quarter/sub-neighbourhood (Mai Anguwa level)
  static Future<void> saveUserCommunity(String communityId, String communityName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedCommunityKey, communityId);
    await prefs.setString(_kSelectedCommunityNameKey, communityName);
  }

  /// Get stored community ID
  static Future<String?> getUserCommunityId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSelectedCommunityKey) ?? 'mai_anguwa_gwallameji_01';
  }

  /// Get stored community Name
  static Future<String> getUserCommunityName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSelectedCommunityNameKey) ?? 'Sarkin Yama Quarter (Mai Anguwa)';
  }
}
