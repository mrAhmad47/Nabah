import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Register and persist device Push Notification (FCM) token into Supabase profiles
  Future<void> saveDeviceToken(String fcmToken) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      debugPrint('📲 Persisting FCM Token to Supabase profile: $fcmToken');
      await _supabase.from('profiles').update({
        'fcm_token': fcmToken,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('⚠️ Error persisting FCM token to Supabase: $e');
    }
  }

  /// Trigger local alert notification payload
  void handleIncomingPayload(Map<String, dynamic> payload) {
    final String type = payload['type'] ?? 'info';
    final String title = payload['title'] ?? 'Emergency Notification';
    final String body = payload['body'] ?? 'New alert received from Nebah Platform.';

    debugPrint('🔔 RECEIVED INCOMING PUSH NOTIFICATION [$type]: $title — $body');
  }
}
