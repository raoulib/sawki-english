import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (errorNotification) {
          debugPrint("STT Error: ${errorNotification.errorMsg}");
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint("STT Status: $status");
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint("STT Init Exception: $e");
      return false;
    }
  }

  Future<void> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    Function(double soundLevel)? onSoundLevelChange,
    String localeId = 'en_US',
  }) async {
    final hasInit = await init();
    if (!hasInit) {
      debugPrint("Microphone / STT not available or permission denied.");
      return;
    }

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: localeId,
        ),
      );
    } catch (e) {
      debugPrint("Error starting listening: $e");
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _speech.stop();
      _isListening = false;
    } catch (e) {
      debugPrint("Error stopping STT: $e");
    }
  }
}
