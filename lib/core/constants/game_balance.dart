import '../../data/models/tile.dart';

/// ゲームバランスに関する定数を一元管理する。
/// 数値調整はここだけを触れば良いようにし、90日目以降の難易度チューニングを容易にする。
class GameBalance {
  /// タイル1マスあたりの建設コスト
  static const Map<TileType, int> buildCost = {
    TileType.road: 100,
    TileType.residential: 500,
    TileType.commercial: 800,
    TileType.park: 300,
  };

  /// 建設不可（既存インフラ・固定ランドマーク・河川）のタイル種別
  static const Set<TileType> unbuildable = {
    TileType.river,
    TileType.landmark,
    TileType.rail,
  };

  /// ミッション達成に必要な各種しきい値
  static const int missionPopulationTarget = 50;
  static const int missionFundsTarget = 60000;
  static const int missionParkTarget = 2;

  /// オートセーブの間隔（実時間・秒）
  static const double autosaveIntervalSeconds = 20.0;
}
