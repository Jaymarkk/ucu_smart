import 'dart:math' as math;

class CampusNode {
  const CampusNode({
    required this.id,
    required this.x,
    required this.y,
    required this.connectedNodes,
  });

  final String id;
  final double x;
  final double y;
  final List<String> connectedNodes;
}

class CampusGraph {
  // Junctions sampled from the visible campus roads and pedestrian corridors.
  static const List<CampusNode> nodes = [
    CampusNode(id: 'north', x: 33, y: 7, connectedNodes: ['gate']),
    CampusNode(id: 'gate', x: 33, y: 14, connectedNodes: ['north', 'top']),
    CampusNode(
      id: 'top',
      x: 38,
      y: 20,
      connectedNodes: ['gate', 'westTop', 'eastUpper'],
    ),
    CampusNode(
      id: 'westTop',
      x: 35,
      y: 25,
      connectedNodes: ['top', 'westMid'],
    ),
    CampusNode(
      id: 'westMid',
      x: 30,
      y: 38,
      connectedNodes: ['westTop', 'westCenter'],
    ),
    CampusNode(
      id: 'westCenter',
      x: 40,
      y: 51,
      connectedNodes: ['westMid', 'center'],
    ),
    CampusNode(
      id: 'westSouth',
      x: 39,
      y: 69,
      connectedNodes: ['westCenter', 'southWest'],
    ),
    CampusNode(
      id: 'southWest',
      x: 45,
      y: 87,
      connectedNodes: ['westSouth', 'south'],
    ),
    CampusNode(id: 'south', x: 51, y: 97, connectedNodes: ['southWest']),
    CampusNode(
      id: 'center',
      x: 41,
      y: 39,
      connectedNodes: ['westCenter', 'top', 'upperCross', 'middle'],
    ),
    CampusNode(
      id: 'upperCross',
      x: 55,
      y: 39,
      connectedNodes: ['center', 'eastUpper', 'middle'],
    ),
    CampusNode(
      id: 'eastUpper',
      x: 70,
      y: 37,
      connectedNodes: ['upperCross', 'eastTip', 'eastMiddle'],
    ),
    CampusNode(
      id: 'eastTip',
      x: 88,
      y: 35,
      connectedNodes: ['eastUpper', 'eastMiddle'],
    ),
    CampusNode(
      id: 'eastMiddle',
      x: 80,
      y: 47,
      connectedNodes: ['eastUpper', 'eastTip', 'middle'],
    ),
    CampusNode(
      id: 'middle',
      x: 57,
      y: 47,
      connectedNodes: ['center', 'upperCross', 'eastMiddle', 'lowerCross'],
    ),
    CampusNode(
      id: 'lowerCross',
      x: 55,
      y: 61,
      connectedNodes: ['middle', 'southPath'],
    ),
    CampusNode(
      id: 'southPath',
      x: 48,
      y: 77,
      connectedNodes: ['lowerCross', 'southWest', 'south'],
    ),
  ];

  static final Map<String, CampusNode> _index = {
    for (final node in nodes) node.id: node,
  };

  static CampusNode findNearestNode(double x, double y) {
    var bestDistance = double.infinity;
    CampusNode nearest = nodes.first;

    for (final node in nodes) {
      final distance = math.sqrt(
        (node.x - x) * (node.x - x) + (node.y - y) * (node.y - y),
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = node;
      }
    }

    return nearest;
  }

  static CampusNode? nodeById(String id) => _index[id];

  static List<CampusNode>? findPathBetweenNodes({
    required String startNodeId,
    required String endNodeId,
  }) {
    final startNode = _index[startNodeId];
    final endNode = _index[endNodeId];
    if (startNode == null || endNode == null) return null;
    if (startNode.id == endNode.id) return [startNode];

    final openSet = <String>{startNode.id};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{startNode.id: 0.0};
    final fScore = <String, double>{
      startNode.id: _heuristic(startNode, endNode),
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
        return path.reversed.map((id) => _index[id]!).toList();
      }

      openSet.remove(current);
      final currentNode = _index[current]!;
      for (final neighborId in currentNode.connectedNodes) {
        final neighbor = _index[neighborId];
        if (neighbor == null) continue;
        final tentative = (gScore[current] ?? double.infinity) +
            _distance(currentNode, neighbor);
        if (tentative < (gScore[neighborId] ?? double.infinity)) {
          cameFrom[neighborId] = current;
          gScore[neighborId] = tentative;
          fScore[neighborId] = tentative + _heuristic(neighbor, endNode);
          openSet.add(neighborId);
        }
      }
    }

    return null;
  }

  static List<CampusNode> findPath(
    double startX,
    double startY,
    double endX,
    double endY,
  ) {
    final startNode = findNearestNode(startX, startY);
    final endNode = findNearestNode(endX, endY);

    if (startNode.id == endNode.id) {
      return [startNode];
    }

    final openSet = <String>{startNode.id};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{startNode.id: 0.0};
    final fScore = <String, double>{
      startNode.id: _heuristic(startNode, endNode),
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
        return path.reversed.map((id) => _index[id]!).toList();
      }

      openSet.remove(current);
      final currentNode = _index[current]!;
      for (final neighborId in currentNode.connectedNodes) {
        final neighbor = _index[neighborId]!;
        final tentative = (gScore[current] ?? double.infinity) +
            _distance(currentNode, neighbor);
        if (tentative < (gScore[neighborId] ?? double.infinity)) {
          cameFrom[neighborId] = current;
          gScore[neighborId] = tentative;
          fScore[neighborId] = tentative + _heuristic(neighbor, endNode);
          openSet.add(neighborId);
        }
      }
    }

    return [startNode, endNode];
  }

  static double _heuristic(CampusNode start, CampusNode end) {
    return math.sqrt(
      (start.x - end.x) * (start.x - end.x) +
          (start.y - end.y) * (start.y - end.y),
    );
  }

  static double _distance(CampusNode a, CampusNode b) {
    return math.sqrt(
      (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y),
    );
  }
}
