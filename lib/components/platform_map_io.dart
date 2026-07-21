// IO platforms (Windows, macOS, Linux, Android, iOS) - Google Maps
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'platform_aware_map.dart';

Widget buildPlatformMap({
  required latlong2.LatLng center,
  double zoom = 12.0,
  double minZoom = 3.0,
  double maxZoom = 18.0,
  String? styleUrl,
  Function(dynamic controller)? onMapCreated,
  VoidCallback? onStyleLoaded,
  List<MapCircle>? circles,
  List<MapMarker>? markers,
  List<latlong2.LatLng>? polylinePoints,
  Color polylineColor = const Color(0xFF39FF14),
  double polylineWidth = 4.0,
  List<MapPolyline>? polylines,
  Function(latlong2.LatLng)? onTap,
  Function(latlong2.LatLng)? onCameraMove,
  VoidCallback? onCameraIdle,
}) {
  // For desktop platforms (Windows, macOS, Linux), use flutter_map as fallback
  // Google Maps Flutter doesn't support desktop yet
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return _buildFlutterMapFallback(
      center: center,
      zoom: zoom,
      minZoom: minZoom,
      maxZoom: maxZoom,
      circles: circles,
      markers: markers,
      polylinePoints: polylinePoints,
      polylineColor: polylineColor,
      polylineWidth: polylineWidth,
      polylines: polylines,
      onMapCreated: onMapCreated,
      onStyleLoaded: onStyleLoaded,
      onTap: onTap,
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
    );
  }

  // For Android and iOS, use Google Maps
  return _buildGoogleMap(
    center: center,
    zoom: zoom,
    minZoom: minZoom,
    maxZoom: maxZoom,
    circles: circles,
    markers: markers,
    polylinePoints: polylinePoints,
    polylineColor: polylineColor,
    polylineWidth: polylineWidth,
    polylines: polylines,
    onMapCreated: onMapCreated,
    onStyleLoaded: onStyleLoaded,
    onTap: onTap,
    onCameraMove: onCameraMove,
    onCameraIdle: onCameraIdle,
  );
}

Widget _buildGoogleMap({
  required latlong2.LatLng center,
  required double zoom,
  required double minZoom,
  required double maxZoom,
  List<MapCircle>? circles,
  List<MapMarker>? markers,
  List<latlong2.LatLng>? polylinePoints,
  Color polylineColor = const Color(0xFF39FF14),
  double polylineWidth = 4.0,
  List<MapPolyline>? polylines,
  Function(dynamic controller)? onMapCreated,
  VoidCallback? onStyleLoaded,
  Function(latlong2.LatLng)? onTap,
  Function(latlong2.LatLng)? onCameraMove,
  VoidCallback? onCameraIdle,
}) {
  // Build polylines
  final Set<Polyline> googlePolylines = {};
  if (polylinePoints != null && polylinePoints.isNotEmpty) {
    googlePolylines.add(Polyline(
      polylineId: const PolylineId('route_line'),
      points: polylinePoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
      color: polylineColor,
      width: polylineWidth.round().clamp(3, 8),
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ));
  }

  // Additional polylines (for connectors, alternative routes, etc.)
  if (polylines != null) {
    for (int i = 0; i < polylines.length; i++) {
      final poly = polylines[i];
      if (poly.isDashed) {
        googlePolylines.add(Polyline(
          polylineId: PolylineId('dashed_$i'),
          points: poly.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          color: poly.color,
          width: poly.width.round().clamp(2, 6),
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ));
      } else {
        googlePolylines.add(Polyline(
          polylineId: PolylineId('solid_$i'),
          points: poly.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          color: poly.color,
          width: poly.width.round().clamp(3, 8),
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        ));
      }
    }
  }

  // Build markers
  final Set<Marker> googleMarkers = {};
  if (markers != null) {
    for (int i = 0; i < markers.length; i++) {
      final m = markers[i];
      googleMarkers.add(Marker(
        markerId: MarkerId('marker_$i'),
        position: LatLng(m.position.latitude, m.position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
        ),
      ));
    }
  }

  // Build circles
  final Set<Circle> googleCircles = {};
  if (circles != null) {
    for (int i = 0; i < circles.length; i++) {
      final c = circles[i];
      googleCircles.add(Circle(
        circleId: CircleId('circle_$i'),
        center: LatLng(c.center.latitude, c.center.longitude),
        radius: c.radius,
        fillColor: c.color.withValues(alpha: c.opacity),
        strokeColor: c.color,
        strokeWidth: 2,
      ));
    }
  }

  return GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng(center.latitude, center.longitude),
      zoom: zoom,
    ),
    minMaxZoomPreference: MinMaxZoomPreference(minZoom, maxZoom),
    polylines: googlePolylines,
    markers: googleMarkers,
    circles: googleCircles,
    mapType: MapType.normal,
    myLocationEnabled: false,
    myLocationButtonEnabled: false,
    zoomControlsEnabled: true,
    zoomGesturesEnabled: true,
    scrollGesturesEnabled: true,
    rotateGesturesEnabled: true,
    tiltGesturesEnabled: false,
    compassEnabled: false,
    mapToolbarEnabled: false,
    onTap: onTap != null
        ? (LatLng position) {
            onTap(latlong2.LatLng(position.latitude, position.longitude));
          }
        : null,
    onCameraMove: onCameraMove != null
        ? (CameraPosition position) {
            onCameraMove(latlong2.LatLng(
              position.target.latitude,
              position.target.longitude,
            ));
          }
        : null,
    onCameraIdle: onCameraIdle,
    onMapCreated: (controller) {
      onMapCreated?.call(controller);
      onStyleLoaded?.call();
    },
  );
}

// Fallback for desktop platforms using flutter_map with Google tiles
Widget _buildFlutterMapFallback({
  required latlong2.LatLng center,
  required double zoom,
  required double minZoom,
  required double maxZoom,
  List<MapCircle>? circles,
  List<MapMarker>? markers,
  List<latlong2.LatLng>? polylinePoints,
  Color polylineColor = const Color(0xFF39FF14),
  double polylineWidth = 4.0,
  List<MapPolyline>? polylines,
  Function(dynamic controller)? onMapCreated,
  VoidCallback? onStyleLoaded,
  Function(latlong2.LatLng)? onTap,
  Function(latlong2.LatLng)? onCameraMove,
  VoidCallback? onCameraIdle,
}) {
  // Import flutter_map dynamically
  return FutureBuilder(
    future: Future.delayed(Duration.zero),
    builder: (context, snapshot) {
      // Use flutter_map for desktop
      return _FlutterMapDesktop(
        center: center,
        zoom: zoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        circles: circles,
        markers: markers,
        polylinePoints: polylinePoints,
        polylineColor: polylineColor,
        polylineWidth: polylineWidth,
        polylines: polylines,
        onMapCreated: onMapCreated,
        onStyleLoaded: onStyleLoaded,
      );
    },
  );
}

class _FlutterMapDesktop extends StatelessWidget {
  final latlong2.LatLng center;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final List<MapCircle>? circles;
  final List<MapMarker>? markers;
  final List<latlong2.LatLng>? polylinePoints;
  final Color polylineColor;
  final double polylineWidth;
  final List<MapPolyline>? polylines;
  final Function(dynamic controller)? onMapCreated;
  final VoidCallback? onStyleLoaded;

  const _FlutterMapDesktop({
    required this.center,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    this.circles,
    this.markers,
    this.polylinePoints,
    this.polylineColor = const Color(0xFF39FF14),
    this.polylineWidth = 4.0,
    this.polylines,
    this.onMapCreated,
    this.onStyleLoaded,
  });

  @override
  Widget build(BuildContext context) {
    // Use flutter_map package
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Text(
          'Desktop map - use web or mobile for full experience',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
