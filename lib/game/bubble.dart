import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The bubble colors used in the game. Higher levels unlock more of them.
enum BubbleColor { red, blue, green, yellow, purple, orange }

extension BubbleColorStyle on BubbleColor {
  Color get color {
    switch (this) {
      case BubbleColor.red:
        return const Color(0xFFFF5A5A);
      case BubbleColor.blue:
        return const Color(0xFF4D9FFF);
      case BubbleColor.green:
        return const Color(0xFF58D68D);
      case BubbleColor.yellow:
        return const Color(0xFFFFD23F);
      case BubbleColor.purple:
        return const Color(0xFFB366FF);
      case BubbleColor.orange:
        return const Color(0xFFFF9F43);
    }
  }
}

/// A single glossy bubble, rendered procedurally (no image assets needed).
class Bubble extends PositionComponent {
  Bubble({
    required this.bubbleColor,
    required double radius,
    Vector2? position,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  BubbleColor bubbleColor;
  double opacity = 1.0;

  double get radius => size.x / 2;

  void setColor(BubbleColor color) => bubbleColor = color;

  @override
  void render(Canvas canvas) {
    final r = radius;
    final c = size.x / 2;
    final center = Offset(c, c);
    final base = bubbleColor.color;
    final hsl = HSLColor.fromColor(base);

    final light =
        hsl.withLightness(min(1.0, hsl.lightness + 0.28)).toColor();
    final dark = hsl.withLightness(max(0.0, hsl.lightness - 0.22)).toColor();

    final shader = RadialGradient(
      center: const Alignment(-0.38, -0.42),
      radius: 1.15,
      colors: [
        light.withValues(alpha: opacity),
        base.withValues(alpha: opacity),
        dark.withValues(alpha: opacity),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r, Paint()..shader = shader);

    // Glossy highlights.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c - r * 0.34, c - r * 0.42),
        width: r * 0.74,
        height: r * 0.44,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55 * opacity),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c + r * 0.38, c + r * 0.46),
        width: r * 0.3,
        height: r * 0.2,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.25 * opacity),
    );

    // Rim.
    canvas.drawCircle(
      center,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.black.withValues(alpha: 0.28 * opacity),
    );
  }
}
