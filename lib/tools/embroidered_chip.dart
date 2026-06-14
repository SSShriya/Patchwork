import 'package:flutter/material.dart';

class EmbroideredChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final Color backgroundColor;
  final Color borderColor;

  const EmbroideredChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.backgroundColor = const Color(0xFFD2D2F9),
    this.borderColor = const Color(0xFF002147),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: borderColor.withValues(alpha: 0.6),
        borderRadius: 24,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          // NO border here at all
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withValues(alpha: 0.5),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 13,
                  color: const Color(0xFF4D5359),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(
                    Icons.cancel,
                    size: 16,
                    color: borderColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DottedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      const dotLength = 3;
      const dotGap = 5.0;
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance);
        final end = metric.getTangentForOffset(
          (distance + dotLength).clamp(0, metric.length),
        );
        if (start != null && end != null) {
          canvas.drawLine(start.position, end.position, paint);
        }
        distance += dotLength + dotGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DottedBorderPainter old) => old.color != color;
}
