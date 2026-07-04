/// マップ上の1マスを表すタイルの種別
enum TileType {
  empty,       // 未開発の空き地
  road,        // 道路
  river,       // 河川（那珂川・御笠川モチーフ）
  rail,        // 鉄道
  residential, // 住宅ゾーン
  commercial,  // 商業ゾーン
  landmark,    // ランドマーク（駅・神社モチーフ等の固定施設）
  park,        // 公園・緑地
}

/// タイルが「歩行・移動可能」かどうか（市民エージェントの経路探索に使用）
extension TileWalkable on TileType {
  bool get isWalkable =>
      this == TileType.road ||
      this == TileType.residential ||
      this == TileType.commercial ||
      this == TileType.landmark ||
      this == TileType.park;
}

class Tile {
  final int x;
  final int y;
  TileType type;
  int density; // 0-3: ゾーンの発展段階（人口・雇用キャパシティに影響）
  double happiness; // 0.0-1.0
  double landValue; // 0.0-1.0

  Tile({
    required this.x,
    required this.y,
    this.type = TileType.empty,
    this.density = 0,
    this.happiness = 0.7,
    this.landValue = 0.3,
  });

  /// このタイル1マスが収容できる「人口キャパシティ」（統計人口計算に使用）
  int get populationCapacity {
    if (type != TileType.residential) return 0;
    return (density + 1) * 40; // density0:40人 ... density3:160人
  }

  /// このタイル1マスが提供できる「雇用キャパシティ」（統計人口計算に使用）
  int get jobCapacity {
    if (type == TileType.commercial) return (density + 1) * 30;
    if (type == TileType.landmark) return 20;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'type': type.index,
        'density': density,
        'happiness': happiness,
        'landValue': landValue,
      };

  factory Tile.fromJson(Map<String, dynamic> json) => Tile(
        x: json['x'] as int,
        y: json['y'] as int,
        type: TileType.values[json['type'] as int],
        density: json['density'] as int,
        happiness: (json['happiness'] as num).toDouble(),
        landValue: (json['landValue'] as num).toDouble(),
      );
}
