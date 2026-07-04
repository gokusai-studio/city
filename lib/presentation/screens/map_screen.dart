import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/city_providers.dart';
import '../painters/map_painter.dart';
import '../painters/citizen_painter.dart';
import '../../data/models/tile.dart';
import '../../core/constants/game_balance.dart';
import 'citizen_detail_screen.dart';
import 'missions_screen.dart';
import 'settings_screen.dart';
import '../widgets/banner_ad_widget.dart';

const double kTileSize = 16.0;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // バックグラウンドへ回る/終了する瞬間に即時セーブし、進行状況の消失を防ぐ
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ref.read(gameTickProvider.notifier).saveNow();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.25) return; // バックグラウンド復帰時の異常dtを無視
    ref.read(gameTickProvider.notifier).tick(dt);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  void _onTapTile(TapUpDetails details) {
    final engine = ref.read(gameLoopEngineProvider);

    // タイル座標系での小数点位置（市民のposition表現と同じ単位系）に変換
    final tapTilePosition = Offset(
      details.localPosition.dx / kTileSize,
      details.localPosition.dy / kTileSize,
    );

    // 1. まず市民エージェントへのタップかどうかを判定（建物配置より優先）
    final tappedCitizen = engine.citizenEngine.findCitizenNear(tapTilePosition);
    if (tappedCitizen != null) {
      engine.city.hasViewedCitizenDetail = true;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CitizenDetailScreen(citizen: tappedCitizen),
        ),
      );
      return;
    }

    // 2. 市民がいなければ通常の建設ツール処理
    final tool = ref.read(selectedBuildToolProvider);
    final x = tapTilePosition.dx.floor();
    final y = tapTilePosition.dy.floor();
    if (x < 0 || y < 0 || x >= engine.city.width || y >= engine.city.height) {
      return;
    }
    final tile = engine.city.tileAt(x, y);
    if (tile.type == TileType.river || tile.type == TileType.landmark) {
      return; // 河川・固定ランドマークは上書き不可
    }
    if (tile.type == tool) return; // 既に同じ種別なら何もしない

    final cost = GameBalance.buildCost[tool] ?? 0;
    if (engine.city.funds < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('資金が足りません（必要: ¥$cost）')),
      );
      return;
    }

    setState(() {
      engine.city.funds -= cost;
      tile.type = tool;
      if (tool == TileType.road || tool == TileType.rail) {
        engine.notifyRoadNetworkChanged();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(gameTickProvider); // フレーム更新を購読して再描画
    final engine = ref.read(gameLoopEngineProvider);
    final city = engine.city;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HAKATA RISING'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'ミッション',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MissionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 3.0,
              minScale: 0.4,
              child: GestureDetector(
                onTapUp: _onTapTile,
                child: SizedBox(
                  width: city.width * kTileSize,
                  height: city.height * kTileSize,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(city.width * kTileSize, city.height * kTileSize),
                        painter: MapPainter(city: city, tileSize: kTileSize),
                      ),
                      CustomPaint(
                        size: Size(city.width * kTileSize, city.height * kTileSize),
                        painter: CitizenPainter(
                          engine: engine.citizenEngine,
                          tileSize: kTileSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _TopDashboard(city: city),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          BannerAdWidget(),
          _BuildToolBar(),
        ],
      ),
    );
  }
}

class _TopDashboard extends StatelessWidget {
  final dynamic city;
  const _TopDashboard({required this.city});

  @override
  Widget build(BuildContext context) {
    final hour = (city.gameTimeHours % 24.0).floor();
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statChip(Icons.attach_money, '¥${city.funds}'),
              _statChip(Icons.groups, '${city.residentPopulation}人'),
              _statChip(Icons.directions_walk, '${city.floatingPopulation}人'),
              _statChip(
                city.isDaytime ? Icons.wb_sunny : Icons.nightlight_round,
                '$hour時',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// 片手操作を前提に画面下部へ集約した建設ツールバー
class _BuildToolBar extends ConsumerWidget {
  const _BuildToolBar();

  static const _tools = [
    (TileType.road, Icons.add_road, '道路'),
    (TileType.residential, Icons.home, '住宅'),
    (TileType.commercial, Icons.store, '商業'),
    (TileType.park, Icons.park, '公園'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedBuildToolProvider);
    return NavigationBar(
      selectedIndex: _tools.indexWhere((t) => t.$1 == selected).clamp(0, _tools.length - 1),
      onDestinationSelected: (i) {
        ref.read(selectedBuildToolProvider.notifier).state = _tools[i].$1;
      },
      destinations: _tools
          .map((t) => NavigationDestination(icon: Icon(t.$2), label: t.$3))
          .toList(),
    );
  }
}
