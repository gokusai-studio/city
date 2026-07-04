import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/city_state.dart';
import '../../data/models/tile.dart';
import '../../domain/engine/game_loop_engine.dart';
import '../../core/utils/initial_map_generator.dart';
import '../../services/save/save_service.dart';
import '../../core/constants/game_balance.dart';

/// GameLoopEngine（内部にCityStateと市民エンジンを保持）を単一インスタンスとして提供。
/// Tickerと接続するNotifierから毎フレームtick()が呼ばれる。
/// 起動時にセーブデータがあれば復元し、放置していた時間分の経済進行も簡易的に再現する。
final gameLoopEngineProvider = Provider<GameLoopEngine>((ref) {
  final loaded = SaveService.loadCity();
  final city = loaded ?? InitialMapGenerator.generateHakataStarterMap();
  final engine = GameLoopEngine(city);

  if (loaded != null) {
    _applyOfflineProgress(engine, loaded.lastUpdated);
  }
  city.lastUpdated = DateTime.now();
  return engine;
});

/// 放置していた実時間分の経済進行を、軽量な間引きシミュレーションで近似する。
/// 最大3日分・最大2000ステップまでに制限し、起動時の処理負荷を抑える。
void _applyOfflineProgress(GameLoopEngine engine, DateTime lastUpdated) {
  final rawElapsedSeconds = DateTime.now().difference(lastUpdated).inSeconds;
  final elapsedSeconds = rawElapsedSeconds.clamp(0, 60 * 60 * 24 * 3);
  const stepSeconds = 5.0;
  final steps = (elapsedSeconds / stepSeconds).floor().clamp(0, 2000);
  for (int i = 0; i < steps; i++) {
    engine.tick(stepSeconds);
  }
}

/// UIが再描画のトリガーとして監視するための「フレーム更新カウンタ」。
/// CityStateやCitizenのフィールドはミュータブルなので、
/// Riverpodには「更新があったこと」だけを通知しWidget側でrepaintする設計にする。
class GameTickNotifier extends Notifier<int> {
  double _autosaveAccumulator = 0.0;

  @override
  int build() => 0;

  void tick(double dtSeconds) {
    final engine = ref.read(gameLoopEngineProvider);
    engine.tick(dtSeconds);

    _autosaveAccumulator += dtSeconds;
    if (_autosaveAccumulator >= GameBalance.autosaveIntervalSeconds) {
      _autosaveAccumulator = 0.0;
      engine.city.lastUpdated = DateTime.now();
      SaveService.saveCity(engine.city); // fire-and-forget（UIをブロックしない）
    }

    state++; // 再描画トリガー
  }

  /// アプリがバックグラウンドに回った瞬間などに明示的に呼び出す即時セーブ
  void saveNow() {
    final engine = ref.read(gameLoopEngineProvider);
    engine.city.lastUpdated = DateTime.now();
    SaveService.saveCity(engine.city);
  }
}

final gameTickProvider = NotifierProvider<GameTickNotifier, int>(
  GameTickNotifier.new,
);

/// 現在選択中の建設ツール（ゾーニング種別）
final selectedBuildToolProvider = StateProvider<TileType>((ref) => TileType.road);
