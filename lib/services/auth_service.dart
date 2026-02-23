import 'package:flutter/foundation.dart';

/// Mock Auth Service for testing without backend
/// 
/// This bypasses authentication completely.
/// Replace this with real API calls when backend is ready.
class AuthService {
  // Mock current user
  AppUser? get currentUser => AppUser(
    id: 'test-user-123',
    email: 'test@routeguardian.com',
    displayName: 'Test User',
    phoneNumber: null,
    emailVerified: true,
    createdAt: DateTime.now(),
    lastLoginAt: DateTime.now(),
  );
  
  // Mock auth state - always authenticated
  Stream<AppUser?> get authStateChanges => Stream.value(currentUser);
  
  // Mock sign in - always succeeds
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('✅ Mock sign in: $email');
    return currentUser;
  }
  
  // Mock sign up - always succeeds
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('✅ Mock sign up: $email');
    return currentUser;
  }
  
  // Mock sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('✅ Mock sign out');
  }
  
  // Mock password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('✅ Mock password reset email sent to: $email');
  }
  
  // Mock error messages
  String getErrorMessage(dynamic e) {
    return 'Mock error: ${e.toString()}';
  }
}

/// Mock User Model
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    required this.emailVerified,
    required this.createdAt,
    this.lastLoginAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
  
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      phoneNumber: json['phoneNumber'],
      emailVerified: json['emailVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
    );
  }
}
