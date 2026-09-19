import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/curriculum_models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/data/curriculum_data.dart';
import 'certificate_screen.dart';

class MasterExamScreen extends StatefulWidget {
  const MasterExamScreen({super.key});

  @override
  State<MasterExamScreen> createState() => _MasterExamScreenState();
}

class _MasterExamScreenState extends State<MasterExamScreen> {
  final List<QuizQuestion> _questions = CurriculumData.getMasterExamQuestions();
  int _currentIndex = 0;
  int _correctCount = 0;
  String? _selectedOption;
  final TextEditingController _textController = TextEditingController();
  List<String> _builtSentence = [];
  bool _answered = false;
  final Map<String, List<String>> _cachedScrambledWords = {};

  List<String> _getScrambledWords(QuizQuestion q) {
    if (_cachedScrambledWords.containsKey(q.id)) {
      return _cachedScrambledWords[q.id]!;
    }
    final rawWords = (q.scrambledWords != null && q.scrambledWords!.isNotEmpty)
        ? List<String>.from(q.scrambledWords!)
        : q.correctAnswer.split(' ');
    final shuffled = List<String>.from(rawWords)..shuffle();
    final targetNormalized = _normalize(q.correctAnswer);
    if (shuffled.length > 1 && _normalize(shuffled.join(' ')) == targetNormalized) {
      final first = shuffled.removeAt(0);
      shuffled.add(first);
    }
    _cachedScrambledWords[q.id] = shuffled;
    return shuffled;
  }

  String _normalize(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');
  }

  void _submitAnswer() {
    final q = _questions[_currentIndex];
    bool isCorrect = false;
    final target = _normalize(q.correctAnswer);

    if (q.type == ExerciseType.multipleChoice || q.type == ExerciseType.translation) {
      isCorrect = _normalize(_selectedOption ?? '') == target;
    } else if (q.type == ExerciseType.dictation) {
      isCorrect = _normalize(_textController.text) == target;
    } else if (q.type == ExerciseType.sentenceBuilder) {
      isCorrect = _normalize(_builtSentence.join(' ')) == target;
    }

    if (isCorrect) {
      _correctCount++;
      SoundService().playCorrect();
    } else {
      SoundService().playIncorrect();
    }

    setState(() {
      _answered = true;
    });
  }

  void _nextQuestion() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedOption = null;
        _textController.clear();
        _builtSentence = [];
      });
      final nextQ = _questions[_currentIndex];
      if (nextQ.type == ExerciseType.dictation && nextQ.audioText != null) {
        TtsService().speak(nextQ.audioText!);
      }
    } else {
      // Calcul du score final du Grand Examen
      final total = _questions.length;
      final scorePercent = ((_correctCount / total) * 100).round();

      final provider = context.read<AppStateProvider>();
      final passed = await provider.submitMasterExam(scorePercent);

      if (mounted) {
        _showMasterResultDialog(scorePercent, passed, provider);
      }
    }
  }

  void _showMasterResultDialog(int score, bool passed, AppStateProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(passed ? '🎓' : '📖', style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                passed ? 'CERTIFICAT D\'EXCELLENCE OBTENU !' : 'Examen Non Validé',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: passed ? const Color(0xFFD4AF37) : AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score Global : $score% (Seuil : 80%)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                passed
                    ? 'Félicitations ! Vous avez validé avec brio le Grand Examen de Maîtrise couvrant l\'intégralité des 6 niveaux (A0 à C1) de Sawki English.'
                    : 'Le seuil d\'excellence de 80% n\'a pas été atteint. Révisez vos lacunes et retentez votre chance !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (passed) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Dialog
                    Navigator.pop(context); // Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CertificateScreen(profile: provider.profile),
                      ),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('Voir mon Diplôme Officiel 🏆'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.watchAdForEnergy(context);
                    setState(() {
                      _currentIndex = 0;
                      _correctCount = 0;
                      _answered = false;
                    });
                  },
                  icon: const Icon(Icons.movie_creation_outlined),
                  label: const Text('Regarder une vidéo pour retenter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Grand Examen de Maîtrise Bilingue 🇺🇸', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
            minHeight: 6,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Épreuve ${_currentIndex + 1}/${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD4AF37)),
                    ),
                    child: const Text(
                      'Seuil 80% Requis',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                q.prompt,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (q.type == ExerciseType.dictation) ...[
                        IconButton.filled(
                          iconSize: 40,
                          icon: const Icon(Icons.volume_up),
                          onPressed: () {
                            if (q.audioText != null) TtsService().speak(q.audioText!);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _textController,
                          enabled: !_answered,
                          decoration: InputDecoration(
                            hintText: 'Saisissez la phrase entendue...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                      if (q.type == ExerciseType.multipleChoice || q.type == ExerciseType.translation)
                        ...((q.options ?? []).map(
                          (opt) => GestureDetector(
                            onTap: _answered ? null : () => setState(() => _selectedOption = opt),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedOption == opt ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedOption == opt ? AppColors.primary : Colors.grey.shade200,
                                  width: _selectedOption == opt ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(opt)),
                                  if (_selectedOption == opt)
                                    const Icon(Icons.check_circle, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        )),
                      if (q.type == ExerciseType.sentenceBuilder) ...[
                        Container(
                          constraints: const BoxConstraints(minHeight: 60),
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _builtSentence.map((word) {
                              return ActionChip(
                                label: Text(word),
                                onPressed: _answered
                                    ? null
                                    : () {
                                        setState(() {
                                          _builtSentence.remove(word);
                                        });
                                      },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _getScrambledWords(q).map((word) {
                            final isUsed = _builtSentence.contains(word);
                            return ActionChip(
                              label: Text(word),
                              backgroundColor: isUsed ? Colors.grey.shade200 : Colors.white,
                              onPressed: (_answered || isUsed)
                                  ? null
                                  : () {
                                      setState(() {
                                        _builtSentence.add(word);
                                      });
                                    },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _answered ? _nextQuestion : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _answered ? 'Épreuve Suivante ➔' : 'Confirmer ma réponse',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
