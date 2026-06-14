import 'package:flutter/material.dart';

class ZigZagClipper extends CustomClipper<Path> {
  final double toothSize;

  ZigZagClipper({this.toothSize = 8});

  @override
  Path getClip(Size size) {
    final t = toothSize;
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(0, 0);

    // ── TOP: left → right ──
    path.lineTo(0, 0); // hard corner
    for (double x = t; x < w - t / 2; x += t) {
      path.lineTo(x, (x / t).round().isOdd ? t : 0);
    }
    path.lineTo(w, 0); // hard corner

    // ── RIGHT: top → bottom ──
    for (double y = t; y < h - t / 2; y += t) {
      path.lineTo((y / t).round().isOdd ? w - t : w, y);
    }
    path.lineTo(w, h); // hard corner

    // ── BOTTOM: right → left ──
    for (double x = w - t; x > t / 2; x -= t) {
      final step = ((w - x) / t).round();
      path.lineTo(x, step.isOdd ? h - t : h);
    }
    path.lineTo(0, h); // hard corner

    // ── LEFT: bottom → top ──
    for (double y = h - t; y > t / 2; y -= t) {
      final step = ((h - y) / t).round();
      path.lineTo(step.isOdd ? t : 0, y);
    }
    path.lineTo(0, 0); // hard corner

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
