import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Audios cortos, generados para este prototipo, sin servicios externos.
/// Si el dispositivo silencia el audio o falla el reproductor, la operación sigue.
class GymSounds {
  GymSounds._();
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/$asset.mp3'), volume: .35);
    } catch (_) {
      // El audio es decorativo: nunca bloquea una matrícula o asistencia.
    }
  }

  static void tap() {
    HapticFeedback.selectionClick();
    _play('tap');
  }

  static void success() {
    HapticFeedback.lightImpact();
    _play('success');
  }

  static void notice() {
    HapticFeedback.mediumImpact();
    _play('notice');
  }
}
