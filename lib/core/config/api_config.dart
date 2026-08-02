import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration for Nebah
///
/// All keys and URLs are loaded from `.env` at runtime.
class ApiConfig {
  // Nebah Custom FastAPI Backend URL
  static String get nebahApiBaseUrl {
    final envUrl = dotenv.env['NEBAH_API_URL'] ?? 'http://localhost:8000/v1';
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/v1';
    }
    return envUrl;
  }

  // Nebah AI Inference Server URL
  static String get natlasServerUrl {
    return dotenv.env['NATLAS_SERVER_URL'] ?? 'http://10.0.2.2:8765';
  }

  // Supabase Cloud Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://jyuayofkakbbdlzsctbe.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Gemini AI Key & Capability Chain
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get geminiPrimaryModel =>
      dotenv.env['GEMINI_MODEL_PRIMARY'] ?? 'gemini-2.5-flash';

  static String get geminiSecondaryModel =>
      dotenv.env['GEMINI_MODEL_SECONDARY'] ?? 'gemini-3.1-flash-lite';

  static String get geminiTertiaryModel =>
      dotenv.env['GEMINI_MODEL_TERTIARY'] ?? 'gemini-2.5-flash-lite';

  static String get geminiFallbackModel =>
      dotenv.env['GEMINI_MODEL_FALLBACK'] ?? 'gemini-2.0-flash-lite';

  // Google Maps API Key
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // News API Key
  static String get newsApiKey =>
      dotenv.env['NEWS_API_KEY'] ?? '';

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
