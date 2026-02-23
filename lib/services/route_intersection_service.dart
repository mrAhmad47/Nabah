import 'package:latlong2/latlong.dart' as latlong2;
import 'directions_service.dart';

/// Route Intersection Service
/// 
/// Detects where multiple routes intersect (common towns/cities)
/// and enables dynamic route switching recommendations
class RouteIntersectionService {
  static final RouteIntersectionService instance = RouteIntersectionService._init();
  
  RouteIntersectionService._init();
  
  /// Analyze all routes and find intersection points
  List<RouteIntersection> findIntersections(List<RouteResult> routes) {
    if (routes.length < 2) return [];
    
    final intersections = <RouteIntersection>[];
    
    // Compare each pair of routes
    for (int i = 0; i < routes.length; i++) {
      for (int j = i + 1; j < routes.length; j++) {
        final route1 = routes[i];
        final route2 = routes[j];
        
        // Find common towns between these two routes
        final intersection = _findIntersectionBetweenTwo(route1, route2);
        if (intersection != null) {
          intersections.add(intersection);
        }
      }
    }
    
    return intersections;
  }
  
  /// Find intersection points between two specific routes
  RouteIntersection? _findIntersectionBetweenTwo(RouteResult route1, RouteResult route2) {
    final commonPoints = <IntersectionPoint>[];
    
    // Check each point on route1
    for (int i = 0; i < route1.routePoints.length; i++) {
      final point1 = route1.routePoints[i];
      
      // See if route2 passes near this point (within 500m)
      for (int j = 0; j < route2.routePoints.length; j++) {
        final point2 = route2.routePoints[j];
        
        final distance = _calculateDistance(point1, point2);
        
        // If points are very close (< 500m), they're at the same location
        if (distance < 0.5) { // 500 meters
          // Calculate progress along each route (0 to 1)
          final progress1 = i / route1.routePoints.length;
          final progress2 = j / route2.routePoints.length;
          
          // Calculate actual distance traveled to reach this point
          final distanceOnRoute1 = _calculateDistanceAlongRoute(route1.routePoints, i);
          final distanceOnRoute2 = _calculateDistanceAlongRoute(route2.routePoints, j);
          
          commonPoints.add(IntersectionPoint(
            location: point1,
            route1Index: route1.routeIndex,
            route2Index: route2.routeIndex,
            route1ProgressPercent: (progress1 * 100).round(),
            route2ProgressPercent: (progress2 * 100).round(),
            route1DistanceKm: distanceOnRoute1,
            route2DistanceKm: distanceOnRoute2,
          ));
          
          // Skip ahead to avoid duplicate detections
          break;
        }
      }
    }
    
    if (commonPoints.isEmpty) return null;
    
    // Group nearby intersection points (within 2km) as single intersection
    final clusteredPoints = _clusterIntersectionPoints(commonPoints);
    
    return RouteIntersection(
      route1: route1,
      route2: route2,
      intersectionPoints: clusteredPoints,
    );
  }
  
  /// Cluster intersection points that are close together
  List<IntersectionPoint> _clusterIntersectionPoints(List<IntersectionPoint> points) {
    if (points.isEmpty) return [];
    
    final clustered = <IntersectionPoint>[];
    final used = <bool>[];
    
    for (int i = 0; i < points.length; i++) {
      used.add(false);
    }
    
    for (int i = 0; i < points.length; i++) {
      if (used[i]) continue;
      
      final cluster = <IntersectionPoint>[points[i]];
      used[i] = true;
      
      // Find all nearby points
      for (int j = i + 1; j < points.length; j++) {
        if (used[j]) continue;
        
        final distance = _calculateDistance(points[i].location, points[j].location);
        if (distance < 2.0) { // 2km threshold
          cluster.add(points[j]);
          used[j] = true;
        }
      }
      
      // Use the middle point of the cluster
      if (cluster.isNotEmpty) {
        clustered.add(cluster[cluster.length ~/ 2]);
      }
    }
    
    return clustered;
  }
  
  /// Calculate total distance along a route up to a specific point index
  double _calculateDistanceAlongRoute(List<latlong2.LatLng> points, int endIndex) {
    double totalKm = 0.0;
    
    for (int i = 0; i < endIndex && i < points.length - 1; i++) {
      totalKm += _calculateDistance(points[i], points[i + 1]);
    }
    
    return totalKm;
  }
  
  /// Calculate distance between two points in kilometers
  double _calculateDistance(latlong2.LatLng p1, latlong2.LatLng p2) {
    const distance = latlong2.Distance();
    return distance.as(latlong2.LengthUnit.Kilometer, p1, p2);
  }
  
  /// Get switching recommendation based on current location and route safety
  SwitchRecommendation? getRecommendation({
    required List<RouteResult> allRoutes,
    required RouteResult currentRoute,
    required latlong2.LatLng currentLocation,
    required List<RouteIntersection> intersections,
  }) {
    // Find the nearest intersection point ahead on current route
    IntersectionPoint? nearestIntersection;
    double nearestDistance = double.infinity;
    RouteResult? alternativeRoute;
    
    for (final intersection in intersections) {
      if (intersection.route1.routeIndex != currentRoute.routeIndex &&
          intersection.route2.routeIndex != currentRoute.routeIndex) {
        continue; // This intersection doesn't involve current route
      }
      
      for (final point in intersection.intersectionPoints) {
        final distance = _calculateDistance(currentLocation, point.location);
        
        // Only consider intersections ahead (within 50km)
        if (distance < nearestDistance && distance < 50.0) {
          nearestDistance = distance;
          nearestIntersection = point;
          
          // Determine which route is the alternative
          alternativeRoute = intersection.route1.routeIndex == currentRoute.routeIndex
              ? intersection.route2
              : intersection.route1;
        }
      }
    }
    
    if (nearestIntersection == null || alternativeRoute == null) {
      return null; // No nearby intersections
    }
    
    // Check if alternative route is safer
    if (alternativeRoute.safetyScore > currentRoute.safetyScore + 5) {
      return SwitchRecommendation(
        currentRoute: currentRoute,
        recommendedRoute: alternativeRoute,
        switchPoint: nearestIntersection,
        distanceToSwitchKm: nearestDistance,
        safetyImprovement: alternativeRoute.safetyScore - currentRoute.safetyScore,
        reason: _generateRecommendationReason(currentRoute, alternativeRoute),
      );
    }
    
    return null;
  }
  
  String _generateRecommendationReason(RouteResult current, RouteResult alternative) {
    final scoreDiff = alternative.safetyScore - current.safetyScore;
    
    if (scoreDiff > 20) {
      return 'Much safer route available! +${scoreDiff}% safety improvement.';
    } else if (scoreDiff > 10) {
      return 'Safer alternative detected. +${scoreDiff}% safety improvement.';
    } else {
      return 'Slightly safer option available. +${scoreDiff}% improvement.';
    }
  }
}

/// Represents an intersection between two routes
class RouteIntersection {
  final RouteResult route1;
  final RouteResult route2;
  final List<IntersectionPoint> intersectionPoints;
  
  RouteIntersection({
    required this.route1,
    required this.route2,
    required this.intersectionPoints,
  });
  
  String get description {
    final count = intersectionPoints.length;
    return 'Routes ${route1.routeName} and ${route2.routeName} intersect at $count point${count > 1 ? 's' : ''}';
  }
}

/// Represents a specific point where routes intersect
class IntersectionPoint {
  final latlong2.LatLng location;
  final int route1Index;
  final int route2Index;
  final int route1ProgressPercent;
  final int route2ProgressPercent;
  final double route1DistanceKm;
  final double route2DistanceKm;
  
  IntersectionPoint({
    required this.location,
    required this.route1Index,
    required this.route2Index,
    required this.route1ProgressPercent,
    required this.route2ProgressPercent,
    required this.route1DistanceKm,
    required this.route2DistanceKm,
  });
  
  String getProgressDescription(int forRouteIndex) {
    if (forRouteIndex == route1Index) {
      return '${route1ProgressPercent}% along route (${route1DistanceKm.toStringAsFixed(0)}km)';
    } else {
      return '${route2ProgressPercent}% along route (${route2DistanceKm.toStringAsFixed(0)}km)';
    }
  }
}

/// Recommendation to switch routes
class SwitchRecommendation {
  final RouteResult currentRoute;
  final RouteResult recommendedRoute;
  final IntersectionPoint switchPoint;
  final double distanceToSwitchKm;
  final int safetyImprovement;
  final String reason;
  
  SwitchRecommendation({
    required this.currentRoute,
    required this.recommendedRoute,
    required this.switchPoint,
    required this.distanceToSwitchKm,
    required this.safetyImprovement,
    required this.reason,
  });
  
  String get summaryText {
    return 'Switch to ${recommendedRoute.routeName} in ${distanceToSwitchKm.toStringAsFixed(1)}km for +${safetyImprovement}% safety';
  }
}
