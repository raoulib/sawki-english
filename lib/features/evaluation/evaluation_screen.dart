import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/curriculum_models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/sound_service.dart';

class EvaluationScreen extends StatefulWidget {
  final LevelCurriculum level;

  const EvaluationScreen({super.key, required this.level});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
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
    final q = widget.level.evaluationQuestions[_currentIndex];
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
    if (_currentIndex < widget.level.evaluationQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedOption = null;
        _textController.clear();
        _builtSentence = [];
      });
      final nextQ = widget.level.evaluationQuestions[_currentIndex];
      if (nextQ.type == ExerciseType.dictation && nextQ.audioText != null) {
        TtsService().speak(nextQ.audioText!);
      }
    } else {
      // Calcul du score final en pourcentage
      final total = widget.level.evaluationQuestions.length;
      final scorePercent = ((_correctCount / total) * 100).round();

      final provider = context.read<AppStateProvider>();
      final passed = await provider.submitEvaluation(widget.level.id, scorePercent);

      if (mounted) {
        _showResultDialog(scorePercent, passed, provider);
      }
    }
  }

  void _showResultDialog(int score, bool passed, AppStateProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(passed ? '🏆' : '📚', style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 12),
              Text(
                passed ? 'NIVEAU VALIDÉ !' : 'Poursuivez vos efforts !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: passed ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre score : $score% (Seuil : 80%)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                passed
                    ? 'Félicitations ! Vous avez prouvé vos compétences et débloqué le niveau suivant.'
                    : 'Il vous manque encore quelques points pour atteindre les 80%. Révisez vos lacunes et retentez !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (!passed) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.watchAdForEnergy(context);
                    // Relancer
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
                child: const Text('Retour aux cours'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.level.evaluationQuestions;
    final q = questions[_currentIndex];
    final progress = (_currentIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Examen Final : ${widget.level.name}', style: const TextStyle(fontSize: 15)),
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
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
                    'Question ${_currentIndex + 1}/${questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Seuil 80%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                q.prompt,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (q.type == ExerciseType.dictation) ...[
                        IconButton.filled(
                          iconSize: 36,
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
                          constraints: const BoxConstraints(minHeight: 70),
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                          ),
                          child: _builtSentence.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Touchez les mots ci-dessous pour former la phrase',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _builtSentence.map((word) {
                                    return ActionChip(
                                      label: Text(word, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        const SizedBox(height: 20),
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _answered ? 'Continuer ➔' : 'Valider ma réponse',
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
