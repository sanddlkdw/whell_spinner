import 'dart:math';
import 'package:flutter/material.dart';

/// 单个扇区的数据
class SectorData {
  String label;
  Color color;

  SectorData({required this.label, required this.color});

  Map<String, dynamic> toJson() => {
        'label': label,
        'color': color.value, // Color → int
      };

  factory SectorData.fromJson(Map<String, dynamic> json) => SectorData(
        label: json['label'] as String,
        color: Color(json['color'] as int),
      );
}

/// 整个转盘的配置
class WheelConfig {
  final String id;
  String name;
  List<SectorData> sectors;

  WheelConfig({
    required this.id,
    required this.name,
    required this.sectors,
  });

  /// 用扇区数量生成随机颜色（保证相邻不同色）
  static List<SectorData> generateSectors(int count) {
    const baseColors = [
      Color(0xFFE53935), // 红
      Color(0xFF1E88E5), // 蓝
      Color(0xFF43A047), // 绿
      Color(0xFFFDD835), // 黄
      Color(0xFF8E24AA), // 紫
      Color(0xFF00ACC1), // 青
      Color(0xFFFB8C00), // 橙
      Color(0xFFD81B60), // 粉
      Color(0xFF6D4C41), // 棕
      Color(0xFF546E7A), // 蓝灰
      Color(0xFF00BCD4), // 浅青
      Color(0xFF8BC34A), // 浅绿
      Color(0xFFFF5722), // 深橙
      Color(0xFF9C27B0), // 深紫
      Color(0xFF3F51B5), // 靛蓝
      Color(0xFFE91E63), // 玫红
    ];

    final random = Random();
    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      Color c;
      do {
        c = baseColors[random.nextInt(baseColors.length)];
      } while (colors.isNotEmpty && c == colors.last);
      colors.add(c);
    }
    // 检查首尾相邻约束
    if (count > 1 && colors.first == colors.last) {
      colors[count - 1] = baseColors[
          (baseColors.indexOf(colors.last) + 1) % baseColors.length];
    }

    final labels = List.generate(
      count,
      (i) => String.fromCharCode(65 + (i % 26)), // A, B, C...
    );

    return List.generate(count,
        (i) => SectorData(label: labels[i], color: colors[i]));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sectors': sectors.map((s) => s.toJson()).toList(),
      };

  factory WheelConfig.fromJson(Map<String, dynamic> json) => WheelConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        sectors: (json['sectors'] as List)
            .map((s) => SectorData.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
