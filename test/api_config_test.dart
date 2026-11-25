import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_smart_plus/services/api_config.dart';

const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  if (_configuredApiBaseUrl.trim().isEmpty) {
    test('uses the Android emulator host by default on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(apiBaseUrl, 'http://10.0.2.2:8000/api');
    });

    test('uses localhost by default on Windows desktop', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      expect(apiBaseUrl, 'http://127.0.0.1:8000/api');
    });
  } else {
    test('uses the API_BASE_URL build-time override', () {
      expect(apiBaseUrl, _configuredApiBaseUrl.trim());
    });
  }
}
