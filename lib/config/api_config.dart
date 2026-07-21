import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration for RouteGuardian
///
/// All keys are loaded from `.env` at runtime — never hardcoded.
/// The `.env` file is gitignored for security.
class ApiConfig {
  // Google Maps API Key — loaded from .env
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // News API Key — loaded from .env
  static String get newsApiKey =>
      dotenv.env['NEWS_API_KEY'] ?? '';

  // N-ATLaS Server URL — platform aware, loaded from .env
  // Web uses localhost; mobile uses the WiFi IP from .env
  static String get natlasServerUrl {
    final envUrl = dotenv.env['NATLAS_SERVER_URL'] ?? 'http://localhost:8765';
    if (kIsWeb) {
      return 'http://127.0.0.1:8765';
    }
    return envUrl;
  }

  // Google Maps Tile URLs
  static String get googleMapsTileUrl =>
      'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=$googleMapsApiKey';

  static String get googleMapsHybridUrl =>
      'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}&key=$googleMapsApiKey';

  static String get googleMapsSatelliteUrl =>
      'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}&key=$googleMapsApiKey';

  static String get googleMapsTerrainUrl =>
      'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}&key=$googleMapsApiKey';

  // Directions API
  static String getDirectionsUrl(String origin, String destination) =>
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$googleMapsApiKey';

  // Geocoding API
  static String getGeocodingUrl(String address) =>
      'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$googleMapsApiKey';

  // Reverse Geocoding
  static String getReverseGeocodingUrl(double lat, double lng) =>
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleMapsApiKey';
}
