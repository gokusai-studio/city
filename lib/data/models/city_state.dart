import 'tile.dart';

/// 都市全体の永続化対象データ（セーブ/ロードの単位）
class CityState {
  DateTime lastUpdated;
  int funds;
  int residentPopulation; // 定住人口（統計値）
  int floatingPopulation; // 流動人口＝観光客+通勤者（統計値）

  double taxRateResidential; // 0.0-0.3
  double taxRateCommercial;  // 0.0-0.3
  double taxRateTourism;     // 0.0-0.3

  /// ゲーム内時刻。0.0 = 深夜0時, 24.0 = 翌0時。日をまたいで加算し続ける。
  double gameTimeHours;

  /// 実績用フラグ：市民詳細画面を一度でも開いたか
  bool hasViewedCitizenDetail;

  final int width;
  final int height;
  final List<Tile> tiles;

  CityState({
    required this.width,
    required this.height,
    required this.tiles,
    DateTime? lastUpdated,
    this.funds = 50000,
    this.residentPopulation = 0,
    this.floatingPopulation = 0,
    this.taxRateResidential = 0.1,
    this.taxRateCommercial = 0.1,
    this.taxRateTourism = 0.1,
    this.gameTimeHours = 8.0, // 朝8時スタート
    this.hasViewedCitizenDetail = false,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Tile tileAt(int x, int y) => tiles[y * width + x];

  /// 全住宅タイルの人口収容力の合計（人口が増えられる上限）
  int get totalPopulationCapacity =>
      tiles.fold(0, (sum, t) => sum + t.populationCapacity);

  /// 全商業/ランドマークタイルの雇用収容力の合計
  int get totalJobCapacity =>
      tiles.fold(0, (sum, t) => sum + t.jobCapacity);

  /// ゲーム内時刻が「昼(6-19時)」かどうか（描画の明暗・市民の活動判定に使用）
  bool get isDaytime {
    final h = gameTimeHours % 24.0;
    return h >= 6.0 && h < 19.0;
  }

  Map<String, dynamic> toJson() => {
        'lastUpdated': lastUpdated.toIso8601String(),
        'funds': funds,
        'residentPopulation': residentPopulation,
        'floatingPopulation': floatingPopulation,
        'taxRateResidential': taxRateResidential,
        'taxRateCommercial': taxRateCommercial,
        'taxRateTourism': taxRateTourism,
        'gameTimeHours': gameTimeHours,
        'hasViewedCitizenDetail': hasViewedCitizenDetail,
        'width': width,
        'height': height,
        'tiles': tiles.map((t) => t.toJson()).toList(),
      };

  factory CityState.fromJson(Map<String, dynamic> json) => CityState(
        width: json['width'] as int,
        height: json['height'] as int,
        tiles: (json['tiles'] as List)
            .map((t) => Tile.fromJson(t as Map<String, dynamic>))
            .toList(),
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
        funds: json['funds'] as int,
        residentPopulation: json['residentPopulation'] as int,
        floatingPopulation: json['floatingPopulation'] as int,
        taxRateResidential: (json['taxRateResidential'] as num).toDouble(),
        taxRateCommercial: (json['taxRateCommercial'] as num).toDouble(),
        taxRateTourism: (json['taxRateTourism'] as num).toDouble(),
        gameTimeHours: (json['gameTimeHours'] as num).toDouble(),
        hasViewedCitizenDetail: json['hasViewedCitizenDetail'] as bool? ?? false,
      );
}
