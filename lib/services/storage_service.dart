import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wheel_config.dart';

class StorageService {
  static const _key = 'wheel_configs';

  /// 保存所有转盘配置
  static Future<void> saveConfigs(List<WheelConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(configs.map((c) => c.toJson()).toList());
    await prefs.setString(_key, json);
  }

  /// 加载所有转盘配置
  static Future<List<WheelConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];

    final list = jsonDecode(json) as List;
    return list
        .map((e) => WheelConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
