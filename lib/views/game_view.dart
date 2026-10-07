import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/bubble_shooter_game.dart';
import '../game/save_data.dart';
import '../game/sfx.dart';
import '../viewmodels/game_session_viewmodel.dart';
import '../widgets/game_widgets.dart';

/// Hosts one game session. Creates the [GameSessionViewModel] (the MVVM
/// state for this session), injects it into the Flame game, and exposes it
/// to the HUD and overlays via Provider.
class GameView extends StatefulWidget {
  const GameView(
      {super.key, required this.level, this.mode = GameMode.endless});

  final int level;
  final GameMode mode;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late final GameSessionViewModel _vm = GameSessionViewModel(
    mode: widget.mode,
    startLevel: widget.level,
    dailyKey: widget.mode == GameMode.daily
        ? SaveData.dateKey(DateTime.now())
        : null,
  );
  late final BubbleShooterGame _game = BubbleShooterGame(
    vm: _vm,
    startLevel: widget.level,
    mode: widget.mode,
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _vm,
      child: Scaffold(
        body: GameWidget(
          game: _game,
          overlayBuilderMap: {
            'hud': _hud,
            'pauseMenu': _pauseMenu,
            'gameOver': _gameOver,
            'levelComplete': _levelComplete,
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    );
  }
}

// ---------------- HUD ----------------

Widget _hud(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  final vm = context.watch<GameSessionViewModel>();
  return Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            StatPill(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              child: ValueListenableBuilder<int>(
                valueListenable: vm.score,
                builder: (_, v, __) => Text(
                  '$v',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (vm.isDaily)
              const StatPill(
                icon: Icons.calendar_today_rounded,
                iconColor: Colors.purpleAccent,
                child: Text('DAILY',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              )
            else
              StatPill(
                icon: Icons.flag_rounded,
                iconColor: Colors.lightBlueAccent,
                child: ValueListenableBuilder<int>(
                  valueListenable: vm.level,
                  builder: (_, v, __) => Text(
                    'Lv $v',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // Combo badge — the engagement hook.
            ValueListenableBuilder<int>(
              valueListenable: vm.combo,
              builder: (_, v, __) => v >= 2
                  ? StatPill(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.orange,
                      child: Text(
                        'x$v',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const Spacer(),
            ValueListenableBuilder<int>(
              valueListenable: vm.shotsLeft,
              builder: (_, v, __) => Text(
                'New row in $v',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                Sfx.play('click.wav');
                g.togglePause();
              },
              icon: const Icon(Icons.pause_rounded, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white12),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------- overlays ----------------

Widget _pauseMenu(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  return OverlayCard(
    title: 'Paused',
    children: [
      OverlayButton(
          label: 'Resume',
          icon: Icons.play_arrow_rounded,
          onTap: g.togglePause),
      const SizedBox(height: 10),
      OverlayButton(
          label: 'Restart level',
          icon: Icons.refresh_rounded,
          onTap: g.retryLevel),
      const SizedBox(height: 10),
      OverlayButton(
        label: 'Quit to menu',
        icon: Icons.home_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

Widget _gameOver(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  final vm = context.read<GameSessionViewModel>();
  final best = vm.isDaily
      ? SaveData.dailyBest(vm.dailyKey!)
      : SaveData.bestScore(g.level);
  return OverlayCard(
    title: vm.isDaily ? 'Daily over!' : 'Game Over',
    subtitle: vm.isDaily
        ? 'Come back tomorrow for a new board.'
        : 'The bubbles reached the red line!',
    children: [
      Text(
        'Score: ${g.score}',
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
      ),
      const SizedBox(height: 4),
      Text('Best: $best',
          style: const TextStyle(fontSize: 14, color: Colors.white70)),
      const SizedBox(height: 14),
      OverlayButton(
          label: 'Try again',
          icon: Icons.refresh_rounded,
          onTap: g.retryLevel),
      const SizedBox(height: 10),
      OverlayButton(
        label: 'Quit to menu',
        icon: Icons.home_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

Widget _levelComplete(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  final vm = context.read<GameSessionViewModel>();
  final best = vm.isDaily
      ? SaveData.dailyBest(vm.dailyKey!)
      : SaveData.bestScore(g.level);
  return OverlayCard(
    title: vm.isDaily ? 'Daily complete!' : 'Level ${g.level} complete!',
    children: [
      if (!vm.isDaily)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Icon(
              Icons.star_rounded,
              size: 36,
              color: i < g.stars ? Colors.amber : Colors.white24,
            ),
          ),
        ),
      if (!vm.isDaily) const SizedBox(height: 8),
      Text(
        'Score: ${g.score}',
        style: const TextStyle(fontSize: 18, color: Colors.white70),
      ),
      const SizedBox(height: 4),
      Text('Best: $best',
          style: const TextStyle(fontSize: 14, color: Colors.white70)),
      const SizedBox(height: 14),
      if (!vm.isDaily)
        OverlayButton(
          label: 'Next level',
          icon: Icons.arrow_forward_rounded,
          onTap: g.nextLevel,
        ),
      if (!vm.isDaily) const SizedBox(height: 10),
      OverlayButton(
        label: 'Back to menu',
        icon: Icons.home_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
}
