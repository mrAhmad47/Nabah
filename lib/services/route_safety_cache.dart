
/// Simple in-memory cache for route safety data
/// Helps reduce backend load and improve speed
class RouteSafetyCache {
  static final RouteSafetyCache instance = RouteSafetyCache._init();
  
  RouteSafetyCache._init();
  
  final Map<String, CachedSafetyData> _cache = {};
  
  /// Cache duration: 30 minutes (balance between freshness and performance)
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  /// Generate cache key from route
  String _getCacheKey(String origin, String destination) {
    // Normalize: lowercase, trim, remove "Nigeria"
    final cleanOrigin = origin.toLowerCase().trim().replaceAll(', nigeria', '');
    final cleanDest = destination.toLowerCase().trim().replaceAll(', nigeria', '');
    return '$cleanOrigin|$cleanDest';
  }
  
  /// Check if cached data exists and is still valid
  bool has(String origin, String destination) {
    final key = _getCacheKey(origin, destination);
    final cached = _cache[key];
    
    if (cached == null) return false;
    
    // Check if expired
    final age = DateTime.now().difference(cached.timestamp);
    if (age > _cacheDuration) {
      _cache.remove(key); // Clean up expired
      return false;
    }
    
    return true;
  }
  
  /// Get cached safety data
  CachedSafetyData? get(String origin, String destination) {
    if (!has(origin, destination)) return null;
    
    final key = _getCacheKey(origin, destination);
    return _cache[key];
  }
  
  /// Store safety data in cache
  void set(String origin, String destination, Map<String, dynamic> safetyData) {
    final key = _getCacheKey(origin, destination);
    _cache[key] = CachedSafetyData(
      safetyScore: safetyData['safetyScore'] as int,
      safetyLevel: safetyData['safetyLevel'] as String,
      warnings: safetyData['warnings'] as List<String>,
      timestamp: DateTime.now(),
    );
  }
  
  /// Clear all cache (useful for refresh)
  void clear() {
    _cache.clear();
  }
  
  /// Get cache stats (for debugging)
  Map<String, dynamic> getStats() {
    int validEntries = 0;
    int expiredEntries = 0;
    
    for (final entry in _cache.entries) {
      final age = DateTime.now().difference(entry.value.timestamp);
      if (age > _cacheDuration) {
        expiredEntries++;
      } else {
        validEntries++;
      }
    }
    
    return {
      'total': _cache.length,
      'valid': validEntries,
      'expired': expiredEntries,
      'cacheDurationMinutes': _cacheDuration.inMinutes,
    };
  }
}

/// Cached safety data with timestamp
class CachedSafetyData {
  final int safetyScore;
  final String safetyLevel;
  final List<String> warnings;
  final DateTime timestamp;
  
  CachedSafetyData({
    required this.safetyScore,
    required this.safetyLevel,
    required this.warnings,
    required this.timestamp,
  });
  
  /// How old is this cached data?
  Duration get age => DateTime.now().difference(timestamp);
  
  /// Human-readable age
  String get ageDescription {
    final minutes = age.inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes == 1) return '1 minute ago';
    if (minutes < 60) return '$minutes minutes ago';
    return '${age.inHours} hours ago';
  }
}
