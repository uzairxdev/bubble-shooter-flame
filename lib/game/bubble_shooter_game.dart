import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../viewmodels/game_session_viewmodel.dart';
import 'aim_guide.dart';
import 'bubble.dart';
import 'effects.dart';
import 'grid.dart';
import 'level_generator.dart';
import 'mascot.dart';
import 'save_data.dart';
import 'sfx.dart';
import 'visuals.dart';

/// The full bubble-shooter game: aiming, shooting, snapping to the hex grid,
/// match-3 popping, dropping detached clusters, row pushes, scoring, levels,
/// pause / game-over / level-complete flow.
///
/// Rendering is responsive: the world is always 420 logical units wide and
/// the camera zooms so the width fills the screen exactly; the visible
/// height adapts to the device aspect ratio ([onGameResize]).
class BubbleShooterGame extends FlameGame with DragCallbacks, TapCallbacks {
  BubbleShooterGame({
    required this.vm,
    required this.startLevel,
    this.mode = GameMode.endless,
    DateTime? dailyDate,
  }) : dailyDate = dailyDate ?? DateTime.now();

  /// First level to load (endless mode).
  final int startLevel;

  /// Endless level progression or the once-per-day challenge board.
  final GameMode mode;

  /// Calendar day for daily mode.
  final DateTime dailyDate;

  bool get isDaily => mode == GameMode.daily;

  String get dailyKey => SaveData.dateKey(dailyDate);

  /// Deterministic seed so every player gets the same daily board.
  int get dailySeed =>
      dailyDate.year * 10000 + dailyDate.month * 100 + dailyDate.day;

  /// Shooter anchor, recomputed from the real screen size in [_updateLayout].
  late Vector2 shooterPos;

  List<BubbleRow> rows = [];
  Bubble? currentBubble;
  Bubble? nextBubble;
  Bubble? flyingBubble;
  final Vector2 _flyDir = Vector2(0, -1);

  late AimGuide aimGuide;
  late Mascot mascot;
  late DangerLine _dangerLine;
  late Background _background;
  late ShooterBase _shooterBase;
  late TextComponent _nextLabel;
  bool _ready = false;

  // ---- engagement: combo multiplier ----
  int combo = 0;

  /// Score multiplier from the current combo (x1 below 2, capped at x8).
  int get multiplier => combo < 2 ? 1 : min(combo, 8);

  // ---- engagement: screen shake ----
  double _shakeT = 0;
  double _shakeDur = 1;
  double _shakeMag = 0;

  /// Kick the camera. [magnitude] in logical pixels.
  void shake(double magnitude, [double duration = 0.28]) {
    _shakeMag = magnitude;
    _shakeDur = duration;
    _shakeT = duration;
  }

  final Random _rng = Random();

  int level = 1;
  int score = 0;
  int _scoreAtLevelStart = 0;
  int _shotsFired = 0;
  bool isGameOver = false;
  bool isLevelComplete = false;

  /// UI-facing state (MVVM): the game writes, Flutter widgets observe.
  final GameSessionViewModel vm;

  @override
  Color backgroundColor() => const Color(0xFF0A0F33);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final bgImage = await images.load('bg.png');
    _background = Background(bgImage);
    world.add(_background);
    _dangerLine = DangerLine();
    world.add(_dangerLine);
    _shooterBase = ShooterBase(position: Vector2.zero());
    world.add(_shooterBase);
    mascot = Mascot(
      sprite: Sprite(await images.load('mascot.png')),
      home: Vector2.zero(),
    );
    world.add(mascot);
    _nextLabel = TextComponent(
      text: 'NEXT',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      anchor: Anchor.center,
    );
    world.add(_nextLabel);
    aimGuide = AimGuide(origin: Vector2.zero());
    world.add(aimGuide);
    _ready = true;
    _updateLayout(size);
    loadLevel(startLevel);
  }

  // ---------------- responsive layout ----------------

  /// Recomputes the world layout from the real canvas size. The world is
  /// always [GameConfig.designWidth] logical units wide; the camera zooms
  /// so the width fills the screen exactly and the visible height adapts
  /// to the device's aspect ratio. Called on every resize (rotation,
  /// foldables, multi-window).
  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _updateLayout(canvasSize);
  }

  void _updateLayout(Vector2 canvasSize) {
    if (canvasSize.x <= 0 || canvasSize.y <= 0) return;

    // Camera: top-left anchored, width-filling zoom. This replaces the old
    // fixed-resolution camera, which mis-framed the world on some screens.
    final zoom = canvasSize.x / GameConfig.designWidth;
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero()
      ..zoom = zoom;

    GameConfig.height = canvasSize.y / zoom;
    GameConfig.gridTopY = 110;
    GameConfig.dangerY = GameConfig.height - 210;
    GameConfig.shooterY = GameConfig.height - 110;
    shooterPos = Vector2(GameConfig.designWidth / 2, GameConfig.shooterY);

    if (!_ready) return; // components don't exist yet; onLoad will finish it

    _background.size = Vector2(GameConfig.designWidth, GameConfig.height);
    _shooterBase.position = shooterPos.clone();
    _nextLabel.position = shooterPos + Vector2(66, 30);
    mascot.setHome(Vector2(58, GameConfig.height - 98));
    aimGuide.origin = shooterPos.clone();
    if (currentBubble != null) {
      currentBubble!.position = shooterPos.clone();
    }
    if (nextBubble != null) {
      nextBubble!.position = shooterPos + Vector2(66, 6);
    }
    // Re-layout grid bubbles (e.g. after rotation).
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].cells.length; c++) {
        final b = rows[r].cells[c];
        if (b != null) b.position = GridLayout.cellCenter(r, c, rows);
      }
    }
  }

  // ---------------- level management ----------------

  void loadLevel(int newLevel) {
    level = newLevel;
    _scoreAtLevelStart = score;
    _shotsFired = 0;
    combo = 0;
    vm.combo.value = 0;
    _shakeT = 0;
    camera.viewfinder.position.setValues(0, 0);
    isGameOver = false;
    isLevelComplete = false;
    flyingBubble = null;
    aimGuide.aiming = false;
    aimGuide.points = const [];
    aimGuide.direction = Vector2(0, -1);
    if (isMounted) mascot.reset();

    for (final b in world.children.whereType<Bubble>()) {
      b.removeFromParent();
    }
    // Daily challenge: one fixed-difficulty board, seeded by calendar date.
    rows = isDaily
        ? LevelGenerator.generateSeeded(3, dailySeed)
        : LevelGenerator.generate(newLevel);
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].cells.length; c++) {
        final b = rows[r].cells[c];
        if (b != null) {
          b.position = GridLayout.cellCenter(r, c, rows);
          world.add(b);
        }
      }
    }

    currentBubble = Bubble(
      bubbleColor: _randomPlayColor(),
      radius: GridLayout.radius,
      position: shooterPos.clone(),
    );
    nextBubble = Bubble(
      bubbleColor: _randomPlayColor(),
      radius: 13,
      position: shooterPos + Vector2(66, 6),
    );
    world.add(currentBubble!);
    world.add(nextBubble!);

    vm.score.value = score;
    vm.level.value = newLevel;
    vm.shotsLeft.value = GameConfig.shotsPerRow - _shotsFired;

    for (final o in ['pauseMenu', 'gameOver', 'levelComplete']) {
      overlays.remove(o);
    }
    resumeEngine();
  }

  void retryLevel() {
    score = _scoreAtLevelStart;
    loadLevel(level);
  }

  void nextLevel() => loadLevel(level + 1);

  void togglePause() {
    if (isGameOver || isLevelComplete) return;
    if (paused) {
      overlays.remove('pauseMenu');
      resumeEngine();
    } else {
      pauseEngine();
      overlays.add('pauseMenu');
    }
  }

  int get stars {
    final par = 500 + level * 200;
    if (score >= par * 1.6) return 3;
    if (score >= par) return 2;
    return 1;
  }

  // ---------------- aiming & shooting ----------------

  bool get _canAim =>
      !paused &&
      !isGameOver &&
      !isLevelComplete &&
      flyingBubble == null &&
      currentBubble != null;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!_canAim) return;
    aimGuide.aiming = true;
    _updateAim(camera.globalToLocal(event.canvasPosition));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!aimGuide.aiming || !_canAim) return;
    _updateAim(camera.globalToLocal(event.canvasEndPosition));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (aimGuide.aiming) {
      aimGuide.aiming = false;
      aimGuide.points = const [];
      _shoot();
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    aimGuide.aiming = false;
    aimGuide.points = const [];
  }

  /// Tap the shooter to swap the current and next bubble.
  @override
  void onTapUp(TapUpEvent event) {
    if (!_canAim) return;
    final p = camera.globalToLocal(event.canvasPosition);
    if ((p - shooterPos).length < 58 &&
        currentBubble != null &&
        nextBubble != null) {
      final tmp = currentBubble!.bubbleColor;
      currentBubble!.setColor(nextBubble!.bubbleColor);
      nextBubble!.setColor(tmp);
      Sfx.play('swap.wav');
    }
  }

  void _updateAim(Vector2 worldPos) {
    final toFinger = worldPos - shooterPos;
    if (toFinger.length < 8) return; // finger on the shooter: keep last aim
    // Aim angle clamped into the upward cone. Clamping (instead of ignoring
    // the drag) keeps the arrow glued to the finger: it slides along the
    // limit instead of freezing when the drag dips toward horizontal.
    const limit = 0.17; // ~10° margin above horizontal
    final angle = atan2(toFinger.y, toFinger.x).clamp(-pi + limit, -limit);
    final dir = Vector2(cos(angle), sin(angle));
    aimGuide.direction = dir;
    aimGuide.points = _computeTrajectory(dir);
  }

  /// Simulates the shot path: wall bounces, then stops at the ceiling or
  /// the first bubble it would touch.
  List<Vector2> _computeTrajectory(Vector2 direction) {
    final points = <Vector2>[];
    final r = GridLayout.radius;
    var p = shooterPos + direction * (r + 34);
    var d = direction.clone();
    const step = 6.0;
    var bounces = 0;
    var traveled = 0.0;
    final ceilingY = GameConfig.gridTopY - GridLayout.rowH / 2;
    while (traveled < 1300 && bounces <= 2) {
      p += d * step;
      traveled += step;
      if (p.x < r) {
        p.x = r;
        d.x = -d.x;
        bounces++;
      } else if (p.x > GameConfig.width - r) {
        p.x = GameConfig.width - r;
        d.x = -d.x;
        bounces++;
      }
      if (p.y - r <= ceilingY + 2) break;
      if (_hitsAnyBubble(p)) break;
      points.add(p.clone());
    }
    return points;
  }

  bool _hitsAnyBubble(Vector2 p) {
    final r = GridLayout.radius;
    final limit = r * 2 - 4;
    for (var row = 0; row < rows.length; row++) {
      final cy = GameConfig.gridTopY + row * GridLayout.rowH;
      if ((cy - p.y).abs() > limit + r) continue;
      for (var col = 0; col < rows[row].cells.length; col++) {
        final b = rows[row].cells[col];
        if (b == null) continue;
        if ((b.position - p).length < limit) return true;
      }
    }
    return false;
  }

  void _shoot() {
    if (!_canAim) return;
    flyingBubble = currentBubble;
    currentBubble = null;
    _flyDir.setFrom(aimGuide.direction.normalized());
    Sfx.play('shoot.wav');
  }

  // ---------------- flight & snapping ----------------

  @override
  void update(double dt) {
    super.update(dt);
    _updateShake(dt);
    _updateThreat();

    final f = flyingBubble;
    if (f == null || isGameOver || isLevelComplete) return;

    // Substep so fast bubbles can't tunnel through the grid at low fps.
    var remaining = dt;
    while (remaining > 0 && flyingBubble != null) {
      final step = min(remaining, 1 / 120);
      remaining -= step;
      _moveFlying(f, step);
    }
  }

  void _updateShake(double dt) {
    if (_shakeT > 0) {
      _shakeT -= dt;
      final k = _shakeMag * (_shakeT / _shakeDur).clamp(0.0, 1.0);
      camera.viewfinder.position.setValues(
        (_rng.nextDouble() * 2 - 1) * k,
        (_rng.nextDouble() * 2 - 1) * k,
      );
    } else {
      camera.viewfinder.position.setValues(0, 0);
    }
  }

  /// Flags the danger line to pulse when bubbles creep close to it.
  void _updateThreat() {
    var threat = false;
    outer:
    for (final r in rows) {
      for (final b in r.cells) {
        if (b != null &&
            b.position.y + GridLayout.radius >= GameConfig.dangerY - 80) {
          threat = true;
          break outer;
        }
      }
    }
    _dangerLine.threat = threat;
  }

  /// Advances the flying bubble one substep. Snaps it into the grid on
  /// wall/ceiling/bubble contact.
  void _moveFlying(Bubble f, double dt) {
    f.position += _flyDir * GameConfig.flySpeed * dt;
    final r = GridLayout.radius;
    if (f.position.x < r) {
      f.position.x = r;
      _flyDir.x = -_flyDir.x;
    } else if (f.position.x > GameConfig.width - r) {
      f.position.x = GameConfig.width - r;
      _flyDir.x = -_flyDir.x;
    }

    final ceilingY = GameConfig.gridTopY - GridLayout.rowH / 2;
    if (f.position.y - r <= ceilingY + 1) {
      _snapFlying(ceiling: true);
      return;
    }
    final hit = _findHitCell(f.position);
    if (hit != null) _snapFlying(hitCell: hit);
  }

  (int, int)? _findHitCell(Vector2 p) {
    final r = GridLayout.radius;
    final limit = r * 2 - 4;
    (int, int)? best;
    var bestDist = double.infinity;
    for (var row = 0; row < rows.length; row++) {
      final cy = GameConfig.gridTopY + row * GridLayout.rowH;
      if ((cy - p.y).abs() > limit + r) continue;
      for (var col = 0; col < rows[row].cells.length; col++) {
        if (rows[row].cells[col] == null) continue;
        final d = (GridLayout.cellCenter(row, col, rows) - p).length;
        if (d < limit && d < bestDist) {
          bestDist = d;
          best = (row, col);
        }
      }
    }
    return best;
  }

  void _snapFlying({(int, int)? hitCell, bool ceiling = false}) {
    final f = flyingBubble;
    if (f == null) return;
    flyingBubble = null;

    final (tr, tc) = ceiling || hitCell == null
        ? _nearestEmptyCell(f.position, maxRow: rows.length - 1)
        : _bestNeighborCell(hitCell, f.position);

    if (rows[tr].cells[tc] != null) {
      _lose(); // board is full; defensive, should not happen
      return;
    }
    f.position = GridLayout.cellCenter(tr, tc, rows);
    rows[tr].cells[tc] = f;
    _resolveBoard(tr, tc);
  }

  /// Empty hex neighbor of the hit cell closest to the flying bubble.
  (int, int) _bestNeighborCell((int, int) cell, Vector2 pos) {
    var best = cell;
    var bestDist = double.infinity;
    var found = false;
    for (final (nr, nc) in GridLayout.neighbors(cell.$1, cell.$2, rows)) {
      if (rows[nr].cells[nc] != null) continue;
      final d = (GridLayout.cellCenter(nr, nc, rows) - pos).length;
      if (d < bestDist) {
        bestDist = d;
        best = (nr, nc);
        found = true;
      }
    }
    if (found) return best;
    return _nearestEmptyCell(pos, maxRow: rows.length - 1);
  }

  (int, int) _nearestEmptyCell(Vector2 pos, {required int maxRow}) {
    var best = (0, 0);
    var bestDist = double.infinity;
    for (var r = 0; r <= maxRow && r < rows.length; r++) {
      for (var c = 0; c < rows[r].cells.length; c++) {
        if (rows[r].cells[c] != null) continue;
        final d = (GridLayout.cellCenter(r, c, rows) - pos).length;
        if (d < bestDist) {
          bestDist = d;
          best = (r, c);
        }
      }
    }
    return best;
  }

  // ---------------- board resolution ----------------

  void _resolveBoard(int row, int col) {
    var gained = 0;

    // 1. Pop connected groups of 3+ of the same color.
    final matched = GridLayout.floodSame(row, col, rows);
    if (matched.length >= 3) {
      for (final (r, c) in matched) {
        final b = rows[r].cells[c];
        if (b == null) continue;
        rows[r].cells[c] = null;
        world.add(
          PopEffect(origin: b.position.clone(), color: b.bubbleColor.display),
        );
        b.removeFromParent();
        gained += 10;
      }
    }

    // 2. Drop clusters no longer connected to the ceiling.
    final floating = GridLayout.floatingCells(rows);
    for (final (r, c) in floating) {
      final b = rows[r].cells[c];
      if (b == null) continue;
      rows[r].cells[c] = null;
      world.add(
        FallingBubble(
          bubbleColor: b.bubbleColor,
          radius: GridLayout.radius,
          position: b.position.clone(),
        ),
      );
      b.removeFromParent();
      gained += 20;
    }

    if (gained > 0) {
      // Combo: consecutive popping shots raise the score multiplier.
      combo++;
      vm.combo.value = combo;
      if (combo > SaveData.bestCombo) SaveData.saveBestCombo(combo);

      final mult = multiplier;
      final total = gained * mult;
      score += total;
      vm.score.value = score;
      world.add(ScorePopup(
        mult > 1 ? '+$total  x$mult' : '+$total',
        GridLayout.cellCenter(row, col, rows),
      ));
      Sfx.play('pop.wav');
      if (combo == 4) Sfx.play('combo.wav');
      Sfx.light();
      if (total >= 40) mascot.celebrate(total);
      if (total >= 80) shake(7);
    } else {
      // A shot that pops nothing breaks the combo.
      combo = 0;
      vm.combo.value = 0;
    }

    // 3. Win check.
    if (_gridEmpty()) {
      _winLevel();
      return;
    }

    // 4. Push a new row down every N shots.
    _shotsFired++;
    if (_shotsFired >= GameConfig.shotsPerRow) {
      _shotsFired = 0;
      _addRow();
      if (isGameOver) return;
    }
    vm.shotsLeft.value = GameConfig.shotsPerRow - _shotsFired;
    _reloadShooter();
  }

  bool _gridEmpty() {
    for (final r in rows) {
      for (final b in r.cells) {
        if (b != null) return false;
      }
    }
    return true;
  }

  void _reloadShooter() {
    if (nextBubble == null) return;
    currentBubble = nextBubble;
    currentBubble!.size = Vector2.all(GridLayout.radius * 2);
    currentBubble!.position = shooterPos.clone();
    nextBubble = Bubble(
      bubbleColor: _randomPlayColor(),
      radius: 13,
      position: shooterPos + Vector2(66, 6),
    );
    world.add(nextBubble!);
  }

  void _addRow() {
    final palette = _playColors().toList();
    if (palette.isEmpty || rows.isEmpty) return;
    final newRow = BubbleRow(
      offset: !rows[0].offset,
      capacity: GridLayout.capacityFor(!rows[0].offset),
    );
    for (var c = 0; c < newRow.cells.length; c++) {
      newRow.cells[c] = Bubble(
        bubbleColor: palette[_rng.nextInt(palette.length)],
        radius: GridLayout.radius,
      );
    }
    rows.insert(0, newRow);
    Sfx.play('rowdrop.wav');
    Sfx.medium();
    shake(3, 0.2);
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].cells.length; c++) {
        final b = rows[r].cells[c];
        if (b == null) continue;
        if (!b.isMounted) world.add(b);
        b.position = GridLayout.cellCenter(r, c, rows);
      }
    }
    for (final r in rows) {
      for (final b in r.cells) {
        if (b != null &&
            b.position.y + GridLayout.radius >= GameConfig.dangerY) {
          _lose();
          return;
        }
      }
    }
  }

  Set<BubbleColor> _playColors() {
    final set = <BubbleColor>{};
    for (final r in rows) {
      for (final b in r.cells) {
        if (b != null) set.add(b.bubbleColor);
      }
    }
    return set;
  }

  BubbleColor _randomPlayColor() {
    final colors = _playColors().toList();
    if (colors.isEmpty) return BubbleColor.values[_rng.nextInt(3)];
    return colors[_rng.nextInt(colors.length)];
  }

  void _winLevel() {
    isLevelComplete = true;
    score += 100 * level;
    vm.score.value = score;
    mascot.celebrate(200);
    Sfx.play('win.wav');
    Sfx.medium();
    world.add(ConfettiBurst(
      origin: Vector2(GameConfig.width / 2, GameConfig.height * 0.3),
    ));
    if (isDaily) {
      SaveData.saveDaily(dailyKey, score);
    } else {
      SaveData.saveBest(level, score);
      SaveData.saveStars(level, stars);
      SaveData.unlock(level + 1);
      SaveData.addWin();
    }
    overlays.add('levelComplete');
  }

  void _lose() {
    isGameOver = true;
    mascot.sad();
    Sfx.play('lose.wav');
    Sfx.heavy();
    if (isDaily) {
      SaveData.saveDaily(dailyKey, score);
    } else {
      SaveData.saveBest(level, score);
    }
    overlays.add('gameOver');
  }
}
