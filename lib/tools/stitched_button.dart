import 'package:drp/tools/stitched_border_painter.dart';
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
        foregroundPainter: StitchedBorderPainter(
          stitchColor: stitchColor.withValues(alpha: 0.6),
          strokeWidth: 2.6,
          dashLength: 8.0,
          gapLength: 8.0,
          borderRadius: 8.0,
          inset: 5.0,
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
