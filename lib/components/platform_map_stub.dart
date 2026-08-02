// Stub file for conditional imports
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'platform_aware_map.dart';

Widget buildPlatformMap({
  required latlong2.LatLng center,
  double zoom = 12.0,
  double minZoom = 3.0,
  double maxZoom = 18.0,
  String? styleUrl,
  MapTypeMode mapType = MapTypeMode.hybrid,
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
  throw UnsupportedError('Platform not supported');
}

