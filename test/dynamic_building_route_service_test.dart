import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_smart_plus/navigation/campus_graph.dart';
import 'package:ucu_smart_plus/navigation/dynamic_building_route_service.dart';
import 'package:ucu_smart_plus/navigation/map_coordinates.dart';

void main() {
  const routes = DynamicBuildingRouteService();

  test('map coordinate conversion round-trips normalized percent values', () {
    const size = Size(706, 557);
    const coordinate = Offset(42.5, 31.25);

    expect(mapPixelToPercent(size, percentToMapPixel(size, coordinate)),
        coordinate);
  });

  test('does not offer directions without a verified route connection', () {
    final route = routes.findRoute(
      start: const Offset(50, 30),
      destination: const Offset(55, 25),
      destinationRouteNodeId: 'top',
      destinationConnectionVerified: false,
    );

    expect(route, isNull);
  });

  test('routes between dynamic buildings through configured graph nodes', () {
    final route = routes.findRoute(
      start: const Offset(40, 19),
      destination: const Offset(72, 38),
      startRouteNodeId: 'top',
      startConnectionVerified: true,
      destinationRouteNodeId: 'eastUpper',
      destinationConnectionVerified: true,
    );

    expect(route, isNotNull);
    expect(route!.points.first, const Offset(40, 19));
    expect(route.points.last, const Offset(72, 38));
    expect(route.points, contains(const Offset(38, 20)));
    expect(route.points, contains(const Offset(70, 37)));
    expect(
      CampusGraph.findPathBetweenNodes(
        startNodeId: 'unknown',
        endNodeId: 'eastUpper',
      ),
      isNull,
    );
  });
}
