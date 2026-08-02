import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Get current user profile or fallback
  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.id,
      phone: user.phone,
      email: user.email,
      fullName: user.userMetadata?['full_name'],
      role: UserRole.citizen,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  /// Listen to authentication changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with Phone (Sends OTP)
  Future<void> signInWithPhone(String phone) async {
    debugPrint('📱 Sending Phone OTP to: $phone');
    await _supabase.auth.signInWithOtp(
      phone: phone,
    );
  }

  /// Verify Phone OTP
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String token,
  }) async {
    debugPrint('🔑 Verifying OTP token for: $phone');
    final response = await _supabase.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );

    if (response.user != null) {
      await _supabase.from('profiles').upsert({
        'id': response.user!.id,
        'phone_number': phone,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  /// Sign in with Email & Password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with Email & Password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'full_name': displayName} : null,
    );
    if (response.user != null) {
      await _supabase.from('profiles').upsert({
        'id': response.user!.id,
        'email': email,
        'full_name': displayName,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    return response;
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Format auth error messages
  String getErrorMessage(dynamic e) {
    if (e is AuthException) {
      return e.message;
    }
    return e.toString();
  }

  /// Sign out current user
  Future<void> signOut() async {
    debugPrint('🚪 Signing out from Supabase Auth');
    await _supabase.auth.signOut();
  }

  /// Fetch user profile from Supabase profiles table
  Future<AppUser?> fetchUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return AppUser.fromJson(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching user profile: $e');
    }

    return currentUser;
  }
}
