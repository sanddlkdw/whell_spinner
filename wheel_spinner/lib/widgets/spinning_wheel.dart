import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wheel_config.dart';

/// 物理常量
const double _friction = 0.985; // 摩擦系数
const double _velocityThreshold = 0.5; // 停止阈值
const double _maxAngularVelocity = 50.0; // 最大角速度

class SpinningWheel extends StatefulWidget {
  final WheelConfig config;
  final VoidCallback? onLongPress;
  final double size;

  const SpinningWheel({
    super.key,
    required this.config,
    this.onLongPress,
    this.size = 300,
  });

  @override
  State<SpinningWheel> createState() => _SpinningWheelState();
}

class _SpinningWheelState extends State<SpinningWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentAngle = 0.0;
  double _angularVelocity = 0.0;
  bool _isSpinning = false;
  Offset? _lastFingerPos;
  DateTime? _lastMoveTime;
  double _lastAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // 足够长，靠物理停止
    )..addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 动画每帧回调：惯性减速
  void _onAnimationTick() {
    if (_angularVelocity.abs() < _velocityThreshold) {
      _angularVelocity = 0;
      _isSpinning = false;
      _controller.stop();
      return;
    }
    _currentAngle += _angularVelocity * 0.016; // ~60fps
    _angularVelocity *= _friction;
    setState(() {});
  }

  /// 从手指位置计算角度（相对于转盘中心）
  double _angleFromPosition(Offset position, Size canvasSize) {
    final center = canvasSize / 2;
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    return atan2(dx, -dy); // 12点钟方向为0
  }

  void _onPanStart(DragStartDetails details, Size canvasSize) {
    _controller.stop();
    _lastFingerPos = details.localPosition;
    _lastMoveTime = DateTime.now();
    _lastAngle = _angleFromPosition(details.localPosition, canvasSize);
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    final now = DateTime.now();
    final currentAngle = _angleFromPosition(details.localPosition, canvasSize);
    final deltaAngle = currentAngle - _lastAngle;

    _currentAngle += deltaAngle;
    _lastAngle = currentAngle;
    _lastFingerPos = details.localPosition;
    _lastMoveTime = now;

    setState(() {});
  }

  void _onPanEnd(DragEndDetails details, Size canvasSize) {
    if (_lastFingerPos == null || _lastMoveTime == null) return;

    // 计算角速度（基于最后一段滑动）
    final center = canvasSize / 2;
    final dx = _lastFingerPos!.dx - center.dx;
    final dy = _lastFingerPos!.dy - center.dy;
    final radius = max(sqrt(dx * dx + dy * dy), 1.0);

    // 将像素速度转为角速度
    final velocity = details.velocity.pixelsPerSecond;
    final angularVel =
        (velocity.dx * (-dy) - velocity.dy * dx) / (radius * radius);

    _angularVelocity = angularVel.clamp(
      -_maxAngularVelocity,
      _maxAngularVelocity,
    );

    if (_angularVelocity.abs() > _velocityThreshold) {
      _isSpinning = true;
      _controller.forward(from: 0);
    }
  }

  /// 点击中心按钮：随机旋转
  void _randomSpin() {
    if (_isSpinning) return;
    final random = Random();
    _angularVelocity = (random.nextDouble() * 30 + 10) *
        (random.nextBool() ? 1 : -1);
    _isSpinning = true;
    _controller.forward(from: 0);
  }

  /// 计算指针指向哪个扇区
  String get _winningSectorLabel {
    if (widget.config.sectors.isEmpty) return '';
    final sectorAngle = 2 * pi / widget.config.sectors.length;
    // 归一化角度到 [0, 2π)
    double angle = _currentAngle % (2 * pi);
    if (angle < 0) angle += 2 * pi;
    final index = (angle / sectorAngle).floor() % widget.config.sectors.length;
    return widget.config.sectors[index].label;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _WheelPainter(
            sectors: widget.config.sectors,
            rotation: _currentAngle,
          ),
          child: Center(
            child: GestureDetector(
              onTap: _randomSpin,
              child: Container(
                width: widget.size * 0.15,
                height: widget.size * 0.15,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.play_arrow, color: Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 转盘绘制器
class _WheelPainter extends CustomPainter {
  final List<SectorData> sectors;
  final double rotation;

  _WheelPainter({required this.sectors, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final sectorAngle = 2 * pi / sectors.length;

    // 绘制扇区
    for (int i = 0; i < sectors.length; i++) {
      final startAngle = -pi / 2 + i * sectorAngle + rotation;
      final paint = Paint()
        ..color = sectors[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectorAngle,
        true,
        paint,
      );

      // 绘制分割线
      final linePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        ),
        linePaint,
      );

      // 绘制文字
      final midAngle = startAngle + sectorAngle / 2;
      final textRadius = radius * 0.55;
      final textOffset = Offset(
        center.dx + textRadius * cos(midAngle),
        center.dy + textRadius * sin(midAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: sectors[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        textOffset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // 绘制外圈
    final borderPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, borderPaint);

    // 绘制指针（12点方向）
    final pointerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx - 10, center.dy - radius + 5)
      ..lineTo(center.dx, center.dy - radius - 15)
      ..lineTo(center.dx + 10, center.dy - radius + 5)
      ..close();
    canvas.drawPath(path, pointerPaint);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.sectors != sectors;
}
