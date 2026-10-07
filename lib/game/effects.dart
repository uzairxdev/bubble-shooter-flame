import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'bubble.dart';

/// Ring + spark burst shown when bubbles pop.
class PopEffect extends Component {
  PopEffect({required this.origin, required this.color});

  final Vector2 origin;
  final Color color;
  static const double duration = 0.32;

  double _t = 0;
  final List<_Spark> _sparks = [];

  @override
  Future<void> onLoad() async {
    final rng = Random();
    for (var i = 0; i < 10; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 130 + rng.nextDouble() * 170;
      _sparks.add(_Spark(Vector2(cos(angle) * speed, sin(angle) * speed)));
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    for (final s in _sparks) {
      s.position += s.velocity * dt;
      s.velocity *= (1 - 2.2 * dt);
    }
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0).toDouble();
    final alpha = 1 - p;
    for (final s in _sparks) {
      canvas.drawCircle(
        (origin + s.position).toOffset(),
        3.2 * (1 - p * 0.4),
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
    canvas.drawCircle(
      origin.toOffset(),
      8 + 30 * p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1 - p)
        ..color = Colors.white.withValues(alpha: alpha * 0.9),
    );
  }
}

class _Spark {
  _Spark(this.velocity);
  Vector2 velocity;
  Vector2 position = Vector2.zero();
}

/// A bubble that detached from the ceiling: falls with gravity and fades out.
class FallingBubble extends Bubble {
  FallingBubble({
    required super.bubbleColor,
    required super.radius,
    super.position,
  }) : _velocity = Vector2((Random().nextDouble() - 0.5) * 140, -60);

  final Vector2 _velocity;

  @override
  void update(double dt) {
    _velocity.y += 1500 * dt;
    position += _velocity * dt;
    opacity = (opacity - dt * 0.85).clamp(0.0, 1.0);
    if (position.y > 880 || opacity <= 0) removeFromParent();
  }
}

/// Floating "+30" style score text.
class ScorePopup extends Component {
  ScorePopup(this.text, this.origin);

  final String text;
  final Vector2 origin;
  static const double duration = 0.9;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0).toDouble();
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 1 - p),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      (origin + Vector2(-painter.width / 2, -14 - _t * 56)).toOffset(),
    );
  }
}
