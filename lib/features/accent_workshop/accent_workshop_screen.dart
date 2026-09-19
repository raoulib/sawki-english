import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/stt_service.dart';
import '../../core/services/sound_service.dart';

class AccentWorkshopScreen extends StatefulWidget {
  const AccentWorkshopScreen({super.key});

  @override
  State<AccentWorkshopScreen> createState() => _AccentWorkshopScreenState();
}

class _AccentWorkshopScreenState extends State<AccentWorkshopScreen> {
  final List<Map<String, dynamic>> _accentLessons = [
    {
      'title': 'Le "Flap T" Américain',
      'rule': 'Entre deux voyelles, le "T" se prononce comme un "D" très rapide et léger.',
      'examples': [
        {'word': 'Water', 'ipa': '/ˈwɑː.t̬ɚ/', 'fr': 'De l\'eau (se prononce wader)'},
        {'word': 'Better', 'ipa': '/ˈbet̬.ɚ/', 'fr': 'Meilleur (se prononce bedder)'},
        {'word': 'City', 'ipa': '/ˈsɪt̬.i/', 'fr': 'Ville (se prononce sidi)'},
        {'word': 'Bottle of water', 'ipa': '/ˈbɑː.t̬əl əv ˈwɑː.t̬ɚ/', 'fr': 'Une bouteille d\'eau'},
      ]
    },
    {
      'title': 'Le "R" Rhotique Américain',
      'rule': 'Contrairement au British, le "R" est TOUJOURS prononcé en reculant la langue.',
      'examples': [
        {'word': 'Car', 'ipa': '/kɑːr/', 'fr': 'Voiture (le R s\'entend nettement)'},
        {'word': 'Hard work', 'ipa': '/hɑːrd wɝːk/', 'fr': 'Travail acharné'},
        {'word': 'Morning', 'ipa': '/ˈmɔːr.nɪŋ/', 'fr': 'Matin'},
      ]
    },
    {
      'title': 'Les Contractions Orales US',
      'rule': 'Indispensables pour comprendre les films et parler avec fluidité.',
      'examples': [
        {'word': 'Gonna', 'ipa': 'going to', 'fr': 'I\'m gonna call you (Je vais t\'appeler)'},
        {'word': 'Wanna', 'ipa': 'want to', 'fr': 'I wanna go home (Je veux rentrer)'},
        {'word': 'Gotta', 'ipa': 'got to / have to', 'fr': 'I gotta run (Je dois filer)'},
      ]
    },
    {
      'title': 'Les Lettres Muettes & Rythme US',
      'rule': 'Certaines consonnes ne se prononcent pas en anglais américain fluide.',
      'examples': [
        {'word': 'Wednesday', 'ipa': '/ˈwɛnz.deɪ/', 'fr': 'Mercredi (le premier D est muet : wenz-day)'},
        {'word': 'Comfortable', 'ipa': '/ˈkʌm.fɚ.t̬ə.bəl/', 'fr': 'Confortable (se dit en 3 syllabes : comf-ter-ble)'},
        {'word': 'Often', 'ipa': '/ˈɔː.fən/', 'fr': 'Souvent (le T est le plus souvent muet)'},
      ]
    },
  ];

  String? _targetWord;
  String? _targetIpa;
  String? _recordedWord;
  bool _isListening = false;
  int? _pronunciationScore;
  bool? _isPronunciationSuccess;
  String? _pronunciationAdvice;

  // Calcul de la distance d'édition (Levenshtein) pour la précision phonétique
  double _calculateSimilarity(String target, String recognized) {
    final t = target.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final r = recognized.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    if (t == r) return 1.0;
    if (r.contains(t) || t.contains(r)) return 0.85;

    final int dist = _levenshtein(t, r);
    final int maxLen = t.length > r.length ? t.length : r.length;
    if (maxLen == 0) return 1.0;
    return (1.0 - (dist / maxLen)).clamp(0.0, 1.0);
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i <= t.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        int minVal = v1[j] + 1;
        if (v0[j + 1] + 1 < minVal) minVal = v0[j + 1] + 1;
        if (v0[j] + cost < minVal) minVal = v0[j] + cost;
        v1[j + 1] = minVal;
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  void _listenAndCheck(String targetWord, String ipa, String translation) async {
    setState(() {
      _targetWord = targetWord;
      _targetIpa = ipa;
      _recordedWord = 'Écoute en cours... Parlez clairement dans le micro';
      _isListening = true;
      _pronunciationScore = null;
      _isPronunciationSuccess = null;
      _pronunciationAdvice = null;
    });

    await SttService().startListening(
      onResult: (recognized, isFinal) {
        if (isFinal || recognized.isNotEmpty) {
          final similarity = _calculateSimilarity(targetWord, recognized);
          final score = (similarity * 100).round();
          final isSuccess = similarity >= 0.70;

          setState(() {
            _recordedWord = recognized;
            _isListening = false;
            _pronunciationScore = score;
            _isPronunciationSuccess = isSuccess;
            if (isSuccess) {
              _pronunciationAdvice = 'Bravo ! Votre prononciation de "$targetWord" est excellente et sonne très naturelle (+5 XP accordés).';
            } else {
              _pronunciationAdvice = 'Attention : le micro a détecté "$recognized". Référence phonétique : $ipa. Réécoutez Sarah et répétez !';
            }
          });

          if (isSuccess && mounted) {
            SoundService().playCorrect();
            Provider.of<AppStateProvider>(context, listen: false).addXp(5);
          } else if (mounted) {
            SoundService().playIncorrect();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Atelier Accent US 🇺🇸',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.tutorGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parlez comme un natif de New York ou de Californie',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Écoutez le son à vitesse normale ou lente, puis répétez au micro pour comparer.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_recordedWord != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.blue.shade50
                    : (_isPronunciationSuccess == true
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening
                      ? Colors.blue.shade300
                      : (_isPronunciationSuccess == true
                          ? const Color(0xFF16A34A)
                          : Colors.red.shade300),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isListening
                            ? Icons.mic
                            : (_isPronunciationSuccess == true
                                ? Icons.check_circle
                                : Icons.error_outline),
                        color: _isListening
                            ? Colors.blue
                            : (_isPronunciationSuccess == true
                                ? const Color(0xFF16A34A)
                                : Colors.red),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isListening
                              ? 'Analyse vocale en cours...'
                              : (_isPronunciationSuccess == true
                                  ? '🎉 Excellente Prononciation Américaine !'
                                  : '⚠️ Erreur de Prononciation Détectée'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _isListening
                                ? Colors.blue.shade900
                                : (_isPronunciationSuccess == true
                                    ? const Color(0xFF16A34A)
                                    : Colors.red.shade900),
                          ),
                        ),
                      ),
                      if (_pronunciationScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isPronunciationSuccess == true ? const Color(0xFF16A34A) : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_pronunciationScore%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_targetWord != null) ...[
                    Row(
                      children: [
                        const Text('Mot cible : ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('$_targetWord (${_targetIpa ?? ""})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Ce que vous avez dit : ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Expanded(
                          child: Text(
                            '$_recordedWord',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isPronunciationSuccess == true ? const Color(0xFF16A34A) : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_pronunciationAdvice != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _pronunciationAdvice!,
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                  ],
                  if (_targetWord != null && !_isListening) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.volume_up, size: 16),
                          label: const Text('Réécouter Sarah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => TtsService().speak(_targetWord!),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Réessayer'),
                          onPressed: () => _listenAndCheck(_targetWord!, _targetIpa ?? "", ""),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ..._accentLessons.map((lesson) => _buildLessonCard(lesson)),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    final examples = lesson['examples'] as List<Map<String, String>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.record_voice_over, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lesson['title'],
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lesson['rule'],
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const Divider(height: 24),
          ...examples.map(
            (ex) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ex['word']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ex['ipa']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ex['fr']!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Écouter vitesse normale
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: AppColors.primary),
                    tooltip: 'Écouter (Vitesse normale)',
                    onPressed: () {
                      TtsService().speak(ex['word']!);
                    },
                  ),
                  // Répéter au micro
                  IconButton(
                    icon: const Icon(Icons.mic, color: AppColors.secondary),
                    tooltip: 'Répéter au micro & Évaluer',
                    onPressed: () => _listenAndCheck(ex['word']!, ex['ipa']!, ex['fr']!),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
