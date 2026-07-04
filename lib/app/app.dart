import 'package:flutter/material.dart';
import 'theme/material3_theme.dart';
import '../presentation/screens/map_screen.dart';

class HakataCitySimApp extends StatelessWidget {
  const HakataCitySimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAKATA RISING',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MapScreen(),
    );
  }
}
