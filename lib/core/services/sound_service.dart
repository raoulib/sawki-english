import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service gérant les effets sonores de succès et d'erreur pour les exercices et quiz.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _correctPlayer;
  AudioPlayer? _incorrectPlayer;

  AudioPlayer get _getCorrectPlayer {
    _correctPlayer ??= AudioPlayer();
    return _correctPlayer!;
  }

  AudioPlayer get _getIncorrectPlayer {
    _incorrectPlayer ??= AudioPlayer();
    return _incorrectPlayer!;
  }

  /// Joue le son de succès (bonne réponse, validation)
  Future<void> playCorrect() async {
    try {
      HapticFeedback.lightImpact();
      final player = _getCorrectPlayer;
      await player.stop();
      await player.setVolume(1.0);
      await player.play(AssetSource('sounds/correct.wav'));
    } catch (e) {
      debugPrint('SoundService playCorrect error: $e');
    }
  }

  /// Joue le son d'erreur (mauvaise réponse)
  Future<void> playIncorrect() async {
    try {
      HapticFeedback.mediumImpact();
      final player = _getIncorrectPlayer;
      await player.stop();
      await player.setVolume(1.0);
      await player.play(AssetSource('sounds/incorrect.wav'));
    } catch (e) {
      debugPrint('SoundService playIncorrect error: $e');
    }
  }

  void dispose() {
    _correctPlayer?.dispose();
    _correctPlayer = null;
    _incorrectPlayer?.dispose();
    _incorrectPlayer = null;
  }
}
