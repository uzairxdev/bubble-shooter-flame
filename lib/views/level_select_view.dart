import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/sfx.dart';
import '../viewmodels/game_session_viewmodel.dart';
import '../viewmodels/menu_viewmodel.dart';
import 'game_view.dart';

/// Grid of levels with unlocks, stars, and best scores.
class LevelSelectView extends StatelessWidget {
  const LevelSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MenuViewModel>();
    final unlocked = vm.unlockedLevel;
    final count = unlocked.clamp(12, 120);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose level'), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: count,
        itemBuilder: (context, i) {
          final level = i + 1;
          final isOpen = level <= unlocked;
          final stars = vm.starsFor(level);
          final best = vm.bestFor(level);
          return GestureDetector(
            onTap: isOpen
                ? () {
                    Sfx.play('click.wav');
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => GameView(
                                level: level,
                                mode: GameMode.endless)))
                        .then((_) => vm.refresh());
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: isOpen ? const Color(0xFF1B2452) : Colors.white10,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isOpen ? const Color(0xFF4D9FFF) : Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isOpen
                      ? Text('$level',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold))
                      : const Icon(Icons.lock_rounded,
                          color: Colors.white38, size: 22),
                  if (isOpen) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (s) => Icon(Icons.star_rounded,
                            size: 12,
                            color: s < stars
                                ? Colors.amber
                                : Colors.white24),
                      ),
                    ),
                    if (best > 0)
                      Text('$best',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white60)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
