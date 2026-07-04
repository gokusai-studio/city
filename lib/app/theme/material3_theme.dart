import 'package:flutter/material.dart';

/// 博多祇園山笠を想起させる「朱色×紺」をブランドカラーに、
/// 端末のダイナミックカラーにも対応できるMaterial3テーマ。
class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE53935), // 山笠の朱色
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}
