import 'package:flutter/material.dart';

class StitchedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color stitchColor;
  final bool isLoading;

  const StitchedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = const Color(0xFFDBB2D1),
    this.foregroundColor = Colors.white,
    this.stitchColor = Colors.white,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: CustomPaint(
        foregroundPainter: _StitchedBorderPainter(
          color: stitchColor.withValues(alpha: 0.6),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: onPressed == null || isLoading
                ? backgroundColor.withValues(alpha: 0.6)
                : backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(foregroundColor),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: foregroundColor,
                  ),
                ),
        ),
      ),
    );
  }
}

class _StitchedBorderPainter extends CustomPainter {
  final Color color;
  _StitchedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final inset = 5.0;
    final r = 8.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - inset * 2,
            size.height - inset * 2,
          ),
          Radius.circular(r),
        ),
      );

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      const dash = 8.0;
      const gap = 8.0;
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
  bool shouldRepaint(_StitchedBorderPainter old) => old.color != color;
}
