// Web platform - Google Maps Flutter with proper state management
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
  return _GoogleMapWithPolyline(
    key: ValueKey(polylinePoints?.length ?? 0),
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

class _GoogleMapWithPolyline extends StatefulWidget {
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
  final Function(latlong2.LatLng)? onTap;
  final Function(latlong2.LatLng)? onCameraMove;
  final VoidCallback? onCameraIdle;

  const _GoogleMapWithPolyline({
    Key? key,
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
    this.onTap,
    this.onCameraMove,
    this.onCameraIdle,
  }) : super(key: key);

  @override
  State<_GoogleMapWithPolyline> createState() => _GoogleMapWithPolylineState();
}

class _GoogleMapWithPolylineState extends State<_GoogleMapWithPolyline> {

  Set<Polyline> _buildPolylines() {
    final Set<Polyline> polylines = {};
    
    // Main route polyline (backward compatibility)
    if (widget.polylinePoints != null && widget.polylinePoints!.isNotEmpty) {
      final points = widget.polylinePoints!;
      debugPrint('📍 Building main polyline with ${points.length} points');
      
      polylines.add(Polyline(
        polylineId: const PolylineId('route_line'),
        points: points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        color: widget.polylineColor,
        width: widget.polylineWidth.round().clamp(3, 8),
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      ));
    }
    
    // Additional polylines (for connectors, alternative routes, etc.)
    if (widget.polylines != null) {
      for (int i = 0; i < widget.polylines!.length; i++) {
        final poly = widget.polylines![i];
        
        if (poly.isDashed) {
          // Dashed line (for connectors) - approximated with dotted line
          polylines.add(Polyline(
            polylineId: PolylineId('dashed_$i'),
            points: poly.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            color: poly.color,
            width: poly.width.round().clamp(2, 6),
            patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dashed pattern!
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ));
        } else {
          // Solid line
          polylines.add(Polyline(
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
    
    return polylines;
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> googleMarkers = {};
    
    if (widget.markers != null) {
      for (int i = 0; i < widget.markers!.length; i++) {
        final m = widget.markers![i];
        googleMarkers.add(Marker(
          markerId: MarkerId('marker_$i'),
          position: LatLng(m.position.latitude, m.position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
          ),
        ));
      }
    }
    
    return googleMarkers;
  }

  Set<Circle> _buildCircles() {
    final Set<Circle> googleCircles = {};
    
    if (widget.circles != null) {
      for (int i = 0; i < widget.circles!.length; i++) {
        final c = widget.circles![i];
        googleCircles.add(Circle(
          circleId: CircleId('circle_$i'),
          center: LatLng(c.center.latitude, c.center.longitude),
          radius: c.radius,
          fillColor: c.color.withOpacity(c.opacity),
          strokeColor: c.color,
          strokeWidth: 2,
        ));
      }
    }
    
    return googleCircles;
  }

  @override
  void didUpdateWidget(covariant _GoogleMapWithPolyline oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // DON'T move camera automatically during drag
    // Only move when key changes (GPS button clicked in location picker)
    // This prevents the jumping/lag issue
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.center.latitude, widget.center.longitude),
        zoom: widget.zoom,
      ),
      minMaxZoomPreference: MinMaxZoomPreference(widget.minZoom, widget.maxZoom),
      polylines: _buildPolylines(),
      markers: _buildMarkers(),
      circles: _buildCircles(),
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
      onTap: widget.onTap != null
          ? (LatLng position) {
              widget.onTap!(latlong2.LatLng(position.latitude, position.longitude));
            }
          : null,
      onCameraMove: widget.onCameraMove != null
          ? (CameraPosition position) {
              widget.onCameraMove!(latlong2.LatLng(
                position.target.latitude,
                position.target.longitude,
              ));
            }
          : null,
      onCameraIdle: widget.onCameraIdle,
      onMapCreated: (controller) {
        widget.onMapCreated?.call(controller);
        widget.onStyleLoaded?.call();
      },
    );
  }
}
