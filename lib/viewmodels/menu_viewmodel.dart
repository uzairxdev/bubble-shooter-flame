import 'package:flutter/foundation.dart';

import '../game/save_data.dart';

/// ViewModel for the main menu: unlocks, stars, records.
class MenuViewModel extends ChangeNotifier {
  int unlockedLevel = 1;
  int bestCombo = 0;
  int totalWins = 0;
  int dailyBest = 0;
  String todayKey = '';

  MenuViewModel() {
    refresh();
  }

  void refresh() {
    unlockedLevel = SaveData.unlockedLevel;
    bestCombo = SaveData.bestCombo;
    totalWins = SaveData.totalWins;
    todayKey = SaveData.dateKey(DateTime.now());
    dailyBest = SaveData.dailyBest(todayKey);
    notifyListeners();
  }

  int starsFor(int level) => SaveData.stars(level);
  int bestFor(int level) => SaveData.bestScore(level);
}
