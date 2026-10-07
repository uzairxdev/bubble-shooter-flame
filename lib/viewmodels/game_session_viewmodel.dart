import 'package:flutter/foundation.dart';

import '../game/grid.dart';

/// Which rule set a game session runs under.
enum GameMode { endless, daily }

/// ViewModel for one game session (the MVVM "state" behind the game view).
///
/// The Flame game writes gameplay state here; Flutter widgets (HUD,
/// overlays) observe it. This keeps UI state out of the engine and makes
/// the session testable without a running game.
class GameSessionViewModel extends ChangeNotifier {
  GameSessionViewModel({
    required this.mode,
    required this.startLevel,
    this.dailyKey,
  });

  final GameMode mode;
  final int startLevel;
  final String? dailyKey;

  bool get isDaily => mode == GameMode.daily;

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(0);
  final ValueNotifier<int> level = ValueNotifier(1);
  final ValueNotifier<int> shotsLeft =
      ValueNotifier(GameConfig.shotsPerRow);

  @override
  void dispose() {
    score.dispose();
    combo.dispose();
    level.dispose();
    shotsLeft.dispose();
    super.dispose();
  }
}
