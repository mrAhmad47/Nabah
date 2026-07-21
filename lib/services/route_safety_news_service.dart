import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'reverse_geocoding_service.dart';
import 'directions_service.dart';

/// Route Safety News Service
/// 
/// Uses N-ATLaS Python server to:
/// 1. Scrape REAL news from Google News (no API key needed)
/// 2. Analyze headlines with AI for safety relevance
/// 3. Return time-based severity scores
class RouteSafetyNewsService {
  static final RouteSafetyNewsService instance = RouteSafetyNewsService._init();
  
  static String get _serverUrl => ApiConfig.natlasServerUrl;
  
  final _geocodingService = ReverseGeocodingService.instance;
  
  RouteSafetyNewsService._init();

  /// Main analysis - Extracts up to 5 intermediate towns for comprehensive coverage
  Future<RouteSafetyAnalysis> analyzeRouteSafety({
    required RouteResult route,
  }) async {
    // Extract intermediate towns (limited to 5 to prevent slow performance)
    List<String> locations;
    
    try {
      final extractedTowns = await _geocodingService.extractTownsFromRoute(
        routePoints: route.routePoints,
        origin: route.originAddress,
        destination: route.destinationAddress,
        maxTowns: 5, // Limit to 5 intermediate locations
      );
      
      locations = extractedTowns.map((town) => _cleanCityName(town)).toList();
      debugPrint('🔍 Analyzing safety for ${locations.length} locations: ${locations.join(" → ")}');
    } catch (e) {
      // Fallback to origin/destination if geocoding fails
      debugPrint('⚠️ Geocoding failed: $e - using origin/destination only');
      locations = [
        _cleanCityName(route.originAddress),
        _cleanCityName(route.destinationAddress),
      ];
    }
    
    // Try N-ATLaS server for real news search
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/search_news'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'locations': locations}),
      ).timeout(const Duration(seconds: 20)); // Increased to allow NewsAPI + AI analysis time
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        debugPrint('📰 N-ATLaS found news! Safety Score: ${data['safety_score']}');
        
        // Convert server response to warnings
        final warnings = <SafetyWarning>[];
        
        for (final report in (data['location_reports'] ?? [])) {
          if (report['has_danger'] == true) {
            final headlines = report['headlines'] as List? ?? [];
            
            warnings.add(SafetyWarning(
              type: _getWarningType(report['danger_type'] ?? 'crime'),
              location: report['location'] ?? 'Unknown',
              description: headlines.isNotEmpty 
                  ? headlines.first.toString()
                  : report['ai_summary'] ?? 'Security concern detected',
              source: 'N-ATLaS AI',
              date: DateTime.now(),
              severityImpact: (report['severity'] as num?)?.toInt() ?? 20,
              recencyLabel: 'Live',
            ));
          }
        }
        
        final safetyScore = (data['safety_score'] as num?)?.toInt() ?? 85;
        
        // Adjust for route index
        int adjustedScore = safetyScore;
        if (route.routeIndex == 2 && warnings.isEmpty) {
          adjustedScore += 3;
        }
        adjustedScore = adjustedScore.clamp(10, 95);
        
        return RouteSafetyAnalysis(
          safetyScore: adjustedScore,
          safetyLevel: _getSafetyLevel(adjustedScore),
          warnings: warnings,
          analyzedLocations: locations,
          analysisTime: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ N-ATLaS server error: $e');
      if (e.toString().contains('TimeoutException')) {
        debugPrint('   Timeout after 5 seconds - using fallback analysis...');
      } else {
        debugPrint('   Network error - using fallback analysis...');
      }
    }
    
    // Fallback if server unavailable
    return _getFallbackAnalysis(locations, route.routeIndex);
  }

  WarningType _getWarningType(String dangerType) {
    switch (dangerType.toLowerCase()) {
      case 'kidnapping': return WarningType.kidnapping;
      case 'crime': return WarningType.crime;
      case 'accident': return WarningType.accident;
      case 'road': return WarningType.badRoad;
      case 'weather': return WarningType.weather;
      default: return WarningType.crime;
    }
  }

  RouteSafetyAnalysis _getFallbackAnalysis(List<String> locations, int routeIndex) {
    // Simulated fallback for when N-ATLaS server is not running
    final warnings = <SafetyWarning>[];
    int safetyScore = 85;
    
    for (final loc in locations) {
      final lower = loc.toLowerCase();
      
      if (lower.contains('kaduna') && routeIndex == 0) {
        warnings.add(SafetyWarning(
          type: WarningType.crime,
          location: loc,
          description: 'Security forces active on Kaduna highways (3d ago)',
          source: 'Demo Data',
          date: DateTime.now().subtract(const Duration(days: 3)),
          severityImpact: 12,
          recencyLabel: '3d ago',
        ));
        safetyScore -= 12;
      }
      
      if (lower.contains('zamfara')) {
        warnings.add(SafetyWarning(
          type: WarningType.kidnapping,
          location: loc,
          description: 'Travel advisory: Avoid Zamfara state (2d ago)',
          source: 'Demo Data',
          date: DateTime.now().subtract(const Duration(days: 2)),
          severityImpact: 20,
          recencyLabel: '2d ago',
        ));
        safetyScore -= 20;
      }
      
      if (lower.contains('lagos') || lower.contains('ibadan')) {
        warnings.add(SafetyWarning(
          type: WarningType.traffic,
          location: loc,
          description: 'Heavy traffic on Lagos-Ibadan expressway (12h ago)',
          source: 'Demo Data',
          date: DateTime.now().subtract(const Duration(hours: 12)),
          severityImpact: 5,
          recencyLabel: '12h ago',
        ));
        safetyScore -= 5;
      }
    }
    
    if (routeIndex == 2) safetyScore += 3;
    safetyScore = safetyScore.clamp(10, 95);
    
    return RouteSafetyAnalysis(
      safetyScore: safetyScore,
      safetyLevel: _getSafetyLevel(safetyScore),
      warnings: warnings,
      analyzedLocations: locations,
      analysisTime: DateTime.now(),
    );
  }

  String _getSafetyLevel(int score) {
    if (score >= 85) return 'VERY SAFE';
    if (score >= 70) return 'MOSTLY SAFE';
    if (score >= 50) return 'MODERATE RISK';
    if (score >= 30) return 'HIGH RISK';
    return 'DANGER ZONE';
  }

  String _cleanCityName(String address) {
    // Extract city name from full address
    // e.g., "Bauchi, Nigeria" -> "Bauchi"
    return address
        .split(',')
        .first
        .replaceAll(' State', '')
        .replaceAll(' LGA', '')
        .trim();
  }
}

// === Data Models ===

enum WarningType { crime, kidnapping, badRoad, weather, traffic, accident }

extension WarningTypeExtension on WarningType {
  String get displayName {
    switch (this) {
      case WarningType.crime: return 'Security Alert';
      case WarningType.kidnapping: return 'Kidnapping Risk';
      case WarningType.badRoad: return 'Road Condition';
      case WarningType.weather: return 'Weather Warning';
      case WarningType.traffic: return 'Traffic Alert';
      case WarningType.accident: return 'Accident Report';
    }
  }
  
  String get icon {
    switch (this) {
      case WarningType.crime: return '🚨';
      case WarningType.kidnapping: return '⚠️';
      case WarningType.badRoad: return '🚧';
      case WarningType.weather: return '🌧️';
      case WarningType.traffic: return '🚗';
      case WarningType.accident: return '💥';
    }
  }
}

class SafetyWarning {
  final WarningType type;
  final String location;
  final String description;
  final String source;
  final DateTime date;
  final int severityImpact;
  final String recencyLabel;

  SafetyWarning({
    required this.type,
    required this.location,
    required this.description,
    required this.source,
    required this.date,
    required this.severityImpact,
    this.recencyLabel = '',
  });
}

class RouteSafetyAnalysis {
  final int safetyScore;
  final String safetyLevel;
  final List<SafetyWarning> warnings;
  final List<String> analyzedLocations;
  final DateTime analysisTime;

  RouteSafetyAnalysis({
    required this.safetyScore,
    required this.safetyLevel,
    required this.warnings,
    required this.analyzedLocations,
    required this.analysisTime,
  });
  
  bool get hasCrimeWarnings => warnings.any((w) => 
    w.type == WarningType.crime || w.type == WarningType.kidnapping);
}
