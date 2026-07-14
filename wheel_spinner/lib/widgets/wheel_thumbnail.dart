import 'package:flutter/material.dart';
import '../models/wheel_config.dart';

/// 底部状态栏的小缩略图
class WheelThumbnail extends StatelessWidget {
  final WheelConfig config;
  final bool isSelected;
  final VoidCallback onTap;

  const WheelThumbnail({
    super.key,
    required this.config,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 迷你转盘
            SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(
                painter: _MiniWheelPainter(sectors: config.sectors),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              config.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniWheelPainter extends CustomPainter {
  final List<SectorData> sectors;

  _MiniWheelPainter({required this.sectors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 1;
    final sectorAngle = 2 * pi / sectors.length;

    for (int i = 0; i < sectors.length; i++) {
      final paint = Paint()
        ..color = sectors[i].color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + i * sectorAngle,
        sectorAngle,
        true,
        paint,
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = Colors.grey[400]!..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
