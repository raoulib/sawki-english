import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'google_ai_tts_service.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;
  Map<String, String>? _selectedVoice;
  Map<String, String>? _frenchVoice;

  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      // Détecter et sélectionner une voix féminine américaine naturelle haute qualité
      await _configureNaturalVoice();

      // Intonation chaleureuse et naturelle pour Sarah
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.06);

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        debugPrint("TTS Error: $msg");
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("Error initializing TTS: $e");
    }
  }

  /// Recherche parmi les voix installées sur le smartphone
  /// et sélectionne la voix américaine féminine/naturelle la plus expressive.
  Future<void> _configureNaturalVoice() async {
    try {
      // 1. Préférer le moteur Google Speech Services (Google TTS) s'il est présent
      try {
        final engines = await _flutterTts.getEngines;
        if (engines is List && engines.contains('com.google.android.tts')) {
          await _flutterTts.setEngine('com.google.android.tts');
          debugPrint("TTS: Engine com.google.android.tts selected");
        }
      } catch (e) {
        debugPrint("TTS engine selection note: $e");
      }

      final voices = await _flutterTts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        dynamic bestUsVoice;
        int bestUsScore = -1;

        dynamic bestFrVoice;
        int bestFrScore = -1;

        for (final v in voices) {
          if (v is Map) {
            final locale = (v['locale'] ?? '').toString().toLowerCase().replaceAll('_', '-');
            final name = (v['name'] ?? '').toString().toLowerCase();

            // Voix pour Sarah (anglais américain féminin naturel)
            if (locale.contains('en-us')) {
              int score = 0;
              // Voix neurales et réseau Google haute fidélité
              if (name.contains('network')) score += 60;
              if (name.contains('neural') || name.contains('wavenet') || name.contains('studio')) score += 50;
              if (name.contains('sfg')) score += 35; // Google natural US female (SFG)
              if (name.contains('female') || name.contains('woman') || name.contains('tpf') || name.contains('iol') || name.contains('tpd')) score += 30;
              if (name.contains('local')) score += 10;
              if (name.contains('male') || name.contains('man') || name.contains('boy')) score -= 100;

              if (score > bestUsScore) {
                bestUsScore = score;
                bestUsVoice = v;
              }
            }

            // Voix française pour explications pédagogiques
            if (locale.contains('fr-fr') || locale.contains('fr_fr')) {
              int score = 0;
              if (name.contains('network')) score += 50;
              if (name.contains('neural') || name.contains('wavenet')) score += 40;
              if (name.contains('female') || name.contains('woman')) score += 30;
              if (score > bestFrScore) {
                bestFrScore = score;
                bestFrVoice = v;
              }
            }
          }
        }

        if (bestUsVoice != null && bestUsVoice is Map) {
          _selectedVoice = <String, String>{
            "name": bestUsVoice["name"].toString(),
            "locale": bestUsVoice["locale"]?.toString() ?? "en-US",
          };
          await _flutterTts.setVoice(_selectedVoice!);
          debugPrint("Sarah's natural American voice configured: ${_selectedVoice!['name']}");
        } else {
          await _flutterTts.setLanguage("en-US");
        }

        if (bestFrVoice != null && bestFrVoice is Map) {
          _frenchVoice = <String, String>{
            "name": bestFrVoice["name"].toString(),
            "locale": bestFrVoice["locale"]?.toString() ?? "fr-FR",
          };
        }
      } else {
        await _flutterTts.setLanguage("en-US");
      }
    } catch (e) {
      debugPrint("Could not set specific voice, using default en-US: $e");
      await _flutterTts.setLanguage("en-US");
    }
  }

  /// Vitesse d'élocution réglable :
  /// 0.6 = Lent (débutants), 1.0 = Normal, 1.2 = Rapide (natif)
  Future<void> setSpeedRate(double rate) async {
    try {
      double mappedRate = 0.48;
      if (rate <= 0.7) {
        mappedRate = 0.35;
      } else if (rate >= 1.2) {
        mappedRate = 0.60;
      }
      await _flutterTts.setSpeechRate(mappedRate);
    } catch (e) {
      debugPrint("Error setting speech rate: $e");
    }
  }

  /// Détecte si un texte est principalement en français
  bool isMainlyFrench(String text) {
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'[^\w\u00C0-\u00FF]+'));
    if (words.isEmpty) return false;

    const frenchMarkers = {
      'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'dans', 'en', 'pour',
      'avec', 'sur', 'ce', 'cette', 'ces', 'est', 'sont', 'vous', 'nous',
      'je', 'tu', 'il', 'elle', 'ils', 'elles', 'pas', 'ne', 'que', 'qui',
      'mais', 'donc', 'ou', 'et', 'aussi', 'bien', 'très', 'merci', 'bonjour',
      'pourquoi', 'comment', 'parce', 'français', 'règle', 'façon'
    };

    int frenchCount = 0;
    for (final w in words) {
      if (frenchMarkers.contains(w)) {
        frenchCount++;
      }
    }
    return frenchCount >= 3 || (words.length <= 6 && frenchCount >= 2);
  }

  /// Prononce un texte en anglais américain (priorité Google AI Voice, repli TTS local)
  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    try {
      await stop();

      // Si le message est principalement une explication en français
      if (isMainlyFrench(clean)) {
        await speakFrench(clean);
        return;
      }

      // 1. Tenter la voix humaine ultra-réaliste de Google AI Studio (Gemini TTS)
      final playedWithGoogleAi = await GoogleAiTtsService().speak(clean);
      if (playedWithGoogleAi) {
        _isPlaying = true;
        return; // Succès avec la voix humaine Google AI !
      }

      // 2. Repli automatique sur le TTS local (voix neuronale Android en-US)
      await init();
      if (_selectedVoice != null) {
        await _flutterTts.setVoice(_selectedVoice!);
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      await _flutterTts.setPitch(1.06);
      await _flutterTts.speak(clean);
    } catch (e) {
      debugPrint("Error in speak(): $e");
    }
  }

  /// Prononce une explication en français avec une voix fluide
  Future<void> speakFrench(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    try {
      await stop();
      await init();
      if (_frenchVoice != null) {
        await _flutterTts.setVoice(_frenchVoice!);
      } else {
        await _flutterTts.setLanguage("fr-FR");
      }
      await _flutterTts.setPitch(1.02);
      await _flutterTts.speak(clean);

      // Re-préparer la voix américaine de Sarah
      if (_selectedVoice != null) {
        await _flutterTts.setVoice(_selectedVoice!);
      }
    } catch (e) {
      debugPrint("Error in speakFrench(): $e");
    }
  }

  /// Prononce instantanément en anglais américain sans latence réseau
  Future<void> speakInstant(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    try {
      await stop();
      await init();
      if (_selectedVoice != null) {
        await _flutterTts.setVoice(_selectedVoice!);
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      await _flutterTts.setPitch(1.06);
      await _flutterTts.speak(clean);
    } catch (e) {
      debugPrint("Error in speakInstant(): $e");
    }
  }

  Future<void> stop() async {
    try {
      await GoogleAiTtsService().stop();
      await _flutterTts.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint("Error stopping TTS: $e");
    }
  }
}
