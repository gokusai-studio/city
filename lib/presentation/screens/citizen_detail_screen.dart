import 'package:flutter/material.dart';
import '../../data/models/citizen.dart';

/// マップ上でタップした市民の1日の動きとプロフィールを表示する画面。
class CitizenDetailScreen extends StatelessWidget {
  final Citizen citizen;
  const CitizenDetailScreen({super.key, required this.citizen});

  static const Map<CitizenState, String> _stateLabels = {
    CitizenState.atHome: '自宅で過ごしている',
    CitizenState.commutingToWork: '職場へ移動中',
    CitizenState.atWork: '職場で働いている',
    CitizenState.commutingToLeisure: '余暇先へ移動中',
    CitizenState.atLeisure: '余暇を楽しんでいる',
    CitizenState.commutingHome: '帰宅中',
  };

  static const Map<CitizenState, IconData> _stateIcons = {
    CitizenState.atHome: Icons.home,
    CitizenState.commutingToWork: Icons.directions_walk,
    CitizenState.atWork: Icons.work,
    CitizenState.commutingToLeisure: Icons.directions_walk,
    CitizenState.atLeisure: Icons.local_bar,
    CitizenState.commutingHome: Icons.directions_walk,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${citizen.name}さんの1日')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      citizen.name.substring(0, 1),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(citizen.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text('${citizen.age}歳・${citizen.job}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('暮らしぶり', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(citizen.storyline),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(citizen.state == CitizenState.atHome ||
                              citizen.state == CitizenState.commutingHome
                          ? Icons.nightlight_round
                          : Icons.wb_sunny,
                          size: 18),
                      const SizedBox(width: 6),
                      Text('現在: ${_stateLabels[citizen.state] ?? ''}',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  if (citizen.history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('まだ行動記録がありません。しばらく時間を進めてから見てみましょう。'),
                    )
                  else
                    ..._buildTimeline(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline(BuildContext context) {
    final entries = citizen.history.reversed.toList(); // 新しい順
    return entries.map((e) {
      final hour = (e.hour % 24.0).floor();
      final minute = (((e.hour % 24.0) - hour) * 60).round();
      final timeLabel =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      return ListTile(
        dense: true,
        leading: Icon(_stateIcons[e.state] ?? Icons.circle, size: 20),
        title: Text(_stateLabels[e.state] ?? ''),
        trailing: Text(timeLabel),
        subtitle: Text('位置: (${e.tileLocation.x}, ${e.tileLocation.y})'),
      );
    }).toList();
  }
}
