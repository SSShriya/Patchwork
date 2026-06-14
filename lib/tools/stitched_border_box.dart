import 'package:flutter/material.dart';

class StitchedBorderBox extends StatelessWidget {
  final Widget child;
  final Color stitchColor;
  final Color backgroundColor;
  final double borderRadius;
  final EdgeInsets padding;

  const StitchedBorderBox({
    super.key,
    required this.child,
    this.stitchColor = const Color(0xFF888780),
    this.backgroundColor = Colors.transparent,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StitchedBoxPainter(
        color: stitchColor.withValues(alpha: 0.5),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StitchedBoxPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _StitchedBoxPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final inset = 4.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - inset * 2,
            size.height - inset * 2,
          ),
          Radius.circular(borderRadius),
        ),
      );

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      const dash = 6.0;
      const gap = 7.0;
      while (distance < metric.length) {
        final t1 = metric.getTangentForOffset(distance);
        final t2 = metric.getTangentForOffset(
          (distance + dash).clamp(0, metric.length),
        );
        if (t1 != null && t2 != null) {
          canvas.drawLine(t1.position, t2.position, paint);
        }
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_StitchedBoxPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}
