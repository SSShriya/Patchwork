// widgets/waving_emoji.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class WavingEmoji extends StatefulWidget {
  final double size;
  const WavingEmoji({super.key, this.size = 20});

  @override
  State<WavingEmoji> createState() => _WavingEmojiState();
}

class _WavingEmojiState extends State<WavingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Rocks between -20° and +20°
    _rotation = Tween<double>(
      begin: -math.pi / 9, // -20°
      end: math.pi / 9, // +20°
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Repeat 3 times then stop, so it waves briefly to draw attention
    // without being distracting forever
    _controller.repeat(reverse: true, count: 3);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: Text('👋', style: TextStyle(fontSize: widget.size)),
    );
  }
}
