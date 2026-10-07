import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'grid.dart';

/// Full-screen painted backdrop: the generated candy-sky artwork drawn
/// cover-fit, with a dark vignette so the bubbles stay readable.
class Background extends PositionComponent {
  Background(this.image)
      : super(
          position: Vector2.zero(),
          size: Vector2(GameConfig.width, GameConfig.height),
          anchor: Anchor.topLeft,
        );

  final ui.Image image;

  @override
  void render(Canvas canvas) {
    // Cover-fit: scale to fill, center-crop the overflow.
    final scale = (size.x / image.width).clamp(
      size.y / image.height,
      double.infinity,
    );
    final dw = image.width * scale;
    final dh = image.height * scale;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH((size.x - dw) / 2, (size.y - dh) / 2, dw, dh),
      Paint(),
    );

    // Vignette for bubble contrast.
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [Colors.transparent, Color(0x66000000)],
        ).createShader(rect),
    );
  }
}

/// Dashed red line: any bubble touching it ends the game.
/// Pulses urgently when bubbles get close ([threat] set by the game).
class DangerLine extends Component {
  bool threat = false;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final y = GameConfig.dangerY;
    final pulse =
        threat ? 0.6 + 0.4 * sin(_t * 8).abs() : 0.65;
    final paint = Paint()
      ..color = (threat ? const Color(0xFFFF3B3B) : Colors.redAccent)
          .withValues(alpha: pulse)
      ..strokeWidth = threat ? 3.5 : 2;
    const dashW = 10.0;
    const gap = 8.0;
    for (var x = 8.0; x < GameConfig.width - 8; x += dashW + gap) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), paint);
    }
  }
}

/// The cannon base the current bubble sits on.
class ShooterBase extends PositionComponent {
  ShooterBase({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(64),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final c = size.x / 2;
    final center = Offset(c, c);
    canvas.drawCircle(center, 30, Paint()..color = const Color(0xFF2A3A6E));
    canvas.drawCircle(
      center,
      30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF8FA2E8),
    );
    canvas.drawCircle(center, 22, Paint()..color = const Color(0xFF16224D));
  }
}
