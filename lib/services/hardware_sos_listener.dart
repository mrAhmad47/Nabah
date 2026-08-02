import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:volume_controller/volume_controller.dart';
import 'sos_service.dart';
import 'auth_service.dart';

class HardwareSosListener {
  static final HardwareSosListener _instance = HardwareSosListener._internal();
  factory HardwareSosListener() => _instance;
  HardwareSosListener._internal();

  final _sosService = SosService();
  final _authService = AuthService();
  
  int _clickCount = 0;
  Timer? _resetTimer;
  bool _isListening = false;

  /// Start listening for volume button triple-clicks (Hardware Stealth Panic)
  void startListening() {
    if (_isListening) return;
    _isListening = true;

    debugPrint('🎧 Hardware Stealth Panic listener active (Volume Triple-Click)');
    VolumeController().listener((volume) {
      _handleVolumeChange();
    });
  }

  void _handleVolumeChange() {
    _clickCount++;
    debugPrint('🔔 Volume click count: $_clickCount');

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      _clickCount = 0;
    });

    if (_clickCount >= 3) {
      _clickCount = 0;
      _resetTimer?.cancel();
      _triggerPanic();
    }
  }

  Future<void> _triggerPanic() async {
    debugPrint('🚨 HARDWARE TRIPLE-CLICK DETECTED! DISPATCHING STEALTH PANIC...');
    final user = _authService.currentUser;
    await _sosService.triggerHardwarePanic(
      userId: user?.id ?? 'stealth_user',
      userName: user?.fullName ?? 'Citizen in Distress',
      userPhone: user?.phone ?? 'Emergency Contact',
    );
  }

  void stopListening() {
    _isListening = false;
    VolumeController().removeListener();
  }
}
