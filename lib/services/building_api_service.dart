import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'campus_geofence_service.dart';

@immutable
class BuildingRecord {
  const BuildingRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.isActive,
    required this.isPublic,
    this.description,
    this.floorInfo,
    this.locationDetails,
    this.mapXPct,
    this.mapYPct,
    this.routeNodeId,
    this.routeConnectionVerified = false,
  });

  final int id;
  final String code;
  final String name;
  final String category;
  final String? description;
  final String? floorInfo;
  final String? locationDetails;
  final double? mapXPct;
  final double? mapYPct;
  final String? routeNodeId;
  final bool routeConnectionVerified;
  final bool isActive;
  final bool isPublic;

  bool get hasValidCoordinates =>
      mapXPct != null &&
      mapYPct != null &&
      mapXPct!.isFinite &&
      mapYPct!.isFinite &&
      mapXPct! >= 0 &&
      mapXPct! <= 100 &&
      mapYPct! >= 0 &&
      mapYPct! <= 100;

  bool get hasVerifiedRoute =>
      hasValidCoordinates &&
      routeNodeId != null &&
      routeNodeId!.isNotEmpty &&
      routeConnectionVerified;

  factory BuildingRecord.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const BuildingApiException('Invalid building record from server.');
    }

    final id = value['id'];
    final code = value['code'];
    final name = value['name'];
    final category = value['category'];
    if (id is! num ||
        code is! String ||
        name is! String ||
        category is! String) {
      throw const BuildingApiException('Invalid building record from server.');
    }

    return BuildingRecord(
      id: id.toInt(),
      code: code,
      name: name,
      category: category,
      description: value['description'] as String?,
      floorInfo: value['floor_info'] as String?,
      locationDetails: value['location_details'] as String?,
      mapXPct: _optionalDouble(value['map_x_pct']),
      mapYPct: _optionalDouble(value['map_y_pct']),
      routeNodeId: value['route_node_id'] as String?,
      routeConnectionVerified: value['route_connection_verified'] == true,
      isActive: value['is_active'] == true,
      isPublic: value['is_public'] == true,
    );
  }

  static double? _optionalDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Map<String, Object?> toJson() => {
        'code': code.trim().toUpperCase(),
        'name': name.trim(),
        'description': _trimOrNull(description),
        'category': category.trim(),
        'floor_info': _trimOrNull(floorInfo),
        'location_details': _trimOrNull(locationDetails),
        'map_x_pct': mapXPct,
        'map_y_pct': mapYPct,
        'route_node_id': routeNodeId,
        'route_connection_verified': routeConnectionVerified,
        'is_active': isActive,
        'is_public': isPublic,
      };

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class BuildingApiException implements Exception {
  const BuildingApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class BuildingApiService {
  static final BuildingApiService instance = BuildingApiService();

  BuildingApiService({
    String? baseUrl,
    http.Client? client,
    Map<String, String>? Function()? campusHeadersProvider,
    @visibleForTesting Duration requestTimeout = const Duration(seconds: 15),
  })  : _baseUri = Uri.parse(baseUrl ?? apiBaseUrl),
        _client = client ?? http.Client(),
        _campusHeadersProvider = campusHeadersProvider ??
            (() => CampusGeofenceService.instance.currentAccessHeaders),
        _requestTimeout = requestTimeout;

  final Uri _baseUri;
  final http.Client _client;
  final Map<String, String>? Function() _campusHeadersProvider;
  final Duration _requestTimeout;
  final Map<String, Future<List<BuildingRecord>>> _publicBuildingRequests = {};

  void close() => _client.close();

  Future<List<BuildingRecord>> fetchPublicBuildings({
    String? search,
    String? category,
  }) {
    final normalizedSearch = _normalizeFilter(search);
    final normalizedCategory = _normalizeFilter(category);
    final requestKey = jsonEncode([normalizedSearch, normalizedCategory]);
    final currentRequest = _publicBuildingRequests[requestKey];
    if (currentRequest != null) return currentRequest;

    late final Future<List<BuildingRecord>> trackedRequest;
    trackedRequest = _fetchPublicBuildings(
      search: normalizedSearch,
      category: normalizedCategory,
    ).whenComplete(() {
      if (identical(_publicBuildingRequests[requestKey], trackedRequest)) {
        _publicBuildingRequests.remove(requestKey);
      }
    });
    _publicBuildingRequests[requestKey] = trackedRequest;
    return trackedRequest;
  }

  Future<List<BuildingRecord>> _fetchPublicBuildings({
    String? search,
    String? category,
  }) async {
    final json = await _send(
      'GET',
      'buildings',
      query: {
        if (search != null) 'search': search,
        if (category != null) 'category': category,
      },
    );
    return _parseBuildingList(json);
  }

  String? _normalizeFilter(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  List<BuildingRecord> _parseBuildingList(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) {
      throw const BuildingApiException('The server returned an invalid list.');
    }
    return data.map(BuildingRecord.fromJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) async {
    final requiresCampusAccess = path.startsWith('admin/');
    final campusHeaders =
        requiresCampusAccess ? _campusHeadersProvider() : null;
    if (requiresCampusAccess && campusHeaders == null) {
      throw const BuildingApiException(
        'Campus location must be freshly verified before this request.',
        statusCode: 403,
      );
    }
    final uri = Uri.parse(
      '${_baseUri.toString().replaceFirst(RegExp(r'/+$'), '')}/$path',
    ).replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (campusHeaders != null) headers.addAll(campusHeaders);

    final abortCompleter = Completer<void>();
    final request = http.AbortableRequest(
      method,
      uri,
      abortTrigger: abortCompleter.future,
    )..headers.addAll(headers);

    try {
      if (body != null) request.body = jsonEncode(body);
      final responseFuture = () async {
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      }();
      final response = await responseFuture.timeout(
        _requestTimeout,
        onTimeout: () async {
          abortCompleter.complete();
          try {
            await responseFuture;
          } on http.ClientException {
            // Abortable clients complete the pending request with this error.
          } on SocketException {
            // The request may fail at the transport while cancellation settles.
          }
          throw TimeoutException(
            'The building service took too long to respond.',
            _requestTimeout,
          );
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return <String, dynamic>{};
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        throw const BuildingApiException('The server returned invalid JSON.');
      }

      final message = _errorMessage(response);
      throw BuildingApiException(message, statusCode: response.statusCode);
    } on BuildingApiException {
      rethrow;
    } on SocketException {
      throw const BuildingApiException(
        'Cannot connect to the building service. Check the backend address.',
      );
    } on TimeoutException {
      throw const BuildingApiException(
        'The building service took too long to respond.',
      );
    } on http.ClientException {
      throw const BuildingApiException(
        'Cannot connect to the building service. Check the network.',
      );
    } on FormatException {
      throw const BuildingApiException('The server returned invalid JSON.');
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic>) {
          final messages = errors.values
              .expand((value) => value is List ? value : [value])
              .whereType<String>()
              .where((message) => message.trim().isNotEmpty);
          final joined = messages.join('\n');
          if (joined.isNotEmpty) return joined;
        }
        if (decoded['message'] is String) return decoded['message'] as String;
      }
    } on FormatException {
      // Use a status-safe message below for non-JSON responses.
    }
    if (response.statusCode == 401) {
      return 'Admin session expired. Sign in again.';
    }
    if (response.statusCode == 403) {
      return 'This action requires an Admin account.';
    }
    return 'The building request failed (HTTP ${response.statusCode}).';
  }
}
