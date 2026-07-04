import 'package:flutter/material.dart';
import '../../domain/engine/citizen_simulation_engine.dart';
import '../../data/models/citizen.dart';

/// 市民エージェントを小さなドットとして描画するPainter。
/// MapPainterとは別レイヤーにすることで、市民の移動による毎フレーム再描画を
/// マップ本体の再描画と分離し、パフォーマンスを最適化する。
class CitizenPainter extends CustomPainter {
  final CitizenSimulationEngine engine;
  final double tileSize;

  CitizenPainter({required this.engine, required this.tileSize});

  static const Map<CitizenState, Color> _stateColors = {
    CitizenState.atHome: Color(0xFF90A4AE),
    CitizenState.commutingToWork: Color(0xFFFFEB3B),
    CitizenState.atWork: Color(0xFFFF9800),
    CitizenState.commutingToLeisure: Color(0xFFBA68C8),
    CitizenState.atLeisure: Color(0xFFE91E63),
    CitizenState.commutingHome: Color(0xFF64B5F6),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const dotRadius = 2.5;

    for (final citizen in engine.citizens) {
      paint.color = _stateColors[citizen.state] ?? Colors.white;
      final center = Offset(
        citizen.position.dx * tileSize + tileSize / 2,
        citizen.position.dy * tileSize + tileSize / 2,
      );
      canvas.drawCircle(center, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CitizenPainter oldDelegate) => true;
}
