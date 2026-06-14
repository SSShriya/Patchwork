import 'package:drp/tools/stitched_border_painter.dart';
import 'package:flutter/material.dart';

class StitchedSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String searchQuery;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final double borderRadius;

  const StitchedSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.searchQuery = '',
    this.onChanged,
    this.onClear,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: StitchedBorderPainter(
        // stitchColor: const Color(0xFF84DCC6),
        stitchColor: const Color(0XFF9F8170),
        strokeWidth: 1.6,
        dashLength: 10,
        gapLength: 6,
        borderRadius: borderRadius,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Colors.grey,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4D5359)),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF4D5359)),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: const Color(0x6FEFDECD),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none, // painter handles the border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
