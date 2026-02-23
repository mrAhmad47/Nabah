import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong2;

/// Reverse Geocoding Service
/// 
/// Identifies towns and cities along a route using coordinates
/// Uses Nominatim (OpenStreetMap) - FREE, no API key required!
class ReverseGeocodingService {
  static final ReverseGeocodingService instance = ReverseGeocodingService._init();
  
  ReverseGeocodingService._init();
  
  // Cache to avoid repeated API calls for same coordinates
  final Map<String, String?> _cache = {};
  
  /// Get city/town name from coordinates
  Future<String?> getCityFromCoordinates(latlong2.LatLng point) async {
    final cacheKey = '${point.latitude.toStringAsFixed(2)},${point.longitude.toStringAsFixed(2)}';
    
    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }
    
    try {
      // Use Nominatim reverse geocoding (OpenStreetMap - FREE!)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'lat=${point.latitude}&lon=${point.longitude}&'
        'format=json&addressdetails=1&zoom=10'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'RouteGuardian/1.0 (Safety Navigation App)',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        
        // Try to get city/town name in order of preference
        String? cityName = address['city'] ?? 
                         address['town'] ?? 
                         address['village'] ?? 
                         address['hamlet'] ??
                         address['suburb'] ??
                         address['county'] ??
                         address['state_district'];
        
        if (cityName != null && cityName.isNotEmpty) {
          _cache[cacheKey] = cityName;
          debugPrint('📍 Found city at ${point.latitude.toStringAsFixed(2)}: $cityName');
          return cityName;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Reverse geocoding error: $e');
    }
    
    _cache[cacheKey] = null;
    return null;
  }
  
  /// Extract intermediate towns/cities along a route
  /// 
  /// Smart sampling: checks every ~20-30km to find intermediate towns
  Future<List<String>> extractTownsFromRoute({
    required List<latlong2.LatLng> routePoints,
    required String origin,
    required String destination,
    int maxTowns = 5, // Limit to prevent excessive API calls
  }) async {
    if (routePoints.isEmpty) {
      return [origin, destination];
    }
    
    final towns = <String>[];
    final seenTowns = <String>{};
    
    // Always add origin
    final originClean = _cleanCityName(origin);
    towns.add(originClean);
    seenTowns.add(originClean.toLowerCase());
    
    // Calculate route length to determine sampling frequency
    final distance = latlong2.Distance();
    double totalDistanceKm = 0;
    
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistanceKm += distance.as(
        latlong2.LengthUnit.Kilometer,
        routePoints[i],
        routePoints[i + 1],
      );
    }
    
    // Sample points along the route based on maxTowns
    // +2 for origin and destination
    final sampleInterval = (routePoints.length / (maxTowns + 2)).ceil().clamp(3, 100);
    
    debugPrint('🗺️ Extracting towns from ${routePoints.length} route points (${totalDistanceKm.toStringAsFixed(0)}km)');
    debugPrint('📏 Sampling every ${sampleInterval} points (max $maxTowns towns)...');
    
    // Sample points at regular intervals
    for (int i = sampleInterval; i < routePoints.length - sampleInterval; i += sampleInterval) {
      // Limit total towns extracted
      if (towns.length >= maxTowns) {
        debugPrint('📌 Reached max towns limit ($maxTowns)');
        break;
      }
      
      final cityName = await getCityFromCoordinates(routePoints[i]);
      
      if (cityName != null && cityName.isNotEmpty) {
        final cleanName = _cleanCityName(cityName);
        final lowerName = cleanName.toLowerCase();
        
        // Only add if not already seen
        if (!seenTowns.contains(lowerName)) {
          towns.add(cleanName);
          seenTowns.add(lowerName);
          debugPrint('  ✅ Added: $cleanName');
        }
      }
      
      // Respect Nominatim rate limit (1 request/second)
      await Future.delayed(const Duration(milliseconds: 1100));
    }
    
    // Always add destination
    final destClean = _cleanCityName(destination);
    if (!seenTowns.contains(destClean.toLowerCase())) {
      towns.add(destClean);
    }
    
    debugPrint('🎯 Final extracted towns (${towns.length}): ${towns.join(" → ")}');
    return towns;
  }
  
  /// Clean city names for better news search
  String _cleanCityName(String name) {
    return name
        .replaceAll(', Nigeria', '')
        .replaceAll(' State', '')
        .replaceAll(' LGA', '')
        .trim();
  }
  
  /// Clear the geocoding cache
  void clearCache() {
    _cache.clear();
    debugPrint('🗑️ Geocoding cache cleared');
  }
}
