import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import 'save_data.dart';

/// Central sound + haptics helper. Every effect respects the player's
/// settings toggles.
class Sfx {
  static void play(String file) {
    if (GameSettings.sound.value) {
      FlameAudio.play(file);
    }
  }

  static void light() {
    if (GameSettings.vibration.value) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (GameSettings.vibration.value) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (GameSettings.vibration.value) HapticFeedback.heavyImpact();
  }
}
