import 'package:flutter/foundation.dart';

import '../game/save_data.dart';
import '../game/sfx.dart';

/// ViewModel for the settings screen.
class SettingsViewModel extends ChangeNotifier {
  bool get sound => GameSettings.sound.value;
  bool get vibration => GameSettings.vibration.value;
  bool get colorblind => GameSettings.colorblind.value;

  Future<void> setSound(bool v) async {
    await GameSettings.updateSound(v);
    if (v) Sfx.play('click.wav');
    notifyListeners();
  }

  Future<void> setVibration(bool v) async {
    await GameSettings.updateVibration(v);
    notifyListeners();
  }

  Future<void> setColorblind(bool v) async {
    await GameSettings.updateColorblind(v);
    notifyListeners();
  }

  Future<void> resetAll() async {
    await SaveData.resetAll();
    GameSettings.load();
    notifyListeners();
  }
}
