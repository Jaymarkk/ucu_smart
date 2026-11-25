import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ucu_smart_plus/services/building_api_service.dart';

void main() {
  test('public buildings request has no authentication header', () async {
    late http.Request captured;
    final api = BuildingApiService(
      baseUrl: 'http://127.0.0.1:8000/api',
      campusHeadersProvider: () => null,
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 26,
                'code': 'B21',
                'name': 'TEST',
                'category': 'Building',
                'description': 'TEST',
                'location_details': null,
                'map_x_pct': null,
                'map_y_pct': null,
                'route_connection_verified': false,
                'is_public': true,
              },
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);

    final buildings = await api.fetchPublicBuildings();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/buildings');
    expect(captured.headers.containsKey('authorization'), isFalse);
    expect(captured.headers.containsKey('content-type'), isFalse);
    expect(buildings, hasLength(1));
    expect(buildings.single.name, 'TEST');
    expect(buildings.single.hasValidCoordinates, isFalse);
  });

  test('public building response parses off-map records safely', () async {
    final api = BuildingApiService(
      baseUrl: 'http://localhost:8000/api',
      campusHeadersProvider: () => null,
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 99,
                  'code': 'OFF',
                  'name': 'Off Map',
                  'category': 'Building',
                  'description': 'No verified location',
                  'map_x_pct': null,
                  'map_y_pct': null,
                  'route_connection_verified': false,
                  'is_public': true,
                },
              ],
            }),
            200,
          )),
    );
    addTearDown(api.close);

    final buildings = await api.fetchPublicBuildings();

    expect(buildings.single.hasValidCoordinates, isFalse);
    expect(buildings.single.hasVerifiedRoute, isFalse);
  });

  test('timeout allows a successful retry', () async {
    var requests = 0;
    final api = BuildingApiService(
      baseUrl: 'http://localhost:8000/api',
      requestTimeout: const Duration(milliseconds: 20),
      campusHeadersProvider: () => null,
      client: MockClient((_) async {
        requests++;
        if (requests == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
        return http.Response(jsonEncode({'data': []}), 200);
      }),
    );
    addTearDown(api.close);

    await expectLater(
      api.fetchPublicBuildings(),
      throwsA(isA<BuildingApiException>()),
    );
    final retry = await api.fetchPublicBuildings();
    expect(retry, isEmpty);
  });
}
