import 'package:flutter/foundation.dart';

const String _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  final configuredUrl = _configuredApiBaseUrl.trim();
  if (configuredUrl.isNotEmpty) {
    return configuredUrl;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'http://10.0.2.2:8000/api',
    TargetPlatform.iOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.fuchsia =>
      'http://127.0.0.1:8000/api',
  };
}
