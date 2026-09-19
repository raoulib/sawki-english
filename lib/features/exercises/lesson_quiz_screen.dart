import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/curriculum_models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/widgets/tactile_button.dart';

class _WordTile {
  final int id;
  final String word;
  _WordTile(this.id, this.word);

  @override
  bool operator ==(Object other) => identical(this, other) || other is _WordTile && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LessonQuizScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonQuizScreen({super.key, required this.lesson});

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

class _LessonQuizScreenState extends State<LessonQuizScreen> {
  int _currentIndex = 0;
  int _correctAnswersCount = 0;
  String? _selectedOption;
  final TextEditingController _textInputController = TextEditingController();
  List<_WordTile> _shuffledTiles = [];
  List<_WordTile> _selectedTiles = [];
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _textInputController.dispose();
    super.dispose();
  }

  void _loadQuestion() {
    final q = widget.lesson.questions[_currentIndex];

    // Préparation des tuiles mélangées pour les exercices sentenceBuilder
    List<_WordTile> preparedTiles = [];
    if (q.type == ExerciseType.sentenceBuilder) {
      final rawWords = (q.scrambledWords != null && q.scrambledWords!.isNotEmpty)
          ? List<String>.from(q.scrambledWords!)
          : q.correctAnswer.split(' ');

      // Création avec identifiants uniques
      preparedTiles = rawWords.asMap().entries.map((e) => _WordTile(e.key, e.value.trim())).toList();

      // Mélange aléatoire
      preparedTiles.shuffle(math.Random());

      // Vérification absolue : s'assurer que les mots ne sont PAS dans l'ordre de la réponse correcte
      final targetNormalized = _normalize(q.correctAnswer);
      if (preparedTiles.length > 1 && _normalize(preparedTiles.map((t) => t.word).join(' ')) == targetNormalized) {
        // Décalage pour forcer un ordre désorganisé
        final first = preparedTiles.removeAt(0);
        preparedTiles.add(first);
      }
    }

    setState(() {
      _answered = false;
      _selectedOption = null;
      _textInputController.clear();
      _shuffledTiles = preparedTiles;
      _selectedTiles = [];
    });

    if (q.type == ExerciseType.dictation && q.audioText != null) {
      // Démarrage instantané du son audio américain
      Future.delayed(const Duration(milliseconds: 250), () {
        TtsService().speakInstant(q.audioText!);
      });
    }
  }

  void _restartLesson() {
    setState(() {
      _currentIndex = 0;
      _correctAnswersCount = 0;
    });
    _loadQuestion();
  }

  String _normalize(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isAnswerReady() {
    final q = widget.lesson.questions[_currentIndex];
    if (q.type == ExerciseType.multipleChoice || q.type == ExerciseType.translation) {
      return _selectedOption != null;
    } else if (q.type == ExerciseType.dictation) {
      return _textInputController.text.trim().isNotEmpty;
    } else if (q.type == ExerciseType.sentenceBuilder) {
      return _selectedTiles.isNotEmpty;
    }
    return false;
  }

  void _checkAnswer() async {
    if (!_isAnswerReady() || _answered) return;

    final q = widget.lesson.questions[_currentIndex];
    bool correct = false;
    final target = _normalize(q.correctAnswer);

    if (q.type == ExerciseType.multipleChoice || q.type == ExerciseType.translation) {
      correct = _normalize(_selectedOption ?? '') == target;
    } else if (q.type == ExerciseType.dictation) {
      correct = _normalize(_textInputController.text) == target;
    } else if (q.type == ExerciseType.sentenceBuilder) {
      correct = _normalize(_selectedTiles.map((t) => t.word).join(' ')) == target;
    }

    setState(() {
      _answered = true;
      _isCorrect = correct;
      if (correct) {
        _correctAnswersCount++;
      }
    });

    if (correct) {
      SoundService().playCorrect();
    } else {
      SoundService().playIncorrect();
      // Enregistrement automatique dans les lacunes
      await StorageService.recordMistake(
        originalText: _selectedOption ??
            (_textInputController.text.isNotEmpty
                ? _textInputController.text
                : _selectedTiles.map((t) => t.word).join(' ')),
        correctedText: q.correctAnswer,
        errorType: widget.lesson.category,
        explanationFr: q.explanationFr,
      );
    }
  }

  void _nextQuestion() async {
    if (_currentIndex < widget.lesson.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadQuestion();
    } else {
      // Fin de la leçon : Vérification stricte du seuil d'exigence (80% requis)
      final total = widget.lesson.questions.length;
      final scorePercent = total > 0 ? ((_correctAnswersCount / total) * 100).round() : 0;
      final hasPassed = scorePercent >= 80;

      if (hasPassed) {
        // Enregistre uniquement si l'élève a atteint le seuil de passage de 80%
        final provider = context.read<AppStateProvider>();
        await provider.completeLesson(widget.lesson.id, widget.lesson.xpReward);
      }

      if (mounted) {
        if (hasPassed) {
          _showSuccessDialog(scorePercent);
        } else {
          _showFailureDialog(scorePercent);
        }
      }
    }
  }

  void _showSuccessDialog(int scorePercent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.duoGoldLight,
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 42)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Leçon Validée !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.duoTextDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Félicitations ! Vous avez réussi avec $scorePercent% ($_correctAnswersCount/${widget.lesson.questions.length} correctes).\n\nVous gagnez +${widget.lesson.xpReward} XP et débloquez la leçon suivante !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 24),
              TactileButton(
                text: 'CONTINUER',
                type: TactileButtonType.primary,
                onPressed: () {
                  Navigator.pop(dialogCtx); // Dialog
                  Navigator.pop(context); // Screen retour au parcours
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFailureDialog(int scorePercent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.duoErrorBg,
                ),
                child: const Center(
                  child: Text('❌', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Leçon Non Validée',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.duoRed),
              ),
              const SizedBox(height: 8),
              Text(
                'Score : $_correctAnswersCount/${widget.lesson.questions.length} ($scorePercent%)\n\nIl vous faut au moins 80% de bonnes réponses pour valider cette leçon et débloquer la suite du parcours.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 24),
              TactileButton(
                text: 'RECOMMENCER LA LEÇON',
                type: TactileButtonType.danger,
                onPressed: () {
                  Navigator.pop(dialogCtx); // Fermer le modal
                  _restartLesson(); // Recommencer la leçon
                },
              ),
              const SizedBox(height: 10),
              TactileButton(
                text: 'RETOUR AU PARCOURS',
                type: TactileButtonType.neutral,
                height: 46,
                onPressed: () {
                  Navigator.pop(dialogCtx); // Fermer le modal
                  Navigator.pop(context); // Retourner à la carte où la leçon suivante reste verrouillée
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.lesson.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.lesson.questions.length;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.subtext(context), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.isDark(context) ? const Color(0xFF334155) : AppColors.duoGrey,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.duoGreen),
            minHeight: 14,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.isDark(context) ? const Color(0xFF332A00) : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.isDark(context) ? Colors.amber.shade700 : Colors.amber.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '+${widget.lesson.xpReward} XP',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contenu de la question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catégorie / Consigne Duolingo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.duoBlueLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.lesson.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.duoBlueDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Question ${_currentIndex + 1}/${widget.lesson.questions.length}',
                          style: const TextStyle(
                            color: AppColors.duoTextMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Titre / Énoncé de la question
                    Text(
                      q.prompt,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.duoTextDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Vue spécifique selon le type d'exercice
                    if (q.type == ExerciseType.dictation) _buildDictationView(q),
                    if (q.type == ExerciseType.multipleChoice || q.type == ExerciseType.translation)
                      _buildChoiceView(q),
                    if (q.type == ExerciseType.sentenceBuilder) _buildSentenceBuilderView(q),
                  ],
                ),
              ),
            ),

            // Tiroir de validation Duolingo (Bottom Drawer interactif)
            _buildDuolingoBottomDrawer(q),
          ],
        ),
      ),
    );
  }

  // Tiroir Duolingo interactif surgissant en bas
  Widget _buildDuolingoBottomDrawer(QuizQuestion q) {
    if (!_answered) {
      // Bouton Vérifier tactile normal
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          border: Border(top: BorderSide(color: AppColors.cardBorder(context), width: 2)),
        ),
        child: TactileButton(
          text: 'VÉRIFIER',
          type: TactileButtonType.primary,
          onPressed: _isAnswerReady() ? _checkAnswer : null,
        ),
      );
    }

    // Tiroir de résultat Duolingo
    final isSuccess = _isCorrect;
    final drawerBg = isSuccess ? AppColors.duoSuccessBg : AppColors.duoErrorBg;
    final primaryColor = isSuccess ? AppColors.duoGreen : AppColors.duoRed;
    final textColor = isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: drawerBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuccess ? 'Excellent !' : 'Solution correcte :',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    if (!isSuccess)
                      Text(
                        q.correctAnswer,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (q.explanationFr.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      q.explanationFr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          TactileButton(
            text: _currentIndex == widget.lesson.questions.length - 1 ? 'TERMINER' : 'CONTINUER',
            type: isSuccess ? TactileButtonType.primary : TactileButtonType.danger,
            onPressed: _nextQuestion,
          ),
        ],
      ),
    );
  }

  Widget _buildDictationView(QuizQuestion q) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.duoBlueLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.duoBlue.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (q.audioText != null) {
                    TtsService().speakInstant(q.audioText!);
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.duoBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.duoBlueDark,
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Touchez pour écouter la prononciation américaine',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.duoBlueDark,
                ),
              ),
              if (q.phoneticHint != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Aide phonétique : ${q.phoneticHint}',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _textInputController,
          enabled: !_answered,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Écrivez ce que vous avez entendu...',
            hintStyle: TextStyle(color: AppColors.subtext(context), fontWeight: FontWeight.normal),
            filled: true,
            fillColor: AppColors.card(context),
            contentPadding: const EdgeInsets.all(18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppColors.cardBorder(context), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppColors.cardBorder(context), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.duoBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceView(QuizQuestion q) {
    final options = q.options ?? [];

    return Column(
      children: options.asMap().entries.map((entry) {
        final opt = entry.value;
        final isSelected = _selectedOption == opt;

        final isDark = AppColors.isDark(context);
        Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        Color borderColor = isDark ? const Color(0xFF334155) : AppColors.duoGrey;
        Color bottomShadow = isDark ? const Color(0xFF0F172A) : AppColors.duoGreyDark;
        Color textColor = isDark ? Colors.white : AppColors.duoTextDark;

        if (_answered) {
          if (opt == q.correctAnswer) {
            bgColor = AppColors.duoSuccessBg;
            borderColor = AppColors.duoGreen;
            bottomShadow = AppColors.duoGreenDark;
            textColor = const Color(0xFF2E7D32);
          } else if (isSelected && !_isCorrect) {
            bgColor = AppColors.duoErrorBg;
            borderColor = AppColors.duoRed;
            bottomShadow = AppColors.duoRedDark;
            textColor = const Color(0xFFC62828);
          }
        } else if (isSelected) {
          bgColor = AppColors.duoBlueLight;
          borderColor = AppColors.duoBlue;
          bottomShadow = AppColors.duoBlueDark;
          textColor = AppColors.duoBlueDark;
        }

        return GestureDetector(
          onTap: _answered
              ? null
              : () {
                  setState(() => _selectedOption = opt);
                },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: bottomShadow,
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? borderColor : AppColors.duoGreyDark,
                      width: 2,
                    ),
                    color: isSelected ? borderColor : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.duoTextMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (_answered && opt == q.correctAnswer)
                  const Icon(Icons.check_circle_rounded, color: AppColors.duoGreen, size: 24),
                if (_answered && isSelected && !_isCorrect)
                  const Icon(Icons.cancel_rounded, color: AppColors.duoRed, size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSentenceBuilderView(QuizQuestion q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zone de construction avec tactile tiles
        Container(
          constraints: const BoxConstraints(minHeight: 90),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.duoGreyLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.duoGrey, width: 2),
          ),
          child: _selectedTiles.isEmpty
              ? const Center(
                  child: Text(
                    'Touchez les mots ci-dessous pour former la phrase',
                    style: TextStyle(color: AppColors.duoTextMuted, fontSize: 13),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _selectedTiles.map((tile) {
                    return GestureDetector(
                      onTap: _answered
                          ? null
                          : () {
                              setState(() {
                                _selectedTiles.remove(tile);
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.duoBlue, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.duoBlueDark,
                              offset: Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          tile.word,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.duoBlue,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 24),

        // Mots disponibles mélangés aléatoirement
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: _shuffledTiles.map((tile) {
            final isUsed = _selectedTiles.contains(tile);
            final isDark = AppColors.isDark(context);
            return GestureDetector(
              onTap: (_answered || isUsed)
                  ? null
                  : () {
                      setState(() {
                        _selectedTiles.add(tile);
                      });
                    },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isUsed ? 0.35 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUsed
                          ? (isDark ? const Color(0xFF334155) : AppColors.duoGrey)
                          : (isDark ? const Color(0xFF475569) : AppColors.duoGreyDark),
                      width: 2,
                    ),
                    boxShadow: isUsed
                        ? null
                        : [
                            BoxShadow(
                              color: isDark ? const Color(0xFF0F172A) : AppColors.duoGreyDark,
                              offset: const Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                  ),
                  child: Text(
                    tile.word,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isUsed ? AppColors.duoTextMuted : AppColors.text(context),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}


