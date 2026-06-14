import 'package:flutter/material.dart';

class StitchedBorderPainter extends CustomPainter {
  final Color stitchColor;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;
  final double inset;

  const StitchedBorderPainter({
    this.stitchColor = const Color(0xFF84DCC6),
    this.strokeWidth = 1.8,
    this.dashLength = 6.0,
    this.gapLength = 4.0,
    this.borderRadius = 24.0,
    this.inset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stitchColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Build the full path of the rounded rect
    final borderPath = Path()..addRRect(rrect);

    // Measure total length and walk it in dash+gap increments
    final metrics = borderPath.computeMetrics().first;
    double distance = 0.0;

    while (distance < metrics.length) {
      final start = distance;
      final end = (distance + dashLength).clamp(0.0, metrics.length);
      canvas.drawPath(metrics.extractPath(start, end), paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(StitchedBorderPainter old) =>
      old.stitchColor != stitchColor ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.borderRadius != borderRadius;
}
