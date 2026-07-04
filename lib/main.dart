import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'services/save/save_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SaveService.init();
  runApp(const ProviderScope(child: HakataCitySimApp()));
}
