import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_event.dart';

class SosService {
  final String baseUrl;

  SosService({this.baseUrl = 'http://10.0.2.2:8000'});

  /// Trigger Hardware Stealth Panic SOS (Outside Panic: Volume button triple-click / hold)
  /// Dispatches immediately without user screen intervention
  Future<SosEvent> triggerHardwarePanic({
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    debugPrint('🚨 SOS DISPATCH TRIGGERED: HARDWARE STEALTH PANIC!');
    
    // Obtain live coordinates
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('⚠️ Geolocator position error on panic, using fallback: $e');
    }

    final double lat = pos?.latitude ?? 10.3158;
    final double lng = pos?.longitude ?? 9.8442;

    final event = SosEvent(
      id: 'panic_${DateTime.now().millisecondsSinceEpoch}',
      mode: SosMode.hardwarePanic,
      category: EmergencyCategory.intruder,
      targets: const SosTargetChannels(
        notifyVigilante: true,
        notifyPolice: true,
        notifyEmergencyContacts: true,
        notifyFireService: false,
        notifyAmbulance: false,
      ),
      latitude: lat,
      longitude: lng,
      address: 'Current Live GPS Location ($lat, $lng)',
      batteryLevel: 88,
      speed: pos?.speed ?? 0.0,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      timestamp: DateTime.now(),
      status: SosStatus.dispatched,
    );

    // Send payload to backend
    await _sendSosToBackend('/api/v1/emergency/sos/panic', event);
    return event;
  }

  /// Trigger Interactive Categorized In-App SOS
  Future<SosEvent> triggerCategorizedSos({
    required EmergencyCategory category,
    required SosTargetChannels targets,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    debugPrint('🚨 SOS DISPATCH TRIGGERED: IN-APP CATEGORIZED SOS (${category.title})');

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('⚠️ Geolocator position error: $e');
    }

    final double lat = pos?.latitude ?? 10.3158;
    final double lng = pos?.longitude ?? 9.8442;

    final event = SosEvent(
      id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
      mode: SosMode.interactiveCategorized,
      category: category,
      targets: targets,
      latitude: lat,
      longitude: lng,
      address: 'Near User Current Location ($lat, $lng)',
      batteryLevel: 92,
      speed: pos?.speed ?? 0.0,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      timestamp: DateTime.now(),
      status: SosStatus.dispatched,
    );

    await _sendSosToBackend('/api/v1/emergency/sos/categorized', event);
    return event;
  }

  /// Quick Phone Call to Nigerian Police / Emergency Control Room
  Future<void> makeEmergencyCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch phone dialer for $phoneNumber');
    }
  }

  /// Send SOS payload to backend API endpoint
  Future<void> _sendSosToBackend(String path, SosEvent event) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(event.toJson()),
      );
      debugPrint('📡 Backend SOS Response: ${response.statusCode}');
    } catch (e) {
      debugPrint('⚠️ Network failure sending SOS to backend server: $e');
    }
  }
}
