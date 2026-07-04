import 'dart:math';
import 'dart:ui';

/// 市民エージェントの現在の行動状態
enum CitizenState {
  atHome,          // 自宅で就寝・在宅中
  commutingToWork, // 職場/商業施設へ移動中
  atWork,          // 職場/商業施設で活動中
  commutingToLeisure, // 余暇先（公園・歓楽街）へ移動中
  atLeisure,       // 余暇活動中
  commutingHome,   // 帰宅中
}

/// 市民の1日の行動履歴の1エントリ（タップ時の詳細画面で時系列表示するために使用）
class ScheduleLogEntry {
  final double hour; // ゲーム内時刻（0.0-24.0、日をまたぐ場合は24を超えることもある）
  final CitizenState state;
  final Point<int> tileLocation;

  const ScheduleLogEntry({
    required this.hour,
    required this.state,
    required this.tileLocation,
  });
}

/// 1体で「population ÷ agentCount」人分の人口を代表する市民エージェント。
/// 実際に道路網を経路探索で移動し、24時間の生活サイクルを繰り返す。
///
/// name/age/job/storylineはタップ詳細画面での「顔が見える街」演出用のプロフィール。
/// storylineは性的表現を含まない範囲での人間ドラマ（金銭・恋愛未満の悩み・夜の街での
/// 息抜きなど）に留め、Google Playの通常コンテンツレーティングで許容される範囲とする。
class Citizen {
  final String id;
  final String name;
  final int age;
  final String job;
  final String storyline;

  final Point<int> homeTile;
  Point<int>? workTile; // 無職/流動人口の場合は null もありうる
  Point<int>? leisureTile;

  CitizenState state;
  List<Point<int>> currentPath; // 経路探索済みのウェイポイント（タイル座標）
  int pathIndex;
  Offset position; // 現在地（タイル座標系の小数点位置。描画時にpx変換）
  double speedTilesPerSec;

  /// 直近の行動履歴（詳細画面のタイムライン表示用。古いものから先頭を間引く）
  final List<ScheduleLogEntry> history = [];
  static const int maxHistoryEntries = 24;

  /// 1日のうち何時にどの行動へ遷移するかの個体差（0.0-1.0でシフトをずらし
  /// 全市民が同時に一斉行動しないようにする＝リアルな街の見え方を作る）
  final double scheduleJitter;

  Citizen({
    required this.id,
    required this.name,
    required this.age,
    required this.job,
    required this.storyline,
    required this.homeTile,
    this.workTile,
    this.leisureTile,
    this.state = CitizenState.atHome,
    List<Point<int>>? currentPath,
    this.pathIndex = 0,
    Offset? position,
    this.speedTilesPerSec = 1.6,
    double? scheduleJitter,
  })  : currentPath = currentPath ?? const [],
        position = position ??
            Offset(homeTile.x.toDouble(), homeTile.y.toDouble()),
        scheduleJitter = scheduleJitter ?? Random().nextDouble();

  void logEvent(double hour, CitizenState newState, Point<int> tile) {
    history.add(ScheduleLogEntry(hour: hour, state: newState, tileLocation: tile));
    if (history.length > maxHistoryEntries) {
      history.removeAt(0);
    }
  }
}
