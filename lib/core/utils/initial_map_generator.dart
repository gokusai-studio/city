import '../../data/models/city_state.dart';
import '../../data/models/tile.dart';

/// 博多区の「それっぽさ」（那珂川・南北幹線・博多駅モチーフの中央ハブ）を
/// 再現したMVP用スターターマップを生成する。
/// ※実測座標の複製ではなく、地理的特徴のデフォルメ再現。
class InitialMapGenerator {
  static const int width = 64;
  static const int height = 64;

  static CityState generateHakataStarterMap() {
    final tiles = <Tile>[];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        tiles.add(Tile(x: x, y: y));
      }
    }

    CityState city = CityState(width: width, height: height, tiles: tiles);

    // 1. 那珂川モチーフ：中央やや東寄りを南北に流れる河川
    for (int y = 0; y < height; y++) {
      _setType(city, 38, y, TileType.river);
      _setType(city, 39, y, TileType.river);
    }

    // 2. 南北幹線道路2本
    for (int y = 0; y < height; y++) {
      _setType(city, 20, y, TileType.road);
      _setType(city, 50, y, TileType.road);
    }
    // 3. 東西幹線道路2本
    for (int x = 0; x < width; x++) {
      if (x == 38 || x == 39) continue; // 川は橋（後で道路タイル上書き）にする
      _setType(city, x, 24, TileType.road);
      _setType(city, x, 44, TileType.road);
    }
    // 橋：川と交差する地点は道路として通行可能にする
    _setType(city, 38, 24, TileType.road);
    _setType(city, 39, 24, TileType.road);
    _setType(city, 38, 44, TileType.road);
    _setType(city, 39, 44, TileType.road);

    // 4. 博多駅モチーフ（中央付近のランドマーク、東西横断の鉄道と接続）
    _setType(city, 30, 32, TileType.landmark);
    for (int x = 0; x < width; x++) {
      if (x == 38 || x == 39) continue;
      _setType(city, x, 34, TileType.rail);
    }
    _setType(city, 38, 34, TileType.rail);
    _setType(city, 39, 34, TileType.rail);

    // 5. 神社モチーフの観光ランドマーク（川沿い＝景観ボーナス立地）
    _setType(city, 41, 20, TileType.landmark);

    // 6. 初期の住宅・商業ゾーンを少量配置（チュートリアル用）
    for (int x = 21; x <= 25; x++) {
      _setType(city, x, 20, TileType.residential);
    }
    for (int x = 31; x <= 35; x++) {
      _setType(city, x, 30, TileType.commercial);
    }

    // 7. 近隣公園（幸福度ボーナス）
    _setType(city, 22, 28, TileType.park);

    return city;
  }

  static void _setType(CityState city, int x, int y, TileType type) {
    if (x < 0 || y < 0 || x >= city.width || y >= city.height) return;
    city.tileAt(x, y).type = type;
  }
}
