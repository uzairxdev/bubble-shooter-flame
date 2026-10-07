import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Dotted trajectory preview plus a direction arrow at the shooter.
/// The dots only show while the player is dragging to aim.
class AimGuide extends Component {
  AimGuide({required Vector2 origin}) : _origin = origin.clone();

  final Vector2 _origin;
  Vector2 get origin => _origin;
  set origin(Vector2 value) => _origin.setFrom(value);
  Vector2 direction = Vector2(0, -1);
  List<Vector2> points = const [];
  bool aiming = false;

  @override
  void render(Canvas canvas) {
    if (aiming) {
      final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
      for (var i = 0; i < points.length; i += 3) {
        canvas.drawCircle(points[i].toOffset(), 4, dotPaint);
      }
    }
    final d = direction.normalized();
    final tip = origin + d * 56;
    final base = origin + d * 30;
    final perp = Vector2(-d.y, d.x) * 11;
    final path = Path()
      ..moveTo(tip.x, tip.y)
      ..lineTo(base.x + perp.x, base.y + perp.y)
      ..lineTo(base.x - perp.x, base.y - perp.y)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: aiming ? 0.95 : 0.5),
    );
  }
}
