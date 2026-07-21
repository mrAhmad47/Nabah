import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'geocoding_service.dart';

/// Service for handling geolocation and reverse geocoding
class GeolocationService {
  final GeocodingService _geocodingService = GeocodingService.instance;

  /// Get the current GPS location
  Future<latlong2.LatLng?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied');
        return null;
      }

      // Get current position
      debugPrint('📍 Getting current GPS location...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('✅ Got location: ${position.latitude}, ${position.longitude}');
      return latlong2.LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  /// Request location permissions
  Future<bool> requestPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Get address/city name from coordinates — delegates to GeocodingService
  Future<String> getAddressFromCoordinates(latlong2.LatLng location) async {
    try {
      final address = await _geocodingService.reverseGeocode(location);
      if (address != null) {
        // Shorten if too long
        if (address.length > 50) {
          return '${address.substring(0, 47)}...';
        }
        return address;
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
    // Fallback to coordinates
    return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  /// Default fallback location (Lagos, Nigeria)
  static const latlong2.LatLng defaultLocation = latlong2.LatLng(6.5244, 3.3792);
}

