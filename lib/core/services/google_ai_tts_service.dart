import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

/// Service de synthèse vocale haute fidélité utilisant l'API Google AI Studio (Gemini TTS).
/// Produit une voix humaine américaine naturelle (voix Aoede) à 24kHz.
class GoogleAiTtsService {
  static final GoogleAiTtsService _instance = GoogleAiTtsService._internal();
  factory GoogleAiTtsService() => _instance;
  GoogleAiTtsService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, Uint8List> _cache = {};
  bool _isPlaying = false;
  bool _isInitialized = false;

  bool get isPlaying => _isPlaying;

  /// Modèle Gemini TTS officiel supportant la synthèse vocale neuronale humaine
  static const String _ttsModel = 'gemini-2.5-flash-preview-tts';

  /// Nom de la voix féminine américaine naturelle de Google
  static const String _voiceName = 'Aoede';

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _audioPlayer.onPlayerStateChanged.listen((state) {
        _isPlaying = (state == PlayerState.playing);
      });
      _isInitialized = true;
    } catch (e) {
      debugPrint("GoogleAiTtsService init exception: $e");
    }
  }

  /// Synthétise et joue un texte avec la voix humaine Google AI.
  /// Retourne `true` si le son a été généré et joué avec succès, `false` sinon.
  Future<bool> speak(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    try {
      await init();
      await stop();

      Uint8List? wavBytes = _cache[cleanText];
      if (wavBytes == null) {
        wavBytes = await _fetchGoogleAiAudio(cleanText);
        if (wavBytes != null) {
          // Mettre en cache (limité à 60 entrées pour la mémoire)
          if (_cache.length < 60) {
            _cache[cleanText] = wavBytes;
          }
        }
      }

      if (wavBytes != null) {
        await _audioPlayer.play(BytesSource(wavBytes));
        _isPlaying = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Google AI TTS Error in speak(): $e");
      return false;
    }
  }

  Future<Uint8List?> _fetchGoogleAiAudio(String text) async {
    try {
      final userKey = StorageService.getApiKey();
      final apiKey = (userKey != null && userKey.trim().isNotEmpty)
          ? userKey.trim()
          : AppConfig.defaultGeminiApiKey.trim();

      if (apiKey.isEmpty) return null;

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_ttsModel:generateContent?key=$apiKey',
      );

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": text}
            ]
          }
        ],
        "generationConfig": {
          "responseModalities": ["AUDIO"],
          "speechConfig": {
            "voiceConfig": {
              "prebuiltVoiceConfig": {
                "voiceName": _voiceName,
              }
            }
          }
        }
      });

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final inlineData = parts[0]['inlineData'];
            final base64Audio = inlineData?['data'] as String?;
            if (base64Audio != null && base64Audio.isNotEmpty) {
              final pcmBytes = base64Decode(base64Audio);
              return buildWavHeader(pcmBytes, sampleRate: 24000);
            }
          }
        }
      } else {
        debugPrint("Google AI TTS error code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Google AI TTS fetch failed: $e");
    }
    return null;
  }

  /// Construit un en-tête WAV 44 octets standard pour le flux PCM 24kHz 16-bit Mono
  static Uint8List buildWavHeader(Uint8List pcmData, {int sampleRate = 24000, int numChannels = 1, int bitsPerSample = 16}) {
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final totalDataLen = pcmData.length;
    final totalFileLen = totalDataLen + 36;

    final header = ByteData(44);
    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, totalFileLen, Endian.little);
    // WAVE format
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'
    // fmt subchunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data subchunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, totalDataLen, Endian.little);

    final wav = Uint8List(44 + totalDataLen);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + totalDataLen, pcmData);
    return wav;
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint("Error stopping Google AI audio: $e");
    }
  }
}
