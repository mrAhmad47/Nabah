import 'dart:convert';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/api_config.dart';
import '../models/sos_event.dart';

class SosService {
  final Battery _battery = Battery();
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Read actual device battery level
  Future<int> _getRealBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      debugPrint('⚠️ Error reading device battery level: $e');
      return 100;
    }
  }

  /// Trigger Hardware Stealth Panic SOS (Outside Panic: Volume button triple-click / hold)
  Future<SosEvent> triggerHardwarePanic({
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    debugPrint('🚨 SOS DISPATCH TRIGGERED: HARDWARE STEALTH PANIC!');
    
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
    final int battery = await _getRealBatteryLevel();

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
      batteryLevel: battery,
      speed: pos?.speed ?? 0.0,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      timestamp: DateTime.now(),
      status: SosStatus.dispatched,
    );

    // Save to Supabase Cloud & Python Server
    await dispatchSosEvent(event);
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
    final int battery = await _getRealBatteryLevel();

    final event = SosEvent(
      id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
      mode: SosMode.interactiveCategorized,
      category: category,
      targets: targets,
      latitude: lat,
      longitude: lng,
      address: 'Near User Current Location ($lat, $lng)',
      batteryLevel: battery,
      speed: pos?.speed ?? 0.0,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      timestamp: DateTime.now(),
      status: SosStatus.dispatched,
    );

    await dispatchSosEvent(event);
    return event;
  }

  /// Dispatch SOS payload to Supabase & Python Backend
  Future<void> dispatchSosEvent(SosEvent event) async {
    // 1. Insert into Supabase cloud DB
    try {
      await _supabase.from('sos_events').upsert({
        'id': event.id,
        'user_id': event.userId.isNotEmpty ? event.userId : null,
        'mode': event.mode.name,
        'category': event.category.name,
        'address': event.address,
        'battery_level': event.batteryLevel,
        'targets': event.targets.toJson(),
        'status': event.status.name,
        'created_at': event.timestamp.toIso8601String(),
      });
      debugPrint('⚡ SOS successfully saved to Supabase cloud!');

      // Insert initial live GPS point
      await _supabase.from('sos_location_stream').upsert({
        'sos_id': event.id,
        'lat': event.latitude,
        'lng': event.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ Supabase SOS dispatch error: $e');
    }

    // 2. Dispatch to Python FastAPI backend (for SMS/WhatsApp alerts)
    try {
      final backendUrl = ApiConfig.nebahApiBaseUrl;
      await http.post(
        Uri.parse('$backendUrl/api/v1/emergency/sos/panic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(event.toJson()),
      );
    } catch (e) {
      debugPrint('⚠️ Backend Python SOS dispatch warning: $e');
    }
  }

  /// Direct Emergency Phone Call Dialer
  Future<void> makeEmergencyCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch phone dialer for $phoneNumber');
    }
  }
}
