// Smoke test for RouteGuardian app
//
// Verifies that the app can launch and render the main screen
// without throwing any errors.

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:route_guardian/main.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return MockHttpClientRequest();
  }
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  
  @override
  int get contentLength => mockImageBytes.length;
  
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([mockImageBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

// 1x1 transparent PNG
final List<int> mockImageBytes = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
];

void main() {
  setUpAll(() async {
    // Set up mock HTTP overrides to handle NetworkImage loads
    HttpOverrides.global = MockHttpOverrides();

    // Initialize sqflite for local test execution
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Load .env with test fallbacks
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // If .env is not available in test environment, use test defaults
      dotenv.env.addAll({
        'GOOGLE_MAPS_API_KEY': 'test_key',
        'NEWS_API_KEY': 'test_key',
        'NATLAS_SERVER_URL': 'http://localhost:8765',
      });
    }
  });

  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify the app title or main screen renders
    expect(find.byType(MaterialApp), findsOneWidget);

    // Pump a duration greater than the Geolocator 10-second timeout
    // to allow any pending geolocation timeouts or delayed futures to resolve
    await tester.pump(const Duration(seconds: 11));
  });
}
