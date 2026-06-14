import 'package:flutter/material.dart';

class StitchedDivider extends StatelessWidget {
  final Color color;
  final double height;

  const StitchedDivider({
    super.key,
    this.color = const Color(0xFF888780),
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _StitchPainter(color: color)),
    );
  }
}

class _StitchPainter extends CustomPainter {
  final Color color;
  _StitchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final segmentWidth = 20.0;
    final peakHeight = 5.0;
    final centerY = size.height / 2;
    final gapFraction = 0.2; // portion of each segment that's a gap
    final peakGap = 1.5;

    double x = 0;

    while (x < size.width) {
      final nextX = (x + segmentWidth).clamp(0.0, size.width);
      final midX = (x + nextX) / 2;

      if (x + segmentWidth * gapFraction < size.width) {
        // left side of stitch
        canvas.drawLine(
          Offset(x, centerY),
          Offset(midX - peakGap, centerY - peakHeight),
          paint,
        );

        // right side of stitch
        canvas.drawLine(
          Offset(midX + peakGap, centerY - peakHeight),
          Offset(nextX, centerY),
          paint,
        );
      }

      x += segmentWidth + segmentWidth * gapFraction;
    }
  }

  @override
  bool shouldRepaint(_StitchPainter old) => old.color != color;
}
