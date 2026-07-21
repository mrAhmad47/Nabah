import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;

import '../components/platform_aware_map.dart';
import '../theme/theme.dart';
import '../components/neon_button.dart';
import '../services/incident_database.dart';
import '../services/directions_service.dart';
import '../services/route_safety_news_service.dart';
import '../services/route_intersection_service.dart';
import '../services/route_safety_cache.dart';
import '../models/incident_report.dart';

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final IncidentDatabase _incidentDb = IncidentDatabase.instance;
  final DirectionsService _directionsService = DirectionsService.instance;
  final RouteIntersectionService _intersectionService = RouteIntersectionService.instance;

  // State
  List<RouteResult> _routes = [];
  int _selectedRouteIndex = 0;
  List<IncidentReport> _routeIncidents = [];
  bool _isCalculating = false;
  bool _routeCalculated = false;
  bool _isInputExpanded = true; // Toggle for input panel
  bool _isAnalyzingRoutes = false;
  
  // Intersection state
  List<RouteIntersection> _intersections = [];

  // Map state
  latlong2.LatLng _mapCenter = const latlong2.LatLng(9.0820, 8.6753); // Nigeria center
  double _mapZoom = 6.0;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _calculateRoutes() async {
    final fromText = _fromController.text.trim();
    final toText = _toController.text.trim();

    if (fromText.isEmpty || toText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both origin and destination')),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _routes = [];
      _routeCalculated = false;
    });

    try {
      // Fetch multiple routes from Google Directions API (works globally)
      final routes = await _directionsService.getMultipleRoutes(
        origin: fromText,
        destination: toText,
      );

      if (routes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find routes. Try different locations.')),
        );
        setState(() => _isCalculating = false);
        return;
      }

      setState(() {
        _routes = routes;
        _selectedRouteIndex = 0;
        _routeCalculated = true;
        _isCalculating = false;
        _isInputExpanded = false; // Collapse input after route found
      });

      // Update map center
      if (routes.first.routePoints.isNotEmpty) {
        final points = routes.first.routePoints;
        _mapCenter = latlong2.LatLng(
          (points.first.latitude + points.last.latitude) / 2,
          (points.first.longitude + points.last.longitude) / 2,
        );
        _mapZoom = _calculateZoomLevel(routes.first);
      }

      // Analyze safety for all routes
      await _analyzeRouteSafety();
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCalculating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  double _calculateZoomLevel(RouteResult route) {
    final km = route.distanceKm;
    if (km > 500) return 6.0;
    if (km > 200) return 7.0;
    if (km > 100) return 8.0;
    if (km > 50) return 9.0;
    return 10.0;
  }

  Future<void> _analyzeRouteSafety() async {
    setState(() => _isAnalyzingRoutes = true);

    final newsService = RouteSafetyNewsService.instance;
    final cache = RouteSafetyCache.instance;
    final fromText = _fromController.text.trim();
    final toText = _toController.text.trim();

    for (int i = 0; i < _routes.length; i++) {
      final route = _routes[i];
      
      // 1. Check cache first!
      final cached = cache.get(fromText, toText);
      if (cached != null) {
        debugPrint('✅ Using CACHED safety data (${cached.ageDescription})');
        
        setState(() {
          _routes[i].safetyScore = cached.safetyScore;
          _routes[i].safetyLevel = cached.safetyLevel;
          _routes[i].safetyWarnings = cached.warnings;
          _routes[i].routeColor = _routes[i].getSafetyColor();
        });
        continue; // Skip API call!
      }
      
      // 2. Find user-reported incidents along this route
      final incidents = await _findIncidentsAlongRoute(route);
      
      // 3. AI News Search - analyze news for locations
      debugPrint('🔍 AI analyzing news for route ${i + 1}...');
      final newsAnalysis = await newsService.analyzeRouteSafety(
        route: route,
      );
      
      // 4. Combine all safety data
      int safetyScore = newsAnalysis.safetyScore;
      List<String> warnings = [];

      // Add news-based warnings
      for (final warning in newsAnalysis.warnings) {
        warnings.add('${warning.type.icon} ${warning.description}');
        debugPrint('⚠️ ${warning.type.displayName}: ${warning.description}');
      }

      // Deduct for user-reported incidents
      if (incidents.isNotEmpty) {
        safetyScore -= incidents.length * 8;
        for (final incident in incidents) {
          warnings.add('📍 ${incident.type} reported near ${incident.locationName}');
        }
      }

      // Check Google route warnings
      if (route.warnings.isNotEmpty) {
        safetyScore -= 3;
        warnings.addAll(route.warnings.map((w) => '⚠️ $w'));
      }

      // Clamp final score
      safetyScore = safetyScore.clamp(10, 95);

      // Determine safety level
      String safetyLevel;
      if (safetyScore >= 80) {
        safetyLevel = 'VERY SAFE';
      } else if (safetyScore >= 60) {
        safetyLevel = 'MOSTLY SAFE';
      } else if (safetyScore >= 40) {
        safetyLevel = 'MODERATE RISK';
      } else {
        safetyLevel = 'HIGH RISK';
      }

      debugPrint('✅ Route ${i + 1}: Safety Score $safetyScore ($safetyLevel)');

      // 5. Store in cache for future requests
      cache.set(fromText, toText, {
        'safetyScore': safetyScore,
        'safetyLevel': safetyLevel,
        'warnings': warnings,
      });
      debugPrint('💾 Cached safety data for $fromText → $toText');

      setState(() {
        _routes[i].safetyScore = safetyScore;
        _routes[i].safetyLevel = safetyLevel;
        _routes[i].safetyWarnings = warnings;
        _routes[i].routeColor = _routes[i].getSafetyColor();
      });
    }

    // Sort routes by safety score (safest first)
    _routes.sort((a, b) => b.safetyScore.compareTo(a.safetyScore));
    _selectedRouteIndex = 0; // Auto-select safest route
    
    // Get incidents for selected route
    if (_routes.isNotEmpty) {
      _routeIncidents = await _findIncidentsAlongRoute(_routes[_selectedRouteIndex]);
    }
    
    // Detect route intersections for switching opportunities
    debugPrint('🔀 Detecting route intersections...');
    _intersections = _intersectionService.findIntersections(_routes);
    debugPrint('✅ Found ${_intersections.length} route intersections');
    
    for (final intersection in _intersections) {
      debugPrint('  📍 ${intersection.description}');
      for (final point in intersection.intersectionPoints) {
        debugPrint('    - ${point.getProgressDescription(intersection.route1.routeIndex)}');
      }
    }

    setState(() => _isAnalyzingRoutes = false);
  }

  Future<List<IncidentReport>> _findIncidentsAlongRoute(RouteResult route) async {
    try {
      final allIncidents = await _incidentDb.getIncidents(daysBack: 30);
      
      return allIncidents.where((incident) {
        // Check if incident is near any point on the route
        for (final point in route.routePoints) {
          final distance = _calculatePointDistance(
            incident.location,
            point,
          );
          if (distance < 30) { // 30km buffer
            return true;
          }
        }
        return false;
      }).toList();
    } catch (e) {
      debugPrint('Error finding incidents: $e');
      return [];
    }
  }

  double _calculatePointDistance(latlong2.LatLng p1, latlong2.LatLng p2) {
    const distance = latlong2.Distance();
    return distance.as(latlong2.LengthUnit.Kilometer, p1, p2);
  }

  RouteResult? get _selectedRoute => 
      _routes.isNotEmpty ? _routes[_selectedRouteIndex] : null;

  List<MapMarker> get _mapMarkers {
    final markers = <MapMarker>[];
    
    if (_selectedRoute != null && _selectedRoute!.routePoints.isNotEmpty) {
      // Origin marker
      markers.add(MapMarker(
        position: _selectedRoute!.routePoints.first,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.neonGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: AppTheme.neonGreen.withValues(alpha: 0.5), blurRadius: 10)],
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
        ),
      ));

      // Destination marker
      markers.add(MapMarker(
        position: _selectedRoute!.routePoints.last,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.accentBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: AppTheme.accentBlue.withValues(alpha: 0.5), blurRadius: 10)],
          ),
          child: const Icon(Icons.flag, color: Colors.white, size: 24),
        ),
      ));
    }

    // Incident markers
    for (final incident in _routeIncidents) {
      final color = incident.severity > 70 ? Colors.red : Colors.orange;
      markers.add(MapMarker(
        position: latlong2.LatLng(incident.location.latitude, incident.location.longitude),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.warning, color: Colors.white, size: 18),
        ),
      ));
    }
    
    
    // Switch Point markers (route intersections)
    for (final intersection in _intersections) {
      // Only show intersections involving the currently selected route
      if (intersection.route1.routeIndex != _selectedRouteIndex &&
          intersection.route2.routeIndex != _selectedRouteIndex) {
        continue;
      }
      
      // Limit to max 3 intersection points to avoid clutter
      final pointsToShow = intersection.intersectionPoints.length > 3
          ? intersection.intersectionPoints.sublist(0, 3)
          : intersection.intersectionPoints;
      
      for (final point in pointsToShow) {
        markers.add(MapMarker(
          position: point.location,
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing outer ring
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.purple, width: 2),
                ),
              ),
              // Inner icon
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.compare_arrows, color: Colors.white, size: 18),
              ),
            ],
          ),
        ));
      }
    }

    return markers;
  }

  /// Build dashed connector lines from intersection points to alternative routes
  List<MapPolyline> _buildIntersectionConnectors() {
    final connectors = <MapPolyline>[];
    
    if (_selectedRoute == null || _intersections.isEmpty) {
      return connectors;
    }
    
    for (final intersection in _intersections) {
      // Only show connectors for selected route
      if (intersection.route1.routeIndex != _selectedRouteIndex &&
          intersection.route2.routeIndex != _selectedRouteIndex) {
        continue;
      }
      
      // Limit to 3 connectors to avoid clutter
      final pointsToShow = intersection.intersectionPoints.length > 3
          ? intersection.intersectionPoints.sublist(0, 3)
          : intersection.intersectionPoints;
      
      for (final point in pointsToShow) {
        // Determine which is the alternative route
        final altRoute = intersection.route1.routeIndex == _selectedRouteIndex
            ? intersection.route2
            : intersection.route1;
        
        // Find closest point on alternative route
        final closestPoint = _findClosestPoint(point.location, altRoute.routePoints);
        
        // Create dashed connector line
        connectors.add(MapPolyline(
          points: [point.location, closestPoint],
          color: Colors.purple.withValues(alpha: 0.7),
          width: 3.0,
          isDashed: true,
        ));
      }
    }
    
    return connectors;
  }

  /// Find closest point in a list to a target point
  latlong2.LatLng _findClosestPoint(latlong2.LatLng target, List<latlong2.LatLng> points) {
    if (points.isEmpty) return target;
    
    latlong2.LatLng closest = points.first;
    double minDistance = _calculatePointDistance(target, closest);
    
    for (final point in points) {
      final distance = _calculatePointDistance(target, point);
      if (distance < minDistance) {
        minDistance = distance;
        closest = point;
      }
    }
    
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Full screen map (zoomable/scrollable)
          Positioned.fill(
            child: PlatformAwareMap(
              center: _mapCenter,
              zoom: _mapZoom,
              minZoom: 4.0,
              maxZoom: 18.0,
              markers: _mapMarkers,
              polylinePoints: _selectedRoute?.routePoints,
              polylineColor: _selectedRoute?.routeColor ?? AppTheme.neonGreen,
              polylineWidth: 5.0,
              polylines: _buildIntersectionConnectors(), // Add dashed connectors
            ),
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black87,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Toggle Input Button (when collapsed)
          if (!_isInputExpanded && _routeCalculated)
            Positioned(
              top: 50,
              right: 16,
              child: CircleAvatar(
                backgroundColor: AppTheme.neonGreen,
                child: IconButton(
                  icon: const Icon(Icons.edit_location_alt, color: Colors.black),
                  onPressed: () => setState(() => _isInputExpanded = true),
                ),
              ),
            ),

          // Collapsible Input Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _isInputExpanded ? 100 : -200,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isInputExpanded ? 1.0 : 0.0,
              child: _buildInputPanel(),
            ),
          ),
          
          // Switch Recommendation Banner
          if (_intersections.isNotEmpty && _selectedRoute != null)
            Positioned(
              top: _isInputExpanded ? 320 : 120,
              left: 16,
              right: 16,
              child: _buildSwitchRecommendationBanner(),
            ),

          // Route Selection Cards (bottom)
          if (_routeCalculated && _routes.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _routes.length,
                  itemBuilder: (context, index) => _buildRouteCard(index),
                ),
              ),
            ),

          // Start Navigation Button
          if (_routeCalculated)
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: NeonButton(
                text: "START NAVIGATION",
                isPrimary: true,
                onPressed: () {
                  final route = _selectedRoute;
                  if (route != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.navigation, color: Colors.black),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Starting ${route.routeName} - Safety: ${route.safetyScore}%',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppTheme.neonGreen,
                      ),
                    );
                  }
                },
              ),
            ),

          // Loading overlay
          if (_isCalculating || _isAnalyzingRoutes)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.neonGreen),
                      const SizedBox(height: 16),
                      Text(
                        _isCalculating ? 'Finding routes...' : 'Analyzing safety...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapse button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Plan Route',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_routeCalculated)
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                  onPressed: () => setState(() => _isInputExpanded = false),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputField(
            icon: Icons.my_location,
            color: AppTheme.neonGreen,
            controller: _fromController,
            hint: "From (e.g., Bauchi)",
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 20,
                child: VerticalDivider(color: Colors.grey, thickness: 1),
              ),
            ),
          ),
          _buildInputField(
            icon: Icons.location_on,
            color: AppTheme.accentBlue,
            controller: _toController,
            hint: "To (e.g., Kano)",
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCalculating ? null : _calculateRoutes,
              icon: const Icon(Icons.route, size: 18),
              label: const Text('Find Safe Routes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(int index) {
    final route = _routes[index];
    final isSelected = index == _selectedRouteIndex;
    final isSafest = index == 0 && _routes.length > 1;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRouteIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 300 : 270,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? route.routeColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: route.routeColor.withValues(alpha: 0.35), blurRadius: 14)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + score badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isSafest)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SAFEST',
                            style: TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          route.routeName,
                          style: TextStyle(
                            color: isSelected ? route.routeColor : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: route.routeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${route.safetyScore}%',
                    style: TextStyle(
                      color: route.routeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Safety score bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: route.safetyScore / 100,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(route.routeColor),
                minHeight: 5,
              ),
            ),

            const SizedBox(height: 8),

            // Distance + duration
            Row(
              children: [
                Icon(Icons.straighten, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(route.distanceText, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(width: 14),
                Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(route.durationText, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),

            const SizedBox(height: 6),

            // Safety level
            Row(
              children: [
                Icon(
                  route.safetyScore >= 60 ? Icons.verified_user : Icons.warning_amber,
                  size: 13,
                  color: route.routeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  route.safetyLevel,
                  style: TextStyle(
                    color: route.routeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Warnings: show first if not selected, all if selected
            if (route.safetyWarnings.isNotEmpty) ...[
              const SizedBox(height: 6),
              if (!isSelected)
                Text(
                  route.safetyWarnings.first,
                  style: const TextStyle(color: Colors.orange, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 68),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: route.safetyWarnings.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        route.safetyWarnings[i],
                        style: const TextStyle(color: Colors.orange, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildInputField({
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String hint,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSwitchRecommendationBanner() {
    // Find intersections involving current route
    final relevantIntersections = _intersections.where((intersection) {
      return intersection.route1.routeIndex == _selectedRouteIndex ||
             intersection.route2.routeIndex == _selectedRouteIndex;
    }).toList();
    
    if (relevantIntersections.isEmpty) return const SizedBox.shrink();
    
    // Get the alternative route from first intersection
    final firstIntersection = relevantIntersections.first;
    final alternativeRoute = firstIntersection.route1.routeIndex == _selectedRouteIndex
        ? firstIntersection.route2
        : firstIntersection.route1;
    
    final safetyDiff = alternativeRoute.safetyScore - (_selectedRoute?.safetyScore ?? 0);
    
    // Only show if alternative is safer
    if (safetyDiff <= 0) return const SizedBox.shrink();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.9),
            Colors.deepPurple.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Switch Point Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${relevantIntersections.length} intersection${relevantIntersections.length > 1 ? 's' : ''} with ${alternativeRoute.routeName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
                if (safetyDiff > 0)
                  Text(
                    '+$safetyDiff% safer',
                    style: const TextStyle(
                      color: AppTheme.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedRouteIndex = alternativeRoute.routeIndex;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to ${alternativeRoute.routeName}'),
                  backgroundColor: Colors.purple,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'SWITCH',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
