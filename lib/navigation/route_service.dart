import 'dart:math' as math;
import 'dart:ui';

import 'campus_graph.dart';

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.walkingMinutes,
  });

  final List<Offset> points;
  final double distanceMeters;
  final double walkingMinutes;
}

class RouteService {
  const RouteService();

  // =====================================================
  // MANUAL ROUTES - EDIT THESE POINTS TO ALIGN THE LINE
  // =====================================================
  static const manualRoute7To13 = <Offset>[
    Offset(75.0, 47.0), // #7 Honasan Hall
    Offset(62.0, 47.5), // #8 Nursing Bldg. 2
    Offset(44.0, 50.0), // #23 University Clinic
    Offset(49.0, 75.0), // #13 Gymnasium
  ];

  // =====================================================
  // FIXED ROUTE CORRIDOR
  // Destinations that must pass through #8 -> #23
  // =====================================================
  static const _fixedRouteCorridorDestinations = <int>{
    13,
    15,
    34,
    14,
    16,
    19,
    20,
    18,
    17,
  };

  static const _fixedRouteCorridorCoordinates = <int, Offset>{
    13: Offset(49.0, 75.0),
    15: Offset(38.8, 78.0),
    34: Offset(42.0, 85.5),
    14: Offset(45.0, 86.0),
    16: Offset(48.7, 83.0),
    19: Offset(36.3, 67.0),
    20: Offset(36.8, 69.0),
    18: Offset(39.0, 68.4),
    17: Offset(39.0, 71.4),
  };

  static const _fixedRouteCorridorWaypoint8 = Offset(62.0, 47.5);
  static const _fixedRouteCorridorWaypoint23 = Offset(44.0, 50.0);

  // =====================================================
  // FIXED ROUTE VIA #23
  // Starts from #14/#15/#34/#16/#19/#20/#18/#17
  // and destinations #8/#7/#6/#27/#28/#25/#26
  // =====================================================
  static const _fixedRouteVia23StartNumbers = <int>{
    14,
    15,
    34,
    16,
    19,
    20,
    18,
    17,
  };

  static const _fixedRouteVia23DestinationNumbers = <int>{
    8,
    7,
    6,
    27,
    28,
    25,
    26,
  };

  static const _fixedRouteVia23StartCoordinates = <int, Offset>{
    14: Offset(45.0, 86.0),
    15: Offset(38.8, 78.0),
    34: Offset(42.0, 85.5),
    16: Offset(48.7, 83.0),
    19: Offset(36.3, 67.0),
    20: Offset(36.8, 69.0),
    18: Offset(39.0, 68.4),
    17: Offset(39.0, 71.4),
  };

  static const _fixedRouteVia23DestinationCoordinates = <int, Offset>{
    8: Offset(62.0, 47.5),
    7: Offset(75.0, 47.0),
    6: Offset(80.3, 40.0),
    27: Offset(70.0, 40.0),
    28: Offset(54.0, 42.5),
    25: Offset(78.0, 34.0),
    26: Offset(83.0, 33.5),
  };

  static const _specialRoute27To8 = <Offset>[
    Offset(70.0, 40.0),
    Offset(62.0, 47.5),
  ];

  static const _specialRoute2To22 = <Offset>[
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

  static const _specialRoute4To3 = <Offset>[
    Offset(54.0, 29.5),
    Offset(61.5, 29.5),
  ];

  static const _specialRoute1To25 = <Offset>[
    Offset(53.0, 20.4),
    Offset(58.0, 22.0),
    Offset(63.0, 24.0),
    Offset(68.0, 26.0),
    Offset(72.0, 28.5),
    Offset(75.0, 31.0),
    Offset(78.0, 34.0),
  ];

  static const _specialRoute1To26 = <Offset>[
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

  static const _specialRoute29To13 = <Offset>[
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
  static const _specialRoute29To25 = <Offset>[
    Offset(48.0, 29.0),
    Offset(53.0, 27.5),
    Offset(58.0, 26.5),
    Offset(63.0, 27.5),
    Offset(68.0, 29.0),
    Offset(72.5, 31.5),
    Offset(75.5, 33.0),
    Offset(78.0, 34.0),
  ];
  static const _specialRoute29To26 = <Offset>[
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
  static const _specialRoute29To8 = <Offset>[
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

  static const _specialRoute11To13 = <Offset>[
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

  static const _specialRoute11To15 = <Offset>[
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

  static const _specialRoute11To19 = <Offset>[
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

  // =====================================================
  // START #32 ROUTE CORRIDOR
  // #32 -> #31 -> CONTINUE ALONG PATH -> DESTINATION
  // =====================================================
  static const _fixedRouteVia31To30Start = Offset(32.0, 7.5);
  static const _fixedRouteVia31To30Destinations = <int>{
    30,
    1,
    2,
    29,
    3,
    5,
    28,
    27,
    6,
    7,
    26,
    8,
  };

  static const _fixedRouteVia31To30Waypoint31 = Offset(32.5, 13.0);
  static const _fixedRouteVia31To30Destination = Offset(40.0, 18.0);
  static const _route31To30 = <Offset>[
    _fixedRouteVia31To30Waypoint31,
    Offset(32.5, 15.0),
    Offset(33.0, 16.5),
    Offset(35.0, 17.5),
    Offset(37.5, 18.0),
    _fixedRouteVia31To30Destination,
  ];
  static const _route32To30 = <Offset>[
    _fixedRouteVia31To30Start,
    Offset(31.5, 10.5),
    Offset(32.5, 13.0),
    Offset(32.5, 15.0),
    Offset(33.0, 16.5),
    Offset(34.0, 17.0),
    Offset(35.0, 17.5),
    Offset(37.5, 18.0),
    Offset(40.0, 18.0),
  ];
  static const _start32ContinuationWaypoints = <Offset>[
    Offset(34.0, 16.0),
    Offset(38.0, 18.0),
  ];

  // =====================================================
  // SPECIAL ROUTE: #32 -> #2 VIA #1
  // =====================================================
  static const _specialRoute32To2Destination = Offset(67.0, 25.5);
  static const _specialRoute32To2Via1 = Offset(53.0, 20.4);

  // =====================================================
  // MANUAL ROUTE: #32 <-> #4
  // Follows the marked central pedestrian corridor.
  // =====================================================
  static const _specialRoute32To4Destination = Offset(54.0, 29.5);
  static const _specialRoute32To4 = <Offset>[
    Offset(32.0, 7.5),
    Offset(32.5, 13.0),
    Offset(34.0, 17.0),
    Offset(38.0, 22.0),
    Offset(42.0, 26.0),
    Offset(46.0, 29.0),
    Offset(50.0, 31.0),
    Offset(54.0, 29.5),
  ];
  static const _specialRoute32To29 = <Offset>[
    Offset(32.0, 7.5),
    Offset(32.5, 13.0),
    Offset(34.0, 17.0),
    Offset(38.0, 22.0),
    Offset(42.0, 26.0),
    Offset(46.0, 29.0),
    Offset(48.0, 29.0),
  ];
  static const _specialRoute32To3 = <Offset>[
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
  static const _specialRoute32To5 = <Offset>[
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
  static const _specialRoute32To9 = <Offset>[
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
  static const _specialRoute32To28 = <Offset>[
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
  static const _specialRoute32To7 = <Offset>[
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
  static const _specialRoute32To27 = <Offset>[
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
  static const _specialRoute32To6 = <Offset>[
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

  // =====================================================
  // START #32 WEST ROUTE CORRIDOR
  // #32 -> #31 -> CENTRAL PATHWAY -> WEST PATHWAY -> DESTINATION
  // =====================================================
  static const _start32WestDestinations = <int>{
    11,
    10,
    22,
    21,
    12,
    35,
  };

  static const _start32WestDestinationCoordinates = <int, Offset>{
    11: Offset(27.0, 34.5),
    10: Offset(31.5, 34.0),
    22: Offset(29.5, 45.5),
    21: Offset(32.0, 49.2),
    12: Offset(24.8, 24.0),
    35: Offset(21.0, 29.0),
  };

  static const _specialRoute32To1 = <Offset>[
    Offset(32.0, 7.5),
    Offset(32.5, 13.0),
    Offset(34.0, 16.0),
    Offset(38.0, 18.0),
    Offset(42.0, 19.0),
    Offset(47.0, 19.5),
    Offset(53.0, 20.4),
  ];

  static const _specialRoute32To12 = <Offset>[
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

  static const _specialRoute32To35 = <Offset>[
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

  static const _specialRoute32To15 = <Offset>[
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

  static const _specialRoute32To11 = <Offset>[
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

  static const _specialRoute32To10 = <Offset>[
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

  static const _specialRoute32To22 = <Offset>[
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

  static const _specialRoute32To19 = <Offset>[
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

  static const _specialRoute32To18 = <Offset>[
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

  static const _specialRoute32To17 = <Offset>[
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

  static const _specialRoute32To20 = <Offset>[
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

  static const _specialRoute32To21 = <Offset>[
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

  static const _specialRoute32To26 = <Offset>[
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

  static const _specialRoute32To8 = <Offset>[
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

  static const _specialRoute32To25 = <Offset>[
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

  static const _start32WestCorridor = <Offset>[
    Offset(32.0, 7.5), // #32 - DO NOT CHANGE
    Offset(32.5, 13.0), // #31 - DO NOT CHANGE
  ];

  // =====================================================
  // START #32 ROUTE CORRIDOR
  // #32 -> #31 -> CENTRAL PATHWAY -> DESTINATION
  // =====================================================
  static const _start32SouthDestinations = <int>{
    13,
    19,
    20,
    18,
    17,
    15,
    34,
    14,
    16,
  };

  static const _start32SouthDestinationCoordinates = <int, Offset>{
    13: Offset(49.0, 75.0),
    19: Offset(36.3, 67.0),
    20: Offset(36.8, 69.0),
    18: Offset(39.0, 68.4),
    17: Offset(39.0, 71.4),
    15: Offset(38.8, 78.0),
    34: Offset(42.0, 85.5),
    14: Offset(45.0, 86.0),
    16: Offset(48.7, 83.0),
  };

  static const _start32SouthCorridor = <Offset>[
    Offset(32.0, 7.5), // #32 - DO NOT CHANGE
    Offset(32.5, 13.0), // #31 - DO NOT CHANGE
    Offset(38.0, 20.0), // Continue along the upper central pathway.
    Offset(41.0, 39.0), // Central pathway junction.
    Offset(40.0, 51.0), // Continue downward through the campus center.
    Offset(39.0, 69.0), // Lower central pathway before branching.
  ];
  static const _fixedRouteVia31To30DestinationCoordinates = <int, Offset>{
    30: Offset(40.0, 18.0),
    1: Offset(53.0, 20.4),
    2: Offset(67.0, 25.5),
    29: Offset(48.0, 29.0),
    3: Offset(61.5, 29.5),
    5: Offset(59.4, 35.0),
    28: Offset(54.0, 42.5),
    27: Offset(70.0, 40.0),
    6: Offset(80.3, 40.0),
    7: Offset(75.0, 47.0),
    26: Offset(83.0, 33.5),
    8: Offset(62.0, 47.5),
  };

  static const _nearbyRouteDistance = 20.0;
  static const _nearbyWaypointPadding = 2.0;
  static const _campusObstacles = <Rect>[
    Rect.fromLTRB(19, 22, 34, 36),
    Rect.fromLTRB(43, 24, 64, 32),
    Rect.fromLTRB(47, 40, 66, 52),
    Rect.fromLTRB(27, 56, 40, 72),
    Rect.fromLTRB(39, 74, 55, 91),
    Rect.fromLTRB(68, 43, 83, 58),
    // Open white area below the east wing is outside the walkable site plan.
    Rect.fromLTRB(58, 52, 92, 75),
  ];

  static const _campusBoundary = <Offset>[
    Offset(26, 0),
    Offset(36, 0),
    Offset(39, 12),
    Offset(48, 16),
    Offset(64, 13),
    Offset(89, 20),
    Offset(97, 29),
    Offset(94, 39),
    Offset(87, 41),
    Offset(88, 51),
    Offset(82, 56),
    Offset(88, 61),
    Offset(87, 69),
    Offset(64, 70),
    Offset(65, 79),
    Offset(60, 88),
    Offset(59, 96),
    Offset(53, 100),
    Offset(45, 100),
    Offset(37, 82),
    Offset(28, 64),
    Offset(22, 51),
    Offset(16, 39),
    Offset(9, 24),
    Offset(30, 17),
  ];

  RouteResult findRoute({
    required double startX,
    required double startY,
    required double destinationX,
    required double destinationY,
  }) {
    final start = Offset(startX, startY);
    final destination = Offset(destinationX, destinationY);
    final directDistance = _distance(start, destination);

    final manualPath = _specialRoute11To13For(start, destination) ??
        _specialRoute11To15For(start, destination) ??
        _specialRoute11To19For(start, destination) ??
        _specialRoute1To26For(start, destination) ??
        _specialRoute1To25For(start, destination) ??
        _specialRoute29To13For(start, destination) ??
        _specialRoute29To25For(start, destination) ??
        _specialRoute29To26For(start, destination) ??
        _specialRoute29To8For(start, destination) ??
        _specialRoute4To3For(start, destination) ??
        _specialRoute2To22For(start, destination) ??
        _specialRoute27To8For(start, destination) ??
        _specialStart32WhiteRouteFor(start, destination) ??
        _specialRoute32To29For(start, destination) ??
        _specialRoute32To3For(start, destination) ??
        _specialRoute32To5For(start, destination) ??
        _specialRoute32To9For(start, destination) ??
        _specialRoute32To28For(start, destination) ??
        _specialRoute32To7For(start, destination) ??
        _specialRoute32To27For(start, destination) ??
        _specialRoute32To6For(start, destination) ??
        _specialRoute31To32To30For(start, destination) ??
        _start1To2DirectFor(start, destination) ??
        _start32SouthRouteFor(start, destination) ??
        _fixedRouteVia23For(start, destination) ??
        _fixedRouteCorridorFor(start, destination) ??
        _manualRouteFor(start, destination) ??
        _specialRoute32To2For(start, destination) ??
        _specialRoute32To4For(start, destination) ??
        _start32WestRouteFor(start, destination) ??
        _start32RouteFor(start, destination);
    final nearbyPath = directDistance <= _nearbyRouteDistance
        ? _findNearbyPath(start, destination)
        : null;
    final preservesWaypoints = manualPath != null || nearbyPath == null;
    final routePoints = manualPath ??
        nearbyPath ??
        [
          start,
          ..._findWalkablePath(start, destination)
              .map((node) => Offset(node.x, node.y)),
          destination,
        ];

    final simplified = _simplifyRoute(
      routePoints,
      preserveGraphWaypoints: preservesWaypoints,
    );

    var totalDistance = 0.0;
    for (var i = 1; i < simplified.length; i++) {
      final previous = simplified[i - 1];
      final current = simplified[i];
      final dx = current.dx - previous.dx;
      final dy = current.dy - previous.dy;
      totalDistance += math.sqrt(dx * dx + dy * dy) * 7.0;
    }

    final walkingMinutes = totalDistance / 80.0;

    return RouteResult(
      points: simplified,
      distanceMeters: totalDistance,
      walkingMinutes: walkingMinutes,
    );
  }

  static List<Offset>? _specialStart32WhiteRouteFor(
    Offset start,
    Offset destination,
  ) {
    const marker1 = Offset(53.0, 20.4);
    if (start == marker1 && destination == _fixedRouteVia31To30Waypoint31) {
      final marker31Index =
          _specialRoute32To1.indexOf(_fixedRouteVia31To30Waypoint31);
      return _specialRoute32To1.sublist(marker31Index).reversed.toList();
    }
    if (start == _fixedRouteVia31To30Waypoint31 && destination == marker1) {
      final marker31Index =
          _specialRoute32To1.indexOf(_fixedRouteVia31To30Waypoint31);
      return _specialRoute32To1.sublist(marker31Index);
    }

    const routes = <List<Offset>>[
      _specialRoute32To1,
      _specialRoute32To12,
      _specialRoute32To35,
      _specialRoute32To15,
      _specialRoute32To11,
      _specialRoute32To10,
      _specialRoute32To22,
      _specialRoute32To19,
      _specialRoute32To18,
      _specialRoute32To17,
      _specialRoute32To20,
      _specialRoute32To21,
      _specialRoute32To26,
      _specialRoute32To8,
      _specialRoute32To25,
    ];
    for (final route in routes) {
      if (start == route.first && destination == route.last) {
        return route;
      }
      if (start == route.last && destination == route.first) {
        return route.reversed.toList();
      }
    }
    return null;
  }

  static List<Offset>? _specialRoute27To8For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute27To8.first &&
        destination == _specialRoute27To8.last) {
      return _specialRoute27To8;
    }
    if (start == _specialRoute27To8.last &&
        destination == _specialRoute27To8.first) {
      return _specialRoute27To8.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute2To22For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute2To22.first &&
        destination == _specialRoute2To22.last) {
      return _specialRoute2To22;
    }
    if (start == _specialRoute2To22.last &&
        destination == _specialRoute2To22.first) {
      return _specialRoute2To22.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute4To3For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute4To3.first &&
        destination == _specialRoute4To3.last) {
      return _specialRoute4To3;
    }
    if (start == _specialRoute4To3.last &&
        destination == _specialRoute4To3.first) {
      return _specialRoute4To3.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute29To13For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute29To13.first &&
        destination == _specialRoute29To13.last) {
      return _specialRoute29To13;
    }
    if (start == _specialRoute29To13.last &&
        destination == _specialRoute29To13.first) {
      return _specialRoute29To13.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute29To25For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute29To25.first &&
        destination == _specialRoute29To25.last) {
      return _specialRoute29To25;
    }
    if (start == _specialRoute29To25.last &&
        destination == _specialRoute29To25.first) {
      return _specialRoute29To25.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute29To26For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute29To26.first &&
        destination == _specialRoute29To26.last) {
      return _specialRoute29To26;
    }
    if (start == _specialRoute29To26.last &&
        destination == _specialRoute29To26.first) {
      return _specialRoute29To26.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute29To8For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute29To8.first &&
        destination == _specialRoute29To8.last) {
      return _specialRoute29To8;
    }
    if (start == _specialRoute29To8.last &&
        destination == _specialRoute29To8.first) {
      return _specialRoute29To8.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute1To25For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute1To25.first &&
        destination == _specialRoute1To25.last) {
      return _specialRoute1To25;
    }
    if (start == _specialRoute1To25.last &&
        destination == _specialRoute1To25.first) {
      return _specialRoute1To25.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute1To26For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute1To26.first &&
        destination == _specialRoute1To26.last) {
      return _specialRoute1To26;
    }
    if (start == _specialRoute1To26.last &&
        destination == _specialRoute1To26.first) {
      return _specialRoute1To26.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute11To13For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute11To13.first &&
        destination == _specialRoute11To13.last) {
      return _specialRoute11To13;
    }
    if (start == _specialRoute11To13.last &&
        destination == _specialRoute11To13.first) {
      return _specialRoute11To13.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute11To15For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute11To15.first &&
        destination == _specialRoute11To15.last) {
      return _specialRoute11To15;
    }
    if (start == _specialRoute11To15.last &&
        destination == _specialRoute11To15.first) {
      return _specialRoute11To15.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute11To19For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute11To19.first &&
        destination == _specialRoute11To19.last) {
      return _specialRoute11To19;
    }
    if (start == _specialRoute11To19.last &&
        destination == _specialRoute11To19.first) {
      return _specialRoute11To19.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute31To32To30For(
    Offset start,
    Offset destination,
  ) {
    if (start == _fixedRouteVia31To30Start &&
        destination == _fixedRouteVia31To30Waypoint31) {
      return [start, _fixedRouteVia31To30Waypoint31];
    }
    if (start == _fixedRouteVia31To30Waypoint31 &&
        destination == _fixedRouteVia31To30Start) {
      return [_fixedRouteVia31To30Waypoint31, _fixedRouteVia31To30Start];
    }
    if (start == _fixedRouteVia31To30Waypoint31 &&
        destination == _fixedRouteVia31To30Destination) {
      return _route31To30;
    }
    if (start == _fixedRouteVia31To30Destination &&
        destination == _fixedRouteVia31To30Waypoint31) {
      return _route31To30.reversed.toList();
    }
    if (start == _fixedRouteVia31To30Start &&
        destination == _fixedRouteVia31To30Destination) {
      return _route32To30;
    }
    if (start == _fixedRouteVia31To30Destination &&
        destination == _fixedRouteVia31To30Start) {
      return _route32To30.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _start1To2DirectFor(
    Offset start,
    Offset destination,
  ) {
    const building1 = Offset(53.0, 20.4);
    const building2 = Offset(67.0, 25.5);
    if (start != building1 || destination != building2) {
      return null;
    }

    return [start, destination];
  }

  static List<Offset>? _specialRoute32To2For(
    Offset start,
    Offset destination,
  ) {
    if (start != _fixedRouteVia31To30Start ||
        destination != _specialRoute32To2Destination) {
      return null;
    }

    return [
      start,
      _fixedRouteVia31To30Waypoint31,
      ..._start32ContinuationWaypoints,
      _specialRoute32To2Via1,
      destination,
    ];
  }

  static List<Offset>? _specialRoute32To4For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute32To4.first &&
        destination == _specialRoute32To4Destination) {
      return _specialRoute32To4;
    }
    if (start == _specialRoute32To4Destination &&
        destination == _specialRoute32To4.first) {
      return _specialRoute32To4.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute32To29For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute32To29.first &&
        destination == _specialRoute32To29.last) {
      return _specialRoute32To29;
    }
    if (start == _specialRoute32To29.last &&
        destination == _specialRoute32To29.first) {
      return _specialRoute32To29.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute32To3For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute32To3.first &&
        destination == _specialRoute32To3.last) {
      return _specialRoute32To3;
    }
    if (start == _specialRoute32To3.last &&
        destination == _specialRoute32To3.first) {
      return _specialRoute32To3.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute32To5For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute32To5.first &&
        destination == _specialRoute32To5.last) {
      return _specialRoute32To5;
    }
    if (start == _specialRoute32To5.last &&
        destination == _specialRoute32To5.first) {
      return _specialRoute32To5.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute32To9For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute32To9.first &&
        destination == _specialRoute32To9.last) {
      return _specialRoute32To9;
    }
    if (start == _specialRoute32To9.last &&
        destination == _specialRoute32To9.first) {
      return _specialRoute32To9.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute32To28For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute32To28.first &&
        destination == _specialRoute32To28.last) {
      return _specialRoute32To28;
    }
    if (start == _specialRoute32To28.last &&
        destination == _specialRoute32To28.first) {
      return _specialRoute32To28.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute32To7For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute32To7.first &&
        destination == _specialRoute32To7.last) {
      return _specialRoute32To7;
    }
    if (start == _specialRoute32To7.last &&
        destination == _specialRoute32To7.first) {
      return _specialRoute32To7.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute32To27For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute32To27.first &&
        destination == _specialRoute32To27.last) {
      return _specialRoute32To27;
    }
    if (start == _specialRoute32To27.last &&
        destination == _specialRoute32To27.first) {
      return _specialRoute32To27.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _specialRoute32To6For(
    Offset start,
    Offset destination,
  ) {
    if (start == _specialRoute32To6.first &&
        destination == _specialRoute32To6.last) {
      return _specialRoute32To6;
    }
    if (start == _specialRoute32To6.last &&
        destination == _specialRoute32To6.first) {
      return _specialRoute32To6.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _start32SouthRouteFor(
    Offset start,
    Offset destination,
  ) {
    if (start != _fixedRouteVia31To30Start) {
      return null;
    }

    final destinationNumber = _start32SouthDestinationCoordinates.entries
        .where((entry) => entry.value == destination)
        .map((entry) => entry.key)
        .firstWhere(
          _start32SouthDestinations.contains,
          orElse: () => -1,
        );
    if (destinationNumber == -1) {
      return null;
    }

    return [..._start32SouthCorridor, destination];
  }

  static List<Offset>? _start32WestRouteFor(
    Offset start,
    Offset destination,
  ) {
    if (start != _fixedRouteVia31To30Start) {
      return null;
    }

    final destinationNumber = _start32WestDestinationCoordinates.entries
        .where((entry) => entry.value == destination)
        .map((entry) => entry.key)
        .firstWhere(
          _start32WestDestinations.contains,
          orElse: () => -1,
        );
    if (destinationNumber == -1) {
      return null;
    }

    final route = [..._start32WestCorridor];
    final graphPoints =
        _findWalkablePath(_fixedRouteVia31To30Waypoint31, destination);
    route.addAll(graphPoints.map((node) => Offset(node.x, node.y)));
    route.add(destination);
    return route;
  }

  static List<Offset>? _start32RouteFor(
    Offset start,
    Offset destination,
  ) {
    if (start != _fixedRouteVia31To30Start) {
      return null;
    }

    final destinationNumber = _fixedRouteVia31To30DestinationCoordinates.entries
        .where((entry) => entry.value == destination)
        .map((entry) => entry.key)
        .firstWhere(
          _fixedRouteVia31To30Destinations.contains,
          orElse: () => -1,
        );
    if (destinationNumber == -1) {
      return null;
    }

    final route = <Offset>[
      start,
      _fixedRouteVia31To30Waypoint31,
      ..._start32ContinuationWaypoints,
    ];

    final graphPoints = _findWalkablePath(
      _start32ContinuationWaypoints.last,
      destination,
    );
    route.addAll(graphPoints.map((node) => Offset(node.x, node.y)));
    route.add(destination);
    return route;
  }

  static List<Offset>? _fixedRouteVia23For(
    Offset start,
    Offset destination,
  ) {
    final startNumber = _fixedRouteVia23StartCoordinates.entries
        .where((entry) => entry.value == start)
        .map((entry) => entry.key)
        .firstWhere(
          _fixedRouteVia23StartNumbers.contains,
          orElse: () => -1,
        );
    final destinationNumber = _fixedRouteVia23DestinationCoordinates.entries
        .where((entry) => entry.value == destination)
        .map((entry) => entry.key)
        .firstWhere(
          _fixedRouteVia23DestinationNumbers.contains,
          orElse: () => -1,
        );

    if (startNumber == -1 || destinationNumber == -1) {
      return null;
    }

    return [start, _fixedRouteCorridorWaypoint23, destination];
  }

  static List<Offset>? _fixedRouteCorridorFor(
    Offset start,
    Offset destination,
  ) {
    final destinationNumber = _fixedRouteCorridorCoordinates.entries
        .where((entry) => entry.value == destination)
        .map((entry) => entry.key)
        .firstWhere(
          _fixedRouteCorridorDestinations.contains,
          orElse: () => -1,
        );
    if (destinationNumber == -1) {
      return null;
    }

    return [
      start,
      _fixedRouteCorridorWaypoint8,
      _fixedRouteCorridorWaypoint23,
      _fixedRouteCorridorCoordinates[destinationNumber]!,
    ];
  }

  static List<Offset>? _manualRouteFor(
    Offset start,
    Offset destination,
  ) {
    final routeStart = manualRoute7To13.first;
    final routeEnd = manualRoute7To13.last;
    if (start == routeStart && destination == routeEnd) {
      return manualRoute7To13;
    }
    if (start == routeEnd && destination == routeStart) {
      return manualRoute7To13.reversed.toList();
    }
    return null;
  }

  static List<Offset>? _findNearbyPath(Offset start, Offset destination) {
    if (_isWalkableSegment(start, destination)) {
      return [start, destination];
    }

    final waypoints = <Offset>[];
    for (final obstacle in _campusObstacles) {
      final padded = obstacle.inflate(_nearbyWaypointPadding);
      waypoints.addAll([
        Offset(padded.left, padded.top),
        Offset(padded.right, padded.top),
        Offset(padded.left, padded.bottom),
        Offset(padded.right, padded.bottom),
      ]);
    }

    List<Offset>? bestPath;
    var bestDistance = double.infinity;

    void consider(List<Offset> candidate) {
      if (!_isWalkableRoute(candidate)) {
        return;
      }
      final distance = _routeDistance(candidate);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestPath = candidate;
      }
    }

    for (final waypoint in waypoints) {
      consider([start, waypoint, destination]);
    }
    for (final first in waypoints) {
      for (final second in waypoints) {
        if (first == second) {
          continue;
        }
        consider([start, first, second, destination]);
      }
    }

    return bestPath;
  }

  static bool _isWalkableRoute(List<Offset> points) {
    for (var index = 1; index < points.length; index++) {
      if (!_isWalkableSegment(points[index - 1], points[index])) {
        return false;
      }
    }
    return true;
  }

  static double _routeDistance(List<Offset> points) {
    var distance = 0.0;
    for (var index = 1; index < points.length; index++) {
      distance += _distance(points[index - 1], points[index]);
    }
    return distance;
  }

  static List<Offset> _simplifyRoute(
    List<Offset> points, {
    required bool preserveGraphWaypoints,
  }) {
    final distinct = <Offset>[];
    for (final point in points) {
      if (distinct.isEmpty || _distance(distinct.last, point) > 0.01) {
        distinct.add(point);
      }
    }

    if (distinct.length < 3 || preserveGraphWaypoints) {
      return distinct;
    }

    final simplified = <Offset>[distinct.first];
    for (var index = 1; index < distinct.length - 1; index++) {
      final previous = simplified.last;
      final current = distinct[index];
      final next = distinct[index + 1];
      final incoming = current - previous;
      final outgoing = next - current;
      final cross = incoming.dx * outgoing.dy - incoming.dy * outgoing.dx;
      final dot = incoming.dx * outgoing.dx + incoming.dy * outgoing.dy;
      final shortcutIsWalkable = _isWalkableSegment(previous, next);
      if (!shortcutIsWalkable || cross.abs() > 1.5 || dot < 0) {
        simplified.add(current);
      }
    }
    simplified.add(distinct.last);
    return simplified;
  }

  static List<CampusNode> _findWalkablePath(
    Offset start,
    Offset destination,
  ) {
    const nodes = CampusGraph.nodes;
    final index = {for (final node in nodes) node.id: node};
    final startCandidates = _walkableCandidates(start, nodes);
    final endCandidates = _walkableCandidates(destination, nodes);

    if (startCandidates.isEmpty || endCandidates.isEmpty) {
      return const <CampusNode>[];
    }

    List<CampusNode>? bestPath;
    var bestScore = double.infinity;
    for (final startCandidate in startCandidates) {
      for (final endCandidate in endCandidates) {
        final candidatePath = _findGraphPath(
          startCandidate,
          endCandidate,
          index,
        );
        if (candidatePath == null) {
          continue;
        }
        final score = _distance(
              start,
              Offset(startCandidate.x, startCandidate.y),
            ) +
            _distance(
              destination,
              Offset(endCandidate.x, endCandidate.y),
            ) +
            _pathDistance(candidatePath);
        if (score < bestScore) {
          bestScore = score;
          bestPath = candidatePath;
        }
      }
    }

    return bestPath ?? const <CampusNode>[];
  }

  static List<CampusNode> _walkableCandidates(
    Offset point,
    List<CampusNode> nodes,
  ) {
    final candidates = nodes.where((node) {
      return _isWalkableSegment(point, Offset(node.x, node.y));
    }).toList();
    candidates.sort((first, second) {
      final firstDistance = _distance(point, Offset(first.x, first.y));
      final secondDistance = _distance(point, Offset(second.x, second.y));
      return firstDistance.compareTo(secondDistance);
    });
    return candidates;
  }

  static List<CampusNode>? _findGraphPath(
    CampusNode startNode,
    CampusNode endNode,
    Map<String, CampusNode> index,
  ) {
    final openSet = <String>{startNode.id};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{startNode.id: 0};
    final fScore = <String, double>{
      startNode.id: _nodeDistance(startNode, endNode),
    };

    while (openSet.isNotEmpty) {
      var current = openSet.first;
      for (final candidate in openSet) {
        if ((fScore[candidate] ?? double.infinity) <
            (fScore[current] ?? double.infinity)) {
          current = candidate;
        }
      }
      if (current == endNode.id) {
        final path = <String>[current];
        while (cameFrom.containsKey(path.last)) {
          path.add(cameFrom[path.last]!);
        }
        return path.reversed.map((id) => index[id]!).toList();
      }

      openSet.remove(current);
      final currentNode = index[current]!;
      final neighborIds = <String>{...currentNode.connectedNodes};
      for (final node in index.values) {
        if (node.connectedNodes.contains(current)) {
          neighborIds.add(node.id);
        }
      }
      for (final neighborId in neighborIds) {
        final neighbor = index[neighborId]!;
        if (!_isWalkableSegment(
          Offset(currentNode.x, currentNode.y),
          Offset(neighbor.x, neighbor.y),
        )) {
          continue;
        }
        final tentative = (gScore[current] ?? double.infinity) +
            _nodeDistance(currentNode, neighbor);
        if (tentative < (gScore[neighborId] ?? double.infinity)) {
          cameFrom[neighborId] = current;
          gScore[neighborId] = tentative;
          fScore[neighborId] = tentative + _nodeDistance(neighbor, endNode);
          openSet.add(neighborId);
        }
      }
    }

    return null;
  }

  static double _nodeDistance(CampusNode first, CampusNode second) {
    return _distance(Offset(first.x, first.y), Offset(second.x, second.y));
  }

  static double _pathDistance(List<CampusNode> path) {
    var distance = 0.0;
    for (var index = 1; index < path.length; index++) {
      distance += _nodeDistance(path[index - 1], path[index]);
    }
    return distance;
  }

  static bool _isWalkableSegment(Offset start, Offset destination) {
    if (!_isInsideCampus(start) || !_isInsideCampus(destination)) {
      return false;
    }

    for (var step = 1; step < 10; step++) {
      final t = step / 10;
      final sample = Offset(
        start.dx + (destination.dx - start.dx) * t,
        start.dy + (destination.dy - start.dy) * t,
      );
      if (!_isInsideCampus(sample)) {
        return false;
      }
    }

    for (final obstacle in _campusObstacles) {
      final expanded = obstacle.inflate(1.5);
      final startInside = expanded.contains(start);
      final destinationInside = expanded.contains(destination);
      if (startInside && destinationInside) {
        return false;
      }
      if (startInside || destinationInside) {
        continue;
      }
      if (_segmentIntersectsRect(start, destination, expanded)) {
        return false;
      }
    }
    return true;
  }

  static bool _isInsideCampus(Offset point) {
    var inside = false;
    for (var index = 0, previous = _campusBoundary.length - 1;
        index < _campusBoundary.length;
        previous = index++) {
      final current = _campusBoundary[index];
      final prior = _campusBoundary[previous];
      final crosses = (current.dy > point.dy) != (prior.dy > point.dy) &&
          point.dx <
              (prior.dx - current.dx) *
                      (point.dy - current.dy) /
                      (prior.dy - current.dy) +
                  current.dx;
      if (crosses) {
        inside = !inside;
      }
    }
    return inside;
  }

  static bool _segmentIntersectsRect(
    Offset start,
    Offset end,
    Rect rectangle,
  ) {
    var tMin = 0.0;
    var tMax = 1.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    bool clip(double p, double q) {
      if (p == 0) {
        return q >= 0;
      }
      final ratio = q / p;
      if (p < 0) {
        if (ratio > tMax) return false;
        if (ratio > tMin) tMin = ratio;
      } else {
        if (ratio < tMin) return false;
        if (ratio < tMax) tMax = ratio;
      }
      return true;
    }

    return clip(-dx, start.dx - rectangle.left) &&
        clip(dx, rectangle.right - start.dx) &&
        clip(-dy, start.dy - rectangle.top) &&
        clip(dy, rectangle.bottom - start.dy);
  }

  static double _distance(Offset first, Offset second) {
    final dx = second.dx - first.dx;
    final dy = second.dy - first.dy;
    return math.sqrt(dx * dx + dy * dy);
  }
}
