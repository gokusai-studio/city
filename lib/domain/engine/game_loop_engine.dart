import '../../data/models/city_state.dart';
import '../../data/models/tile.dart';
import 'citizen_simulation_engine.dart';

/// ゲーム全体の時間進行・経済計算・市民シミュレーションを統括するエンジン。
/// Tickerから毎フレーム[tick]が呼ばれる想定。
class GameLoopEngine {
  final CityState city;
  final CitizenSimulationEngine citizenEngine;

  /// 実時間1秒あたり何ゲーム内時間(時)が進むか。
  /// 1.0にすると1日=24秒(短すぎ)なので、0.05 = 実時間8分で1ゲーム内日、程度に調整。
  double timeScaleHoursPerRealSecond = 0.05;

  /// 経済再計算は毎フレームではなく一定間隔で行い負荷を抑える
  double _econAccumulator = 0.0;
  static const double econIntervalSeconds = 1.0;

  GameLoopEngine(this.city) : citizenEngine = CitizenSimulationEngine(city) {
    citizenEngine.syncAgentCountWithPopulation();
  }

  void tick(double dtSeconds) {
    // 1. ゲーム内時刻を進める
    city.gameTimeHours += dtSeconds * timeScaleHoursPerRealSecond;

    // 2. 市民エージェントの生活シミュレーション（毎フレーム＝滑らかな移動）
    citizenEngine.update(dtSeconds, city.gameTimeHours);

    // 3. 経済・人口の統計計算（軽量化のため間引き実行）
    _econAccumulator += dtSeconds;
    if (_econAccumulator >= econIntervalSeconds) {
      _econAccumulator = 0.0;
      _updateEconomyTick();
    }
  }

  void _updateEconomyTick() {
    final capacity = city.totalPopulationCapacity;
    final jobs = city.totalJobCapacity;

    // 人口はキャパシティに向けて緩やかに増減（雇用が無いと頭打ちになる仕様）
    final effectiveCapacity =
        jobs > 0 ? (capacity * (0.5 + 0.5 * (jobs / capacity.clamp(1, 1 << 30)))).round() : (capacity * 0.3).round();

    if (city.residentPopulation < effectiveCapacity) {
      city.residentPopulation += ((effectiveCapacity - city.residentPopulation) * 0.02).ceil();
    } else if (city.residentPopulation > effectiveCapacity) {
      city.residentPopulation -= ((city.residentPopulation - effectiveCapacity) * 0.01).ceil();
    }

    // 流動人口＝商業/ランドマークの規模に応じて簡易算出
    final commercialScale = city.tiles
        .where((t) => t.type == TileType.commercial || t.type == TileType.landmark)
        .fold<int>(0, (sum, t) => sum + (t.density + 1));
    city.floatingPopulation = commercialScale * 15;

    // 税収計算
    final residentialTax =
        (city.residentPopulation * city.taxRateResidential * 0.5).round();
    final commercialTax =
        (city.floatingPopulation * city.taxRateCommercial * 0.3).round();
    city.funds += residentialTax + commercialTax;

    // エージェント数を人口変化に追従させる（急な増減はしない）
    citizenEngine.syncAgentCountWithPopulation();
  }

  /// 道路や鉄道が追加/削除された時に呼び出し、市民の経路キャッシュを破棄する
  void notifyRoadNetworkChanged() {
    citizenEngine.roadNetworkDirty = true;
  }
}
