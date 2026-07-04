import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/city_state.dart';

/// 都市の状態をローカル永続化するサービス。
/// Hiveは型登録なしでも Map/String/num などプリミティブなJSON文字列を
/// そのまま保存できるため、CityState.toJson()をJSON文字列化して保存する
/// シンプルな方式を採用（MVPの実装コストを最小化）。
class SaveService {
  static const String _boxName = 'hakata_save_box';
  static const String _cityKey = 'city_state_json';

  static Box? _box;

  /// main()内でrunApp前に必ず呼び出すこと。
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> saveCity(CityState city) async {
    if (_box == null) return;
    try {
      await _box!.put(_cityKey, jsonEncode(city.toJson()));
    } catch (_) {
      // セーブ失敗時もゲームプレイは継続させる（ユーザー体験を止めない）
    }
  }

  /// 保存データが無い、または壊れている場合はnullを返す（呼び出し側で新規マップ生成）
  static CityState? loadCity() {
    if (_box == null) return null;
    final raw = _box!.get(_cityKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      return CityState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSave() async {
    if (_box == null) return;
    await _box!.delete(_cityKey);
  }
}
