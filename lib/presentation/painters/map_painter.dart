import 'package:flutter/material.dart';
import '../../data/models/city_state.dart';
import '../../data/models/tile.dart';

/// タイルマップ本体を描画するPainter。
/// dirty rect管理までは行わず、MVPではシンプルにタイル全体を描画するが、
/// Canvas.drawRectのバッチ化とtileSize固定によりモバイルでも軽量に保つ。
class MapPainter extends CustomPainter {
  final CityState city;
  final double tileSize;

  MapPainter({required this.city, required this.tileSize});

  static const Map<TileType, Color> _dayColors = {
    TileType.empty: Color(0xFFE8E4D8),
    TileType.road: Color(0xFF9E9E9E),
    TileType.river: Color(0xFF4FC3F7),
    TileType.rail: Color(0xFF5D4037),
    TileType.residential: Color(0xFF81C784),
    TileType.commercial: Color(0xFFFFB74D),
    TileType.landmark: Color(0xFFE53935),
    TileType.park: Color(0xFF4CAF50),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final nightOverlay = city.isDaytime
        ? null
        : (Paint()..color = const Color(0x33001030));

    for (final tile in city.tiles) {
      paint.color = _dayColors[tile.type] ?? Colors.grey;
      final rect = Rect.fromLTWH(
        tile.x * tileSize,
        tile.y * tileSize,
        tileSize,
        tileSize,
      );
      canvas.drawRect(rect, paint);
    }

    if (nightOverlay != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, city.width * tileSize, city.height * tileSize),
        nightOverlay,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    // ゾーニング変更時のみ再描画すればよいが、MVPでは簡易的に常時許可。
    // 90日目以降のアップデートでdirty flag管理に最適化予定。
    return true;
  }
}
