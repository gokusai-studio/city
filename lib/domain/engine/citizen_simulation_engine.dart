import 'dart:math';
import 'dart:ui';
import '../../data/models/citizen.dart';
import '../../data/models/city_state.dart';
import '../../data/models/tile.dart';
import '../../core/utils/citizen_flavor_generator.dart';
import 'pathfinding.dart';

/// 「仮想の人々がリアルタイムに生活や営みを繰り返す」ための中核エンジン。
///
/// 設計方針（60FPS維持のためのスケーラビリティ対策）：
/// - 実際の統計人口（数万〜十万人）を1体ずつ動かすのではなく、
///   最大[maxVisibleAgents]体の「代表市民」のみを可視化・移動シミュレーションする。
/// - 代表市民1体 = およそ populationPerAgent 人分を象徴する。
/// - 経路探索は道路網が変化した時、または市民が新しい行き先を必要とした時のみ実行し、
///   結果はCitizen.currentPathにキャッシュする。
class CitizenSimulationEngine {
  final CityState city;
  final Pathfinder pathfinder;
  final Random _random = Random();

  final List<Citizen> citizens = [];

  static const int maxVisibleAgents = 120;
  static const int populationPerAgent = 500;

  /// 道路網に変更があった場合、呼び出し側からtrueにしてキャッシュ経路を破棄する
  bool roadNetworkDirty = true;

  /// 直近のupdate()で渡されたゲーム内時刻。履歴ログ記録用に保持しておく。
  double _lastGameTimeHours = 8.0;

  CitizenSimulationEngine(this.city) : pathfinder = Pathfinder(city);

  /// 現在の統計人口に応じて、代表エージェント数を増減させる。
  /// ゾーニングが変化した後（人口が増減した後）に呼び出す。
  void syncAgentCountWithPopulation() {
    final targetCount = min(
      maxVisibleAgents,
      (city.residentPopulation / populationPerAgent).ceil(),
    );

    while (citizens.length < targetCount) {
      final home = _randomTileOfType(TileType.residential);
      if (home == null) break; // 住宅がまだ無い
      citizens.add(_spawnCitizenAt(home));
    }
    while (citizens.length > targetCount) {
      citizens.removeLast();
    }

    if (roadNetworkDirty) {
      for (final c in citizens) {
        c.currentPath = const [];
        c.pathIndex = 0;
      }
      roadNetworkDirty = false;
    }
  }

  Citizen _spawnCitizenAt(Point<int> home) {
    final work = _randomTileOfType(TileType.commercial) ??
        _randomTileOfType(TileType.landmark);
    final leisure =
        _randomTileOfType(TileType.park) ?? _randomTileOfType(TileType.landmark);

    final workTileType =
        work != null ? city.tileAt(work.x, work.y).type : null;
    final profile = CitizenFlavorGenerator.generateProfile(workTileType: workTileType);

    return Citizen(
      id: 'citizen_${_random.nextInt(1 << 32)}',
      name: profile['name']!,
      age: int.parse(profile['age']!),
      job: profile['job']!,
      storyline: profile['storyline']!,
      homeTile: home,
      workTile: work,
      leisureTile: leisure,
    )..logEvent(_lastGameTimeHours, CitizenState.atHome, home);
  }

  /// スクリーン座標に最も近い市民を探す（タップ判定用）。
  /// [maxDistanceTiles] を超える距離の場合はnullを返す。
  Citizen? findCitizenNear(Offset tilePosition, {double maxDistanceTiles = 0.6}) {
    Citizen? closest;
    double closestDist = double.infinity;
    for (final c in citizens) {
      final dist = (c.position - tilePosition).distance;
      if (dist < closestDist) {
        closestDist = dist;
        closest = c;
      }
    }
    if (closest != null && closestDist <= maxDistanceTiles) return closest;
    return null;
  }

  Point<int>? _randomTileOfType(TileType type) {
    final candidates =
        city.tiles.where((t) => t.type == type).toList(growable: false);
    if (candidates.isEmpty) return null;
    final t = candidates[_random.nextInt(candidates.length)];
    return Point(t.x, t.y);
  }

  /// メインゲームループから毎フレーム呼ばれる更新処理。
  /// [realDtSeconds] : 実時間の経過秒数（描画フレーム間隔）
  /// [gameTimeHours] : 現在のゲーム内時刻（0.0-24.0を超えて加算され続ける）
  void update(double realDtSeconds, double gameTimeHours) {
    _lastGameTimeHours = gameTimeHours;
    for (final citizen in citizens) {
      _updateSchedule(citizen, gameTimeHours);
      _updateMovement(citizen, realDtSeconds);
    }
  }

  /// 時刻とスケジュールジッターから「今この市民が何をすべきか」を決め、
  /// 現在の状態と食い違っていれば移動を開始する。
  void _updateSchedule(Citizen citizen, double gameTimeHours) {
    final localHour = (gameTimeHours + citizen.scheduleJitter * 2.0) % 24.0;

    final wantsWork = localHour >= 7.0 && localHour < 17.0;
    final wantsLeisure = localHour >= 18.0 && localHour < 22.0;
    // それ以外（深夜〜早朝）は帰宅・在宅

    switch (citizen.state) {
      case CitizenState.atHome:
        if (wantsWork && citizen.workTile != null) {
          _beginCommute(citizen, citizen.workTile!, CitizenState.commutingToWork);
        } else if (wantsLeisure && citizen.leisureTile != null && _random.nextDouble() < 0.02) {
          _beginCommute(citizen, citizen.leisureTile!, CitizenState.commutingToLeisure);
        }
        break;
      case CitizenState.atWork:
        if (!wantsWork) {
          if (wantsLeisure && citizen.leisureTile != null && _random.nextDouble() < 0.3) {
            _beginCommute(citizen, citizen.leisureTile!, CitizenState.commutingToLeisure);
          } else {
            _beginCommute(citizen, citizen.homeTile, CitizenState.commutingHome);
          }
        }
        break;
      case CitizenState.atLeisure:
        if (!wantsLeisure) {
          _beginCommute(citizen, citizen.homeTile, CitizenState.commutingHome);
        }
        break;
      case CitizenState.commutingToWork:
      case CitizenState.commutingToLeisure:
      case CitizenState.commutingHome:
        break; // 移動完了は_updateMovement側で処理
    }
  }

  void _beginCommute(Citizen citizen, Point<int> destination, CitizenState commuteState) {
    final currentTile =
        Point(citizen.position.dx.round(), citizen.position.dy.round());
    final path = pathfinder.findPath(currentTile, destination);
    if (path.isEmpty) return; // 到達不可能なら現状維持（道路未接続など）
    citizen.currentPath = path;
    citizen.pathIndex = 0;
    citizen.state = commuteState;
    citizen.logEvent(_lastGameTimeHours, commuteState, currentTile);
  }

  void _updateMovement(Citizen citizen, double dtSeconds) {
    if (citizen.currentPath.isEmpty) return;
    if (citizen.pathIndex >= citizen.currentPath.length) {
      _arriveAtDestination(citizen);
      return;
    }

    final target = citizen.currentPath[citizen.pathIndex];
    final targetOffset = Offset(target.x.toDouble(), target.y.toDouble());
    final delta = targetOffset - citizen.position;
    final distance = delta.distance;
    final step = citizen.speedTilesPerSec * dtSeconds;

    if (distance <= step || distance == 0) {
      citizen.position = targetOffset;
      citizen.pathIndex++;
      if (citizen.pathIndex >= citizen.currentPath.length) {
        _arriveAtDestination(citizen);
      }
    } else {
      final direction = Offset(delta.dx / distance, delta.dy / distance);
      citizen.position += direction * step;
    }
  }

  void _arriveAtDestination(Citizen citizen) {
    citizen.currentPath = const [];
    citizen.pathIndex = 0;
    final arrivedTile = Point(citizen.position.dx.round(), citizen.position.dy.round());
    switch (citizen.state) {
      case CitizenState.commutingToWork:
        citizen.state = CitizenState.atWork;
        break;
      case CitizenState.commutingToLeisure:
        citizen.state = CitizenState.atLeisure;
        break;
      case CitizenState.commutingHome:
        citizen.state = CitizenState.atHome;
        break;
      default:
        break;
    }
    citizen.logEvent(_lastGameTimeHours, citizen.state, arrivedTile);
  }
}
