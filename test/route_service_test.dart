import 'package:flutter_test/flutter_test.dart';

import 'package:ucu_smart_plus/navigation/route_service.dart';
import 'package:ucu_smart_plus/main.dart';

void main() {
  const routeService = RouteService();

  test('nearby clear locations use a direct route', () {
    final route = routeService.findRoute(
      startX: 53,
      startY: 20.4,
      destinationX: 60,
      destinationY: 20.8,
    );

    expect(route.points.length, 2);
    expect(route.points.first.dx, 53);
    expect(route.points.last.dx, 60);
  });

  test('building 1 to building 2 uses a short nearby detour', () {
    final route = routeService.findRoute(
      startX: 53.0,
      startY: 20.4,
      destinationX: 67.0,
      destinationY: 25.5,
    );

    expect(route.points.first, const Offset(53.0, 20.4));
    expect(route.points.last, const Offset(67.0, 25.5));
    expect(route.points.length, lessThanOrEqualTo(3));
    expect(route.distanceMeters, lessThan(125));
  });

  test('building 2 to building 1 remains a short nearby detour', () {
    final route = routeService.findRoute(
      startX: 67.0,
      startY: 25.5,
      destinationX: 53.0,
      destinationY: 20.4,
    );

    expect(route.points.first, const Offset(67.0, 25.5));
    expect(route.points.last, const Offset(53.0, 20.4));
    expect(route.points.length, lessThanOrEqualTo(3));
    expect(route.distanceMeters, lessThan(125));
  });

  test('building 1 to building 32 reverses the existing route', () {
    final route32To1 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 53.0,
      destinationY: 20.4,
    );
    final route1To32 = routeService.findRoute(
      startX: 53.0,
      startY: 20.4,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route1To32.points, route32To1.points.reversed.toList());
  });

  test('markers 32 and 1 follow the marked corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 16.0),
      Offset(38.0, 18.0),
      Offset(42.0, 19.0),
      Offset(47.0, 19.5),
      Offset(53.0, 20.4),
    ];
    final route32To1 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 53.0,
      destinationY: 20.4,
    );
    final route1To32 = routeService.findRoute(
      startX: 53.0,
      startY: 20.4,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To1.points, expectedRoute);
    expect(route1To32.points, expectedRoute.reversed.toList());
  });

  test('building 1 to building 31 reverses the existing route segment', () {
    const marker31 = Offset(32.5, 13.0);
    final route32To1 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 53.0,
      destinationY: 20.4,
    );
    final marker31Index = route32To1.points.indexOf(marker31);
    final route1To31 = routeService.findRoute(
      startX: 53.0,
      startY: 20.4,
      destinationX: 32.5,
      destinationY: 13.0,
    );

    expect(marker31Index, greaterThanOrEqualTo(0));
    expect(
      route1To31.points,
      route32To1.points.sublist(marker31Index).reversed.toList(),
    );
  });

  test('markers 29 and 8 follow the marked south-east route both ways', () {
    const expectedRoute = <Offset>[
      Offset(48.0, 29.0),
      Offset(44.0, 31.0),
      Offset(41.0, 34.0),
      Offset(39.5, 38.0),
      Offset(40.0, 42.0),
      Offset(43.0, 46.0),
      Offset(47.0, 48.0),
      Offset(52.0, 49.0),
      Offset(57.0, 48.5),
      Offset(62.0, 47.5),
    ];
    final route29To8 = routeService.findRoute(
      startX: 48.0,
      startY: 29.0,
      destinationX: 62.0,
      destinationY: 47.5,
    );
    final route8To29 = routeService.findRoute(
      startX: 62.0,
      startY: 47.5,
      destinationX: 48.0,
      destinationY: 29.0,
    );

    expect(route29To8.points, expectedRoute);
    expect(route8To29.points, expectedRoute.reversed.toList());
  });

  test('markers 29 and 26 follow the marked east-side route both ways', () {
    const expectedRoute = <Offset>[
      Offset(48.0, 29.0),
      Offset(53.0, 27.5),
      Offset(58.0, 26.5),
      Offset(63.0, 27.5),
      Offset(68.0, 29.0),
      Offset(72.5, 31.5),
      Offset(75.5, 33.0),
      Offset(78.0, 34.0),
      Offset(80.5, 33.75),
      Offset(83.0, 33.5),
    ];
    final route29To26 = routeService.findRoute(
      startX: 48.0,
      startY: 29.0,
      destinationX: 83.0,
      destinationY: 33.5,
    );
    final route26To29 = routeService.findRoute(
      startX: 83.0,
      startY: 33.5,
      destinationX: 48.0,
      destinationY: 29.0,
    );

    expect(route29To26.points, expectedRoute);
    expect(route26To29.points, expectedRoute.reversed.toList());
  });

  test('building 1 to building 2 uses a direct connection', () {
    final route = routeService.findRoute(
      startX: 53.0,
      startY: 20.4,
      destinationX: 67.0,
      destinationY: 25.5,
    );

    expect(
      route.points,
      [const Offset(53.0, 20.4), const Offset(67.0, 25.5)],
    );
  });

  test('markers 1 and 25 follow the marked upper corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(53.0, 20.4),
      Offset(58.0, 22.0),
      Offset(63.0, 24.0),
      Offset(68.0, 26.0),
      Offset(72.0, 28.5),
      Offset(75.0, 31.0),
      Offset(78.0, 34.0),
    ];
    final route1To25 = routeService.findRoute(
      startX: 53.0,
      startY: 20.4,
      destinationX: 78.0,
      destinationY: 34.0,
    );
    final route25To1 = routeService.findRoute(
      startX: 78.0,
      startY: 34.0,
      destinationX: 53.0,
      destinationY: 20.4,
    );

    expect(route1To25.points, expectedRoute);
    expect(route25To1.points, expectedRoute.reversed.toList());
  });

  test('markers 1 and 26 follow the same upper corridor as marker 25', () {
    const expectedRoute = <Offset>[
      Offset(53.0, 20.4),
      Offset(58.0, 22.0),
      Offset(63.0, 24.0),
      Offset(68.0, 26.0),
      Offset(72.0, 28.5),
      Offset(75.0, 31.0),
      Offset(78.0, 34.0),
      Offset(80.5, 33.75),
      Offset(83.0, 33.5),
    ];
    final route1To26 = routeService.findRoute(
      startX: 53.0,
      startY: 20.4,
      destinationX: 83.0,
      destinationY: 33.5,
    );
    final route26To1 = routeService.findRoute(
      startX: 83.0,
      startY: 33.5,
      destinationX: 53.0,
      destinationY: 20.4,
    );

    expect(route1To26.points, expectedRoute);
    expect(route26To1.points, expectedRoute.reversed.toList());
  });

  test('nearby nursing buildings avoid distant graph nodes', () {
    final route = routeService.findRoute(
      startX: 54.0,
      startY: 29.5,
      destinationX: 62.0,
      destinationY: 47.5,
    );

    expect(route.points.first, const Offset(54.0, 29.5));
    expect(route.points.last, const Offset(62.0, 47.5));
    expect(route.points.length, lessThanOrEqualTo(3));
    expect(route.distanceMeters, lessThan(155));
  });

  test('building 7 to building 13 uses the manual route', () {
    final route = routeService.findRoute(
      startX: 75.0,
      startY: 47.0,
      destinationX: 49.0,
      destinationY: 75.0,
    );

    expect(route.points, RouteService.manualRoute7To13);
  });

  test('building 13 to building 7 reverses the manual route', () {
    final route = routeService.findRoute(
      startX: 49.0,
      startY: 75.0,
      destinationX: 75.0,
      destinationY: 47.0,
    );

    expect(route.points, RouteService.manualRoute7To13.reversed.toList());
  });

  test('markers 29 and 13 follow the marked west-side path both ways', () {
    const expectedRoute = <Offset>[
      Offset(48.0, 29.0),
      Offset(44.0, 31.0),
      Offset(41.0, 34.0),
      Offset(39.5, 38.0),
      Offset(39.5, 43.0),
      Offset(41.0, 49.0),
      Offset(43.0, 55.0),
      Offset(45.0, 61.0),
      Offset(47.0, 68.0),
      Offset(49.0, 75.0),
    ];
    final route29To13 = routeService.findRoute(
      startX: 48.0,
      startY: 29.0,
      destinationX: 49.0,
      destinationY: 75.0,
    );
    final route13To29 = routeService.findRoute(
      startX: 49.0,
      startY: 75.0,
      destinationX: 48.0,
      destinationY: 29.0,
    );

    expect(route29To13.points, expectedRoute);
    expect(route13To29.points, expectedRoute.reversed.toList());
  });

  test('markers 29 and 25 follow the marked east-side route both ways', () {
    const expectedRoute = <Offset>[
      Offset(48.0, 29.0),
      Offset(53.0, 27.5),
      Offset(58.0, 26.5),
      Offset(63.0, 27.5),
      Offset(68.0, 29.0),
      Offset(72.5, 31.5),
      Offset(75.5, 33.0),
      Offset(78.0, 34.0),
    ];
    final route29To25 = routeService.findRoute(
      startX: 48.0,
      startY: 29.0,
      destinationX: 78.0,
      destinationY: 34.0,
    );
    final route25To29 = routeService.findRoute(
      startX: 78.0,
      startY: 34.0,
      destinationX: 48.0,
      destinationY: 29.0,
    );

    expect(route29To25.points, expectedRoute);
    expect(route25To29.points, expectedRoute.reversed.toList());
    expect(
      expectedRoute.every(
        (point) =>
            point.dx >= 0 &&
            point.dx <= 100 &&
            point.dy >= 0 &&
            point.dy <= 100,
      ),
      isTrue,
    );
  });

  test('markers 11 and 13 follow the marked diagonal path both ways', () {
    const expectedRoute = <Offset>[
      Offset(27.0, 34.5),
      Offset(31.0, 37.0),
      Offset(35.0, 40.5),
      Offset(39.0, 45.0),
      Offset(42.0, 50.0),
      Offset(44.0, 56.0),
      Offset(45.0, 62.0),
      Offset(45.0, 68.0),
      Offset(45.0, 72.0),
      Offset(49.0, 75.0),
    ];
    final route11To13 = routeService.findRoute(
      startX: 27.0,
      startY: 34.5,
      destinationX: 49.0,
      destinationY: 75.0,
    );
    final route13To11 = routeService.findRoute(
      startX: 49.0,
      startY: 75.0,
      destinationX: 27.0,
      destinationY: 34.5,
    );

    expect(route11To13.points, expectedRoute);
    expect(route13To11.points, expectedRoute.reversed.toList());
  });

  test('markers 11 and 15 follow the marked curved path both ways', () {
    const expectedRoute = <Offset>[
      Offset(27.0, 34.5),
      Offset(31.0, 37.0),
      Offset(35.0, 40.5),
      Offset(39.0, 45.0),
      Offset(42.0, 50.0),
      Offset(44.0, 56.0),
      Offset(45.0, 62.0),
      Offset(45.0, 68.0),
      Offset(43.0, 73.0),
      Offset(38.8, 78.0),
    ];
    final route11To15 = routeService.findRoute(
      startX: 27.0,
      startY: 34.5,
      destinationX: 38.8,
      destinationY: 78.0,
    );
    final route15To11 = routeService.findRoute(
      startX: 38.8,
      startY: 78.0,
      destinationX: 27.0,
      destinationY: 34.5,
    );

    expect(route11To15.points, expectedRoute);
    expect(route15To11.points, expectedRoute.reversed.toList());
  });

  test('markers 11 and 19 follow the marked curved path both ways', () {
    const expectedRoute = <Offset>[
      Offset(27.0, 34.5),
      Offset(31.0, 37.0),
      Offset(35.0, 41.0),
      Offset(39.0, 46.0),
      Offset(42.0, 51.0),
      Offset(44.0, 56.0),
      Offset(44.5, 60.0),
      Offset(43.0, 63.0),
      Offset(39.5, 65.0),
      Offset(36.3, 67.0),
    ];
    final route11To19 = routeService.findRoute(
      startX: 27.0,
      startY: 34.5,
      destinationX: 36.3,
      destinationY: 67.0,
    );
    final route19To11 = routeService.findRoute(
      startX: 36.3,
      startY: 67.0,
      destinationX: 27.0,
      destinationY: 34.5,
    );

    expect(route11To19.points, expectedRoute);
    expect(route19To11.points, expectedRoute.reversed.toList());
  });

  test('fixed corridor destinations pass through markers 8 and 23', () {
    const start = Offset(75.0, 47.0);
    const waypoint8 = Offset(62.0, 47.5);
    const waypoint23 = Offset(44.0, 50.0);
    const destinations = <Offset>[
      Offset(49.0, 75.0),
      Offset(38.8, 78.0),
      Offset(42.0, 85.5),
      Offset(45.0, 86.0),
      Offset(48.7, 83.0),
      Offset(36.3, 67.0),
      Offset(36.8, 69.0),
      Offset(39.0, 68.4),
      Offset(39.0, 71.4),
    ];

    for (final destination in destinations) {
      final route = routeService.findRoute(
        startX: start.dx,
        startY: start.dy,
        destinationX: destination.dx,
        destinationY: destination.dy,
      );

      expect(route.points, [start, waypoint8, waypoint23, destination]);
    }
  });

  test('fixed via 23 combinations use the exact clinic waypoint', () {
    const waypoint23 = Offset(44.0, 50.0);
    const starts = <Offset>[
      Offset(45.0, 86.0),
      Offset(38.8, 78.0),
      Offset(42.0, 85.5),
      Offset(48.7, 83.0),
      Offset(36.3, 67.0),
      Offset(36.8, 69.0),
      Offset(39.0, 68.4),
      Offset(39.0, 71.4),
    ];
    const destinations = <Offset>[
      Offset(62.0, 47.5),
      Offset(75.0, 47.0),
      Offset(70.0, 40.0),
      Offset(78.0, 34.0),
      Offset(83.0, 33.5),
    ];

    for (final start in starts) {
      for (final destination in destinations) {
        final route = routeService.findRoute(
          startX: start.dx,
          startY: start.dy,
          destinationX: destination.dx,
          destinationY: destination.dy,
        );

        expect(route.points, [start, waypoint23, destination]);
      }
    }
  });

  test('markers 27 and 8 follow the marked walkway both ways', () {
    const expectedRoute = <Offset>[
      Offset(70.0, 40.0),
      Offset(62.0, 47.5),
    ];
    final route27To8 = routeService.findRoute(
      startX: 70.0,
      startY: 40.0,
      destinationX: 62.0,
      destinationY: 47.5,
    );
    final route8To27 = routeService.findRoute(
      startX: 62.0,
      startY: 47.5,
      destinationX: 70.0,
      destinationY: 40.0,
    );

    expect(route27To8.points, expectedRoute);
    expect(route8To27.points, expectedRoute.reversed.toList());
  });

  test('markers 2 and 22 follow the marked route both ways', () {
    const expectedRoute = <Offset>[
      Offset(67.0, 25.5),
      Offset(64.5, 27.0),
      Offset(63.0, 29.0),
      Offset(62.0, 32.0),
      Offset(61.0, 35.0),
      Offset(60.0, 38.5),
      Offset(59.0, 42.0),
      Offset(58.0, 45.5),
      Offset(57.0, 49.0),
      Offset(55.0, 52.0),
      Offset(52.0, 54.0),
      Offset(48.0, 55.0),
      Offset(44.0, 55.0),
      Offset(40.0, 53.0),
      Offset(35.0, 49.0),
      Offset(29.5, 45.5),
    ];
    final route2To22 = routeService.findRoute(
      startX: 67.0,
      startY: 25.5,
      destinationX: 29.5,
      destinationY: 45.5,
    );
    final route22To2 = routeService.findRoute(
      startX: 29.5,
      startY: 45.5,
      destinationX: 67.0,
      destinationY: 25.5,
    );

    expect(route2To22.points, expectedRoute);
    expect(route22To2.points, expectedRoute.reversed.toList());
  });

  test('markers 4 and 3 follow the marked route both ways', () {
    const expectedRoute = <Offset>[
      Offset(54.0, 29.5),
      Offset(61.5, 29.5),
    ];
    final route4To3 = routeService.findRoute(
      startX: 54.0,
      startY: 29.5,
      destinationX: 61.5,
      destinationY: 29.5,
    );
    final route3To4 = routeService.findRoute(
      startX: 61.5,
      startY: 29.5,
      destinationX: 54.0,
      destinationY: 29.5,
    );

    expect(route4To3.points, expectedRoute);
    expect(route3To4.points, expectedRoute.reversed.toList());
  });

  test('start 32 uses the fixed 31 to 30 corridor', () {
    const start = Offset(32.0, 7.5);
    const waypoint31 = Offset(32.5, 13.0);
    const continuation1 = Offset(34.0, 16.0);
    const continuation2 = Offset(38.0, 18.0);
    const destinations = <Offset>[
      Offset(53.0, 20.4),
      Offset(67.0, 25.5),
      Offset(83.0, 33.5),
      Offset(62.0, 47.5),
    ];

    for (final destination in destinations) {
      final route = routeService.findRoute(
        startX: start.dx,
        startY: start.dy,
        destinationX: destination.dx,
        destinationY: destination.dy,
      );

      expect(
        route.points.take(5),
        [start, waypoint31, continuation1, continuation2, route.points[4]],
      );
      expect(route.points.last, destination);
    }
  });

  test('start 32 reaches destination 2 through marker 1', () {
    final route = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 67.0,
      destinationY: 25.5,
    );

    expect(
      route.points,
      [
        const Offset(32.0, 7.5),
        const Offset(32.5, 13.0),
        const Offset(34.0, 16.0),
        const Offset(38.0, 18.0),
        const Offset(53.0, 20.4),
        const Offset(67.0, 25.5),
      ],
    );

    final routeToBuilding1 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 53.0,
      destinationY: 20.4,
    );
    expect(routeToBuilding1.points.last, const Offset(53.0, 20.4));
    expect(routeToBuilding1.points, isNot(contains(const Offset(67.0, 25.5))));
  });

  test('route between markers 32 and 4 follows the marked corridor both ways',
      () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(38.0, 22.0),
      Offset(42.0, 26.0),
      Offset(46.0, 29.0),
      Offset(50.0, 31.0),
      Offset(54.0, 29.5),
    ];

    final route32To4 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 54.0,
      destinationY: 29.5,
    );
    final route4To32 = routeService.findRoute(
      startX: 54.0,
      startY: 29.5,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To4.points, expectedRoute);
    expect(route4To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 29 follow the marked white corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(38.0, 22.0),
      Offset(42.0, 26.0),
      Offset(46.0, 29.0),
      Offset(48.0, 29.0),
    ];
    final route32To29 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 48.0,
      destinationY: 29.0,
    );
    final route29To32 = routeService.findRoute(
      startX: 48.0,
      startY: 29.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To29.points, expectedRoute);
    expect(route29To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 3 follow the marked white corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(38.0, 22.0),
      Offset(42.0, 26.0),
      Offset(46.0, 29.0),
      Offset(50.0, 31.0),
      Offset(54.0, 29.5),
      Offset(58.0, 29.0),
      Offset(61.5, 29.5),
    ];
    final route32To3 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 61.5,
      destinationY: 29.5,
    );
    final route3To32 = routeService.findRoute(
      startX: 61.5,
      startY: 29.5,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To3.points, expectedRoute);
    expect(route3To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 5 follow the marked white corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(38.0, 22.0),
      Offset(42.0, 26.0),
      Offset(46.0, 29.0),
      Offset(50.0, 31.0),
      Offset(54.0, 32.0),
      Offset(59.4, 35.0),
    ];
    final route32To5 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 59.4,
      destinationY: 35.0,
    );
    final route5To32 = routeService.findRoute(
      startX: 59.4,
      startY: 35.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To5.points, expectedRoute);
    expect(route5To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 9 follow the marked white corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(31.2, 11.0),
      Offset(31.0, 15.0),
      Offset(31.7, 19.0),
      Offset(32.7, 23.0),
      Offset(34.0, 27.0),
      Offset(35.7, 31.0),
      Offset(38.0, 35.0),
      Offset(41.0, 39.0),
      Offset(45.2, 43.0),
    ];
    final route32To9 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 45.2,
      destinationY: 43.0,
    );
    final route9To32 = routeService.findRoute(
      startX: 45.2,
      startY: 43.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To9.points, expectedRoute);
    expect(route9To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 28 follow the marked white corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(36.0, 21.0),
      Offset(38.0, 25.0),
      Offset(39.0, 28.0),
      Offset(41.0, 30.0),
      Offset(43.0, 32.0),
      Offset(45.0, 33.0),
      Offset(47.0, 35.0),
      Offset(49.0, 38.0),
      Offset(51.0, 40.0),
      Offset(54.0, 42.5),
    ];
    final route32To28 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 54.0,
      destinationY: 42.5,
    );
    final route28To32 = routeService.findRoute(
      startX: 54.0,
      startY: 42.5,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To28.points, expectedRoute);
    expect(route28To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 7 follow the marked white corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(38.0, 22.0),
      Offset(42.0, 26.0),
      Offset(46.0, 29.0),
      Offset(50.0, 31.0),
      Offset(54.0, 33.0),
      Offset(58.0, 35.0),
      Offset(62.0, 37.5),
      Offset(66.0, 40.0),
      Offset(70.0, 42.5),
      Offset(75.0, 47.0),
    ];
    final route32To7 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 75.0,
      destinationY: 47.0,
    );
    final route7To32 = routeService.findRoute(
      startX: 75.0,
      startY: 47.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To7.points, expectedRoute);
    expect(route7To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 27 follow the marked white corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(38.0, 22.0),
      Offset(42.0, 26.0),
      Offset(46.0, 29.0),
      Offset(50.0, 31.0),
      Offset(54.0, 33.0),
      Offset(58.0, 35.0),
      Offset(62.0, 37.5),
      Offset(66.0, 39.0),
      Offset(70.0, 40.0),
    ];
    final route32To27 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 70.0,
      destinationY: 40.0,
    );
    final route27To32 = routeService.findRoute(
      startX: 70.0,
      startY: 40.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To27.points, expectedRoute);
    expect(route27To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 6 follow the marked white corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(38.0, 22.0),
      Offset(42.0, 26.0),
      Offset(46.0, 29.0),
      Offset(50.0, 31.0),
      Offset(54.0, 33.0),
      Offset(58.0, 34.0),
      Offset(62.0, 35.0),
      Offset(67.0, 36.0),
      Offset(72.0, 37.0),
      Offset(76.0, 38.0),
      Offset(80.3, 40.0),
    ];
    final route32To6 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 80.3,
      destinationY: 40.0,
    );
    final route6To32 = routeService.findRoute(
      startX: 80.3,
      startY: 40.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To6.points, expectedRoute);
    expect(route6To32.points, expectedRoute.reversed.toList());
  });

  test('markers 31 and 32 use the direct marked segment both ways', () {
    final route32To31 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 32.5,
      destinationY: 13.0,
    );
    final route31To32 = routeService.findRoute(
      startX: 32.5,
      startY: 13.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(
      route32To31.points,
      [const Offset(32.0, 7.5), const Offset(32.5, 13.0)],
    );
    expect(route31To32.points, route32To31.points.reversed.toList());
  });

  test('markers 31 and 30 follow the marked corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.5, 13.0),
      Offset(32.5, 15.0),
      Offset(33.0, 16.5),
      Offset(35.0, 17.5),
      Offset(37.5, 18.0),
      Offset(40.0, 18.0),
    ];
    final route31To30 = routeService.findRoute(
      startX: 32.5,
      startY: 13.0,
      destinationX: 40.0,
      destinationY: 18.0,
    );
    final route30To31 = routeService.findRoute(
      startX: 40.0,
      startY: 18.0,
      destinationX: 32.5,
      destinationY: 13.0,
    );

    expect(route31To30.points, expectedRoute);
    expect(route30To31.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 30 follow the combined marked corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(31.5, 10.5),
      Offset(32.5, 13.0),
      Offset(32.5, 15.0),
      Offset(33.0, 16.5),
      Offset(34.0, 17.0),
      Offset(35.0, 17.5),
      Offset(37.5, 18.0),
      Offset(40.0, 18.0),
    ];
    final route32To30 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 40.0,
      destinationY: 18.0,
    );
    final route30To32 = routeService.findRoute(
      startX: 40.0,
      startY: 18.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To30.points, expectedRoute);
    expect(route30To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 12 follow the marked corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(30.5, 8.0),
      Offset(30.5, 11.5),
      Offset(31.0, 14.0),
      Offset(32.5, 17.0),
      Offset(33.0, 20.0),
      Offset(33.5, 23.0),
      Offset(33.5, 25.5),
      Offset(32.0, 26.0),
      Offset(29.0, 26.0),
      Offset(26.5, 25.5),
      Offset(24.8, 24.0),
    ];
    final route32To12 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 24.8,
      destinationY: 24.0,
    );
    final route12To32 = routeService.findRoute(
      startX: 24.8,
      startY: 24.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To12.points, expectedRoute);
    expect(route12To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 35 follow the marked corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(31.2, 11.0),
      Offset(31.0, 15.0),
      Offset(31.7, 19.0),
      Offset(32.2, 23.0),
      Offset(32.7, 26.5),
      Offset(33.5, 29.0),
      Offset(33.4, 29.7),
      Offset(31.5, 30.5),
      Offset(28.5, 31.2),
      Offset(25.5, 31.4),
      Offset(23.0, 31.0),
      Offset(21.5, 29.8),
      Offset(21.0, 29.0),
    ];
    final route32To35 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 21.0,
      destinationY: 29.0,
    );
    final route35To32 = routeService.findRoute(
      startX: 21.0,
      startY: 29.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To35.points, expectedRoute);
    expect(route35To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 15 follow the marked corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(31.5, 17.0),
      Offset(32.5, 22.0),
      Offset(34.0, 30.0),
      Offset(35.0, 40.0),
      Offset(36.0, 50.0),
      Offset(37.0, 60.0),
      Offset(40.0, 68.0),
      Offset(40.0, 73.0),
      Offset(38.8, 78.0),
    ];
    final route32To15 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 38.8,
      destinationY: 78.0,
    );
    final route15To32 = routeService.findRoute(
      startX: 38.8,
      startY: 78.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To15.points, expectedRoute);
    expect(route15To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 11 follow the marked corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(30.5, 8.5),
      Offset(30.8, 11.5),
      Offset(31.2, 15.0),
      Offset(31.8, 19.0),
      Offset(32.4, 23.0),
      Offset(33.0, 27.0),
      Offset(33.5, 31.0),
      Offset(34.0, 34.0),
      Offset(32.0, 34.5),
      Offset(27.0, 34.5),
    ];
    final route32To11 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 27.0,
      destinationY: 34.5,
    );
    final route11To32 = routeService.findRoute(
      startX: 27.0,
      startY: 34.5,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To11.points, expectedRoute);
    expect(route11To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 10 follow the same marked corridor as 32 and 11', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(30.5, 8.5),
      Offset(30.8, 11.5),
      Offset(31.2, 15.0),
      Offset(31.8, 19.0),
      Offset(32.4, 23.0),
      Offset(33.0, 27.0),
      Offset(33.5, 31.0),
      Offset(34.0, 34.0),
      Offset(32.0, 34.5),
      Offset(31.5, 34.0),
    ];
    final route32To10 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 31.5,
      destinationY: 34.0,
    );
    final route10To32 = routeService.findRoute(
      startX: 31.5,
      startY: 34.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To10.points, expectedRoute);
    expect(route10To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 22 follow the marked west-side corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(35.0, 22.0),
      Offset(36.0, 27.0),
      Offset(37.0, 32.0),
      Offset(38.0, 37.0),
      Offset(39.0, 42.0),
      Offset(38.0, 46.0),
      Offset(35.0, 47.0),
      Offset(32.0, 46.5),
      Offset(29.5, 45.5),
    ];
    final route32To22 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 29.5,
      destinationY: 45.5,
    );
    final route22To32 = routeService.findRoute(
      startX: 29.5,
      startY: 45.5,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To22.points, expectedRoute);
    expect(route22To32.points, expectedRoute.reversed.toList());
    expect(
      route32To22.points.every(
        (point) =>
            point.dx >= 0 &&
            point.dx <= 100 &&
            point.dy >= 0 &&
            point.dy <= 100,
      ),
      isTrue,
    );
  });

  test('markers 32 and 21 follow the same west-side corridor both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(34.0, 17.0),
      Offset(35.0, 22.0),
      Offset(36.0, 27.0),
      Offset(37.0, 32.0),
      Offset(38.0, 37.0),
      Offset(39.0, 42.0),
      Offset(38.0, 46.0),
      Offset(35.0, 47.0),
      Offset(32.0, 46.5),
      Offset(32.0, 49.2),
    ];
    final route32To21 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 32.0,
      destinationY: 49.2,
    );
    final route21To32 = routeService.findRoute(
      startX: 32.0,
      startY: 49.2,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To21.points, expectedRoute);
    expect(route21To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 19 follow the marked west walkway both ways', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(34.0, 14.0),
      Offset(35.0, 22.0),
      Offset(37.0, 30.0),
      Offset(38.0, 38.0),
      Offset(40.0, 46.0),
      Offset(41.0, 54.0),
      Offset(41.0, 59.0),
      Offset(36.3, 67.0),
    ];
    final route32To19 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 36.3,
      destinationY: 67.0,
    );
    final route19To32 = routeService.findRoute(
      startX: 36.3,
      startY: 67.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To19.points, expectedRoute);
    expect(route19To32.points, expectedRoute.reversed.toList());
    expect(
      expectedRoute.every(
        (point) =>
            point.dx >= 0 &&
            point.dx <= 100 &&
            point.dy >= 0 &&
            point.dy <= 100,
      ),
      isTrue,
    );
  });

  test('markers 32 and 18 follow the same alignment as marker 19', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(34.0, 14.0),
      Offset(35.0, 22.0),
      Offset(37.0, 30.0),
      Offset(38.0, 38.0),
      Offset(40.0, 46.0),
      Offset(41.0, 54.0),
      Offset(41.0, 59.0),
      Offset(39.0, 68.4),
    ];
    final route32To18 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 39.0,
      destinationY: 68.4,
    );
    final route18To32 = routeService.findRoute(
      startX: 39.0,
      startY: 68.4,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To18.points, expectedRoute);
    expect(route18To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 17 follow the same alignment as marker 19', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(34.0, 14.0),
      Offset(35.0, 22.0),
      Offset(37.0, 30.0),
      Offset(38.0, 38.0),
      Offset(40.0, 46.0),
      Offset(41.0, 54.0),
      Offset(41.0, 59.0),
      Offset(39.0, 71.4),
    ];
    final route32To17 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 39.0,
      destinationY: 71.4,
    );
    final route17To32 = routeService.findRoute(
      startX: 39.0,
      startY: 71.4,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To17.points, expectedRoute);
    expect(route17To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 20 follow the same alignment as marker 19', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(34.0, 14.0),
      Offset(35.0, 22.0),
      Offset(37.0, 30.0),
      Offset(38.0, 38.0),
      Offset(40.0, 46.0),
      Offset(41.0, 54.0),
      Offset(41.0, 59.0),
      Offset(36.8, 69.0),
    ];
    final route32To20 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 36.8,
      destinationY: 69.0,
    );
    final route20To32 = routeService.findRoute(
      startX: 36.8,
      startY: 69.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To20.points, expectedRoute);
    expect(route20To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 26 follow the in-map corridor in both directions', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(33.0, 13.0),
      Offset(34.0, 18.0),
      Offset(35.0, 20.5),
      Offset(38.0, 21.7),
      Offset(43.0, 21.3),
      Offset(48.0, 21.8),
      Offset(53.0, 22.7),
      Offset(58.0, 24.5),
      Offset(63.0, 26.5),
      Offset(68.0, 28.7),
      Offset(73.0, 31.0),
      Offset(78.0, 32.5),
      Offset(81.0, 33.2),
      Offset(83.0, 33.5),
    ];
    final route32To26 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 83.0,
      destinationY: 33.5,
    );
    final route26To32 = routeService.findRoute(
      startX: 83.0,
      startY: 33.5,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To26.points, expectedRoute);
    expect(route26To32.points, expectedRoute.reversed.toList());
    expect(
      expectedRoute.every(
        (point) =>
            point.dx >= 0 &&
            point.dx <= 100 &&
            point.dy >= 0 &&
            point.dy <= 100,
      ),
      isTrue,
    );
  });

  test('markers 32 and 25 follow the marked route in both directions', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(33.0, 13.0),
      Offset(34.0, 18.0),
      Offset(35.0, 20.5),
      Offset(38.0, 21.7),
      Offset(43.0, 21.3),
      Offset(48.0, 21.8),
      Offset(53.0, 22.7),
      Offset(58.0, 24.5),
      Offset(63.0, 26.5),
      Offset(68.0, 28.7),
      Offset(73.0, 31.0),
      Offset(76.0, 33.0),
      Offset(78.0, 34.0),
    ];
    final route32To25 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 78.0,
      destinationY: 34.0,
    );
    final route25To32 = routeService.findRoute(
      startX: 78.0,
      startY: 34.0,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To25.points, expectedRoute);
    expect(route25To32.points, expectedRoute.reversed.toList());
  });

  test('markers 32 and 8 follow the marked route in both directions', () {
    const expectedRoute = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(33.0, 18.0),
      Offset(34.0, 23.0),
      Offset(36.0, 28.0),
      Offset(39.0, 34.0),
      Offset(42.0, 40.0),
      Offset(45.0, 46.0),
      Offset(47.0, 50.0),
      Offset(53.0, 50.0),
      Offset(58.0, 49.0),
      Offset(62.0, 47.5),
    ];
    final route32To8 = routeService.findRoute(
      startX: 32.0,
      startY: 7.5,
      destinationX: 62.0,
      destinationY: 47.5,
    );
    final route8To32 = routeService.findRoute(
      startX: 62.0,
      startY: 47.5,
      destinationX: 32.0,
      destinationY: 7.5,
    );

    expect(route32To8.points, expectedRoute);
    expect(route8To32.points, expectedRoute.reversed.toList());
    expect(
      expectedRoute.every(
        (point) =>
            point.dx >= 0 &&
            point.dx <= 100 &&
            point.dy >= 0 &&
            point.dy <= 100,
      ),
      isTrue,
    );
  });

  test('start 32 uses the central south corridor for lower destinations', () {
    const corridor = <Offset>[
      Offset(32.0, 7.5),
      Offset(32.5, 13.0),
      Offset(38.0, 20.0),
      Offset(41.0, 39.0),
      Offset(40.0, 51.0),
      Offset(39.0, 69.0),
    ];
    const destinations = <Offset>[
      Offset(49.0, 75.0),
      Offset(42.0, 85.5),
      Offset(45.0, 86.0),
      Offset(48.7, 83.0),
    ];

    for (final destination in destinations) {
      final route = routeService.findRoute(
        startX: 32.0,
        startY: 7.5,
        destinationX: destination.dx,
        destinationY: destination.dy,
      );

      expect(route.points, [...corridor, destination]);
    }
  });

  test('start 32 uses the central-to-west corridor for west destinations', () {
    const start = Offset(32.0, 7.5);
    const waypoint31 = Offset(32.5, 13.0);
    const destinations = <Offset>[
      Offset(27.0, 34.5),
      Offset(31.5, 34.0),
      Offset(29.5, 45.5),
      Offset(32.0, 49.2),
    ];

    for (final destination in destinations) {
      final route = routeService.findRoute(
        startX: 32.0,
        startY: 7.5,
        destinationX: destination.dx,
        destinationY: destination.dy,
      );

      expect(route.points.first, start);
      expect(route.points[1], waypoint31);
      expect(route.points.last, destination);
      expect(route.points.length, lessThanOrEqualTo(8));
    }
  });

  test('blocked direct path uses a detour', () {
    final route = routeService.findRoute(
      startX: 31,
      startY: 32,
      destinationX: 71,
      destinationY: 37,
    );

    expect(route.points.length, greaterThan(2));
    expect(route.points.first.dx, 31);
    expect(route.points.last.dx, 71);
  });

  test('long routes use the campus path graph', () {
    final route = routeService.findRoute(
      startX: 21,
      startY: 29,
      destinationX: 49,
      destinationY: 75,
    );

    expect(route.points.length, greaterThan(2));
    expect(route.distanceMeters, greaterThan(0));
  });

  test('reverse direction remains supported', () {
    final route = routeService.findRoute(
      startX: 49,
      startY: 75,
      destinationX: 21,
      destinationY: 29,
    );

    expect(route.points.first.dx, 49);
    expect(route.points.first.dy, 75);
    expect(route.points.last.dx, 21);
    expect(route.points.last.dy, 29);
  });

  test('marker 32 to marker 1 follows the north campus corridor', () {
    final route = routeService.findRoute(
      startX: 32,
      startY: 7.5,
      destinationX: 53,
      destinationY: 20.4,
    );

    expect(route.points.first, const Offset(32, 7.5));
    expect(route.points.last, const Offset(53, 20.4));
    expect(route.points.length, greaterThan(2));
  });

  test('marker 1 to marker 32 preserves the reverse corridor', () {
    final route = routeService.findRoute(
      startX: 53,
      startY: 20.4,
      destinationX: 32,
      destinationY: 7.5,
    );

    expect(route.points.first, const Offset(53, 20.4));
    expect(route.points.last, const Offset(32, 7.5));
    expect(route.points.length, greaterThan(2));
  });

  test('marker 7 to marker 16 stays out of the east white void', () {
    final route = routeService.findRoute(
      startX: 75.0,
      startY: 47.0,
      destinationX: 48.7,
      destinationY: 83.0,
    );

    expect(route.points.first, const Offset(75.0, 47.0));
    expect(route.points.last, const Offset(48.7, 83.0));
    expect(route.points.length, greaterThan(2));
    expect(
      route.points
          .where((point) => point.dx > 58 && point.dy > 52 && point.dy < 75),
      isEmpty,
    );
  });

  test('marker 16 to marker 7 stays out of the east white void', () {
    final route = routeService.findRoute(
      startX: 48.7,
      startY: 83.0,
      destinationX: 75.0,
      destinationY: 47.0,
    );

    expect(route.points.first, const Offset(48.7, 83.0));
    expect(route.points.last, const Offset(75.0, 47.0));
    expect(route.points.length, greaterThan(2));
    expect(
      route.points
          .where((point) => point.dx > 58 && point.dy > 52 && point.dy < 75),
      isEmpty,
    );
  });

  test('all campus location pairs produce bounded routes', () {
    for (final start in campusLocations) {
      for (final destination in campusLocations) {
        if (start.number == destination.number) {
          continue;
        }
        final route = routeService.findRoute(
          startX: start.x!,
          startY: start.y!,
          destinationX: destination.x!,
          destinationY: destination.y!,
        );

        expect(route.points.first.dx, start.x!);
        expect(route.points.first.dy, start.y!);
        expect(route.points.last.dx, destination.x!);
        expect(route.points.last.dy, destination.y!);
        expect(route.points.length, greaterThanOrEqualTo(2));
        expect(route.distanceMeters, greaterThan(0));
        final dx = destination.x! - start.x!;
        final dy = destination.y! - start.y!;
        if ((dx * dx + dy * dy) > 24 * 24) {
          expect(
            route.points.length,
            greaterThan(2),
            reason: '${start.number} -> ${destination.number}',
          );
        }
      }
    }
  });
}
