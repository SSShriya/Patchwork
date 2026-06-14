import 'package:flutter/material.dart';

class ScallopedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);

    final scallopWidth = 40.0;
    final scallopHeight = 10.0;
    int count = (size.width / scallopWidth).ceil() + 1;

    for (int i = 0; i < count; i++) {
      path.quadraticBezierTo(
        (i * scallopWidth) + (scallopWidth / 2),
        size.height + scallopHeight,
        (i + 1) * scallopWidth,
        size.height - 20,
      );
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
