import 'dart:math';

import 'package:flame/components.dart';

/// The game's mascot: an original cartoon character drawn from generated
/// artwork. She idles with a gentle bob, jumps for joy on big pops,
/// celebrates level wins, and droops when the game is over.
/// Purely decorative — she never affects gameplay.
class Mascot extends SpriteComponent {
  Mascot({required super.sprite, required Vector2 home})
      : _home = home.clone(),
        super(
          position: home.clone(),
          size: Vector2(96, 192),
          anchor: Anchor.center,
        );

  final Vector2 _home;
  double _time = 0;
  double _celebrateT = 0; // >0 while a celebration hop is playing
  double _celebrateDur = 0.8;
  bool _sad = false;

  /// Hop with joy. [strength] scales the hop (pass the points gained).
  void celebrate(int strength) {
    _sad = false;
    _celebrateDur = 0.7 + min(strength, 200) / 200 * 0.7;
    _celebrateT = _celebrateDur;
  }

  void sad() {
    _sad = true;
    _celebrateT = 0;
  }

  void reset() {
    _sad = false;
    _celebrateT = 0;
    position.setFrom(_home);
    scale.setAll(1);
    angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_sad) {
      // Droop: sink slightly, tilt, squash a touch.
      position.setFrom(_home);
      position.y += 8;
      scale.setValues(1.04, 0.9);
      angle = 0.09;
      return;
    }

    if (_celebrateT > 0) {
      _celebrateT -= dt;
      final progress = 1 - (_celebrateT / _celebrateDur).clamp(0.0, 1.0);
      final hop = sin(progress * pi);
      position.setFrom(_home);
      position.y -= hop * 52;
      final s = 1 + hop * 0.16;
      scale.setAll(s);
      angle = sin(progress * pi * 2) * 0.06;
      if (_celebrateT <= 0) reset();
      return;
    }

    // Idle: gentle bob and sway.
    position.setFrom(_home);
    position.y += sin(_time * 2.1) * 4;
    position.x += sin(_time * 1.2) * 2;
    scale.setAll(1);
    angle = sin(_time * 1.4) * 0.03;
  }
}
