import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent player data: best scores, stars, unlocks, daily challenge
/// results, and settings. Everything is local — no account, no network.
class SaveData {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---------------- scores & progress ----------------

  static int bestScore(int level) => _prefs.getInt('best_$level') ?? 0;

  static Future<void> saveBest(int level, int score) async {
    if (score > bestScore(level)) {
      await _prefs.setInt('best_$level', score);
    }
  }

  static int stars(int level) => _prefs.getInt('stars_$level') ?? 0;

  static Future<void> saveStars(int level, int value) async {
    if (value > stars(level)) {
      await _prefs.setInt('stars_$level', value);
    }
  }

  /// Highest level the player may open (1-based).
  static int get unlockedLevel => _prefs.getInt('unlocked') ?? 1;

  static Future<void> unlock(int level) async {
    if (level > unlockedLevel) {
      await _prefs.setInt('unlocked', level);
    }
  }

  static int get bestCombo => _prefs.getInt('best_combo') ?? 0;

  static Future<void> saveBestCombo(int combo) async {
    if (combo > bestCombo) {
      await _prefs.setInt('best_combo', combo);
    }
  }

  static int get totalWins => _prefs.getInt('total_wins') ?? 0;

  static Future<void> addWin() async {
    await _prefs.setInt('total_wins', totalWins + 1);
  }

  // ---------------- daily challenge ----------------

  /// yyyy-MM-dd key for a calendar day.
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static int dailyBest(String key) => _prefs.getInt('daily_$key') ?? 0;

  static Future<void> saveDaily(String key, int score) async {
    if (score > dailyBest(key)) {
      await _prefs.setInt('daily_$key', score);
    }
  }

  // ---------------- settings ----------------

  static bool get sound => _prefs.getBool('set_sound') ?? true;
  static Future<void> setSound(bool v) => _prefs.setBool('set_sound', v);

  static bool get vibration => _prefs.getBool('set_vibration') ?? true;
  static Future<void> setVibration(bool v) =>
      _prefs.setBool('set_vibration', v);

  static bool get colorblind => _prefs.getBool('set_colorblind') ?? false;
  static Future<void> setColorblind(bool v) =>
      _prefs.setBool('set_colorblind', v);

  static Future<void> resetAll() => _prefs.clear();
}

/// Runtime copies of the settings as listenable values so the game,
/// bubbles, and UI all react instantly to a toggle.
class GameSettings {
  static final ValueNotifier<bool> sound = ValueNotifier(true);
  static final ValueNotifier<bool> vibration = ValueNotifier(true);
  static final ValueNotifier<bool> colorblind = ValueNotifier(false);

  static void load() {
    sound.value = SaveData.sound;
    vibration.value = SaveData.vibration;
    colorblind.value = SaveData.colorblind;
  }

  static Future<void> updateSound(bool v) async {
    sound.value = v;
    await SaveData.setSound(v);
  }

  static Future<void> updateVibration(bool v) async {
    vibration.value = v;
    await SaveData.setVibration(v);
  }

  static Future<void> updateColorblind(bool v) async {
    colorblind.value = v;
    await SaveData.setColorblind(v);
  }
}
