import 'dart:math' as math;
import 'dart:ui';

import 'campus_graph.dart';
import 'route_service.dart';

class DynamicBuildingRouteService {
  const DynamicBuildingRouteService();

  RouteResult? findRoute({
    required Offset start,
    required Offset destination,
    String? startRouteNodeId,
    bool startConnectionVerified = false,
    String? destinationRouteNodeId,
    bool destinationConnectionVerified = false,
  }) {
    final startIsDynamic = startRouteNodeId != null;
    final destinationIsDynamic = destinationRouteNodeId != null;
    if (!startIsDynamic && !destinationIsDynamic) return null;

    if (startIsDynamic &&
        (!startConnectionVerified ||
            CampusGraph.nodeById(startRouteNodeId) == null)) {
      return null;
    }
    if (destinationIsDynamic &&
        (!destinationConnectionVerified ||
            CampusGraph.nodeById(destinationRouteNodeId) == null)) {
      return null;
    }

    final points = <Offset>[];
    if (startIsDynamic && destinationIsDynamic) {
      final graphPath = CampusGraph.findPathBetweenNodes(
        startNodeId: startRouteNodeId,
        endNodeId: destinationRouteNodeId,
      );
      if (graphPath == null) return null;
      points
        ..add(start)
        ..addAll(graphPath.map((node) => Offset(node.x, node.y)))
        ..add(destination);
    } else if (destinationIsDynamic) {
      final node = CampusGraph.nodeById(destinationRouteNodeId)!;
      final existingPath = const RouteService().findRoute(
        startX: start.dx,
        startY: start.dy,
        destinationX: node.x,
        destinationY: node.y,
      );
      points
        ..addAll(existingPath.points)
        ..add(destination);
    } else {
      final node = CampusGraph.nodeById(startRouteNodeId!)!;
      final existingPath = const RouteService().findRoute(
        startX: node.x,
        startY: node.y,
        destinationX: destination.dx,
        destinationY: destination.dy,
      );
      points
        ..add(start)
        ..addAll(existingPath.points);
    }

    final compact = <Offset>[];
    for (final point in points) {
      if (compact.isEmpty || compact.last != point) compact.add(point);
    }
    return _toRouteResult(compact);
  }

  RouteResult _toRouteResult(List<Offset> points) {
    var mapDistance = 0.0;
    for (var index = 1; index < points.length; index++) {
      final delta = points[index] - points[index - 1];
      mapDistance += math.sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
    }
    final distanceMeters = mapDistance * 7.0;
    return RouteResult(
      points: points,
      distanceMeters: distanceMeters,
      walkingMinutes: distanceMeters / 80.0,
    );
  }
}
