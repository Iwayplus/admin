import 'dart:math';

import 'APIMODELS/waypoint.dart';

class Point2D {
  final int x;
  final int y;

  const Point2D(this.x, this.y);

  double distanceTo(Point2D other) {
    final dx = (x - other.x).toDouble();
    final dy = (y - other.y).toDouble();
    return sqrt(dx * dx + dy * dy);
  }

  Point2D interpolate(Point2D other, double t) {
    return Point2D(
      (x + (other.x - x) * t).round(),
      (y + (other.y - y) * t).round(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Point2D && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '$x,$y';

  static Point2D fromString(String s) {
    final parts = s.split(',');
    return Point2D(int.parse(parts[0]), int.parse(parts[1]));
  }

 static Map<String, Set<Point2D>> generateSampledPointsFromWaypointGraph(
      Map<String, List<PathModel>> waypoint,
      {double step = 10.0}) {
    final Map<String, Set<Point2D>> floorPoints = {};

    for (final floor in waypoint.keys) {
      final Set<Point2D> result = {};
      final visitedEdges = <String>{};
      for (final model in waypoint[floor]!) {
        final graph = model.pathNetwork;

        for (final sourceStr in graph.keys) {
          final source = Point2D.fromString(sourceStr);
          for (final targetStr in graph[sourceStr]!) {
            final target = Point2D.fromString(targetStr.toString());

            final edge = [sourceStr, targetStr]..sort();
            final edgeId = edge.join('->');
            if (visitedEdges.contains(edgeId)) continue;
            visitedEdges.add(edgeId);

            final dist = source.distanceTo(target);
            if (dist == 0) continue;

            final steps = (dist ~/ step);
            for (int i = 0; i <= steps; i++) {
              final t = (i * step) / dist;
              final pt = source.interpolate(target, t);
              result.add(pt);
            }
          }
        }
      }

      floorPoints[floor] = result;

    }

    return floorPoints;
  }
}



