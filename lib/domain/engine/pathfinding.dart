import 'dart:collection';
import 'dart:math';
import '../../data/models/city_state.dart';
import '../../data/models/tile.dart';

/// 市民エージェントが道路・歩行可能タイルの上だけを通って
/// 自宅⇔職場/余暇先を移動するためのA*経路探索。
///
/// 都市が大きくなるとコストが増えるため、呼び出し側
/// (CitizenSimulationEngine)で「経路は道路網変更時のみ再計算しキャッシュする」
/// 運用を必須とする。
class Pathfinder {
  final CityState city;
  Pathfinder(this.city);

  bool _inBounds(int x, int y) =>
      x >= 0 && y >= 0 && x < city.width && y < city.height;

  bool _walkable(int x, int y) {
    if (!_inBounds(x, y)) return false;
    return city.tileAt(x, y).type.isWalkable;
  }

  /// A*で start から goal までのタイル座標リストを返す。
  /// 到達不可能な場合は空リストを返す。
  List<Point<int>> findPath(Point<int> start, Point<int> goal) {
    if (!_walkable(goal.x, goal.y)) return const [];

    final open = HashSet<Point<int>>()..add(start);
    final cameFrom = <Point<int>, Point<int>>{};
    final gScore = <Point<int>, int>{start: 0};
    final fScore = <Point<int>, int>{start: _heuristic(start, goal)};

    int compareByF(Point<int> a, Point<int> b) =>
        (fScore[a] ?? 1 << 30).compareTo(fScore[b] ?? 1 << 30);

    while (open.isNotEmpty) {
      final current = open.reduce(
        (a, b) => compareByF(a, b) <= 0 ? a : b,
      );

      if (current == goal) {
        return _reconstructPath(cameFrom, current);
      }

      open.remove(current);

      for (final neighbor in _neighbors(current)) {
        final tentativeG = (gScore[current] ?? 1 << 30) + 1;
        if (tentativeG < (gScore[neighbor] ?? 1 << 30)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeG;
          fScore[neighbor] = tentativeG + _heuristic(neighbor, goal);
          open.add(neighbor);
        }
      }

      // 安全弁：極端に巨大な探索になった場合は打ち切り（60FPS維持のため）
      if (gScore.length > 4000) return const [];
    }
    return const []; // 到達不可能
  }

  List<Point<int>> _neighbors(Point<int> p) {
    const dirs = [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];
    final result = <Point<int>>[];
    for (final d in dirs) {
      final nx = p.x + d.x;
      final ny = p.y + d.y;
      if (_walkable(nx, ny)) result.add(Point(nx, ny));
    }
    return result;
  }

  int _heuristic(Point<int> a, Point<int> b) =>
      (a.x - b.x).abs() + (a.y - b.y).abs();

  List<Point<int>> _reconstructPath(
      Map<Point<int>, Point<int>> cameFrom, Point<int> current) {
    final path = <Point<int>>[current];
    var c = current;
    while (cameFrom.containsKey(c)) {
      c = cameFrom[c]!;
      path.add(c);
    }
    return path.reversed.toList();
  }
}
