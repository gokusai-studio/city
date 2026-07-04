import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/city_providers.dart';
import '../../data/models/tile.dart';
import '../../core/constants/game_balance.dart';

/// チュートリアルを兼ねたミッション一覧＋簡易実績画面。
/// 条件はCityStateの現在値から都度算出するシンプルな設計（達成フラグの永続化はMVPでは省略）。
class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameTickProvider); // 進行に合わせて達成状況を再評価
    final city = ref.read(gameLoopEngineProvider).city;

    int countOf(TileType t) => city.tiles.where((tile) => tile.type == t).length;

    final missions = <_MissionItem>[
      _MissionItem(
        title: '住宅ゾーンを建設しよう',
        description: '下部ツールバーから「住宅」を選び、空き地をタップして建設しましょう。',
        isDone: countOf(TileType.residential) >= 1,
      ),
      _MissionItem(
        title: '商業ゾーンを建設しよう',
        description: '商業施設は税収と流動人口(観光客・通勤者)を増やします。',
        isDone: countOf(TileType.commercial) >= 1,
      ),
      _MissionItem(
        title: '公園を2つ以上つくろう',
        description: '公園は周辺の幸福度を高め、市民の余暇先にもなります。',
        isDone: countOf(TileType.park) >= GameBalance.missionParkTarget,
      ),
      _MissionItem(
        title: '定住人口${GameBalance.missionPopulationTarget}人を達成しよう',
        description: '住宅ゾーンと雇用先(商業ゾーン)をバランスよく増やしましょう。',
        isDone: city.residentPopulation >= GameBalance.missionPopulationTarget,
      ),
      _MissionItem(
        title: '資金¥${GameBalance.missionFundsTarget}を貯めよう',
        description: '税率スライダー(今後実装)や商業施設の収益で資金を増やせます。',
        isDone: city.funds >= GameBalance.missionFundsTarget,
      ),
      _MissionItem(
        title: '実績: 市民の暮らしをのぞいてみよう',
        description: 'マップ上の市民ドットをタップすると、その人の1日がわかります。',
        isDone: city.hasViewedCitizenDetail,
      ),
    ];

    final doneCount = missions.where((m) => m.isDone).length;

    return Scaffold(
      appBar: AppBar(title: const Text('ミッション・実績')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: missions.isEmpty ? 0 : doneCount / missions.length,
              minHeight: 8,
            ),
          ),
          Text('$doneCount / ${missions.length} 達成'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: missions.length,
              itemBuilder: (context, i) {
                final m = missions[i];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      m.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: m.isDone ? Colors.green : null,
                    ),
                    title: Text(
                      m.title,
                      style: TextStyle(
                        decoration: m.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(m.description),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionItem {
  final String title;
  final String description;
  final bool isDone;
  _MissionItem({required this.title, required this.description, required this.isDone});
}
