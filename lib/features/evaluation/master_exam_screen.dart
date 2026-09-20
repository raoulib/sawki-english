import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/curriculum_models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/data/curriculum_data.dart';
import 'certificate_screen.dart';
import 'evaluation_screen.dart';

class MasterExamScreen extends StatefulWidget {
  const MasterExamScreen({super.key});

  @override
  State<MasterExamScreen> createState() => _MasterExamScreenState();
}

class _MasterExamScreenState extends State<MasterExamScreen> {
  late List<QuizQuestion> _questions;
  int _currentIndex = 0;
  int _correctCount = 0;
  String? _selectedOption;
  final TextEditingController _textController = TextEditingController();
  List<String> _builtSentence = [];
  bool _answered = false;
  final Map<String, List<String>> _cachedScrambledWords = {};
  final Map<String, List<String>> _cachedShuffledOptions = {};

  final Map<String, int> _levelTotal = {};
  final Map<String, int> _levelCorrect = {};

  @override
  void initState() {
    super.initState();
    _questions = CurriculumData.getMasterExamQuestions(randomize: true);
  }

  String _getQuestionLevel(QuizQuestion q) {
    final idLower = q.id.toLowerCase();
    if (idLower.contains('a0')) return 'A0';
    if (idLower.contains('a1')) return 'A1';
    if (idLower.contains('a2')) return 'A2';
    if (idLower.contains('b1')) return 'B1';
    if (idLower.contains('b2')) return 'B2';
    if (idLower.contains('c1')) return 'C1';
    return 'A1';
  }

  List<String> _getOptions(QuizQuestion q) {
    if (q.options == null || q.options!.isEmpty) return [];
    if (_cachedShuffledOptions.containsKey(q.id)) {
      return _cachedShuffledOptions[q.id]!;
    }
    final shuffled = List<String>.from(q.options!)..shuffle();
    _cachedShuffledOptions[q.id] = shuffled;
    return shuffled;
  }

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

    final lvl = _getQuestionLevel(q);
    _levelTotal[lvl] = (_levelTotal[lvl] ?? 0) + 1;

    if (isCorrect) {
      _correctCount++;
      _levelCorrect[lvl] = (_levelCorrect[lvl] ?? 0) + 1;
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

      // Identifier le niveau où l'élève a le plus de lacunes (taux de réussite le plus faible)
      String weakestLevel = 'A1';
      double lowestRate = 2.0;

      const levelsOrder = ['A0', 'A1', 'A2', 'B1', 'B2', 'C1'];
      for (final lvl in levelsOrder) {
        final tot = _levelTotal[lvl] ?? 0;
        final corr = _levelCorrect[lvl] ?? 0;
        if (tot > 0) {
          final rate = corr / tot;
          if (rate < lowestRate) {
            lowestRate = rate;
            weakestLevel = lvl;
          }
        }
      }

      final provider = context.read<AppStateProvider>();
      final passed = await provider.submitMasterExam(scorePercent, weakestLevel: weakestLevel);

      if (mounted) {
        _showMasterResultDialog(scorePercent, passed, weakestLevel, provider);
      }
    }
  }

  void _showMasterResultDialog(int score, bool passed, String weakestLevel, AppStateProvider provider) {
    final isLocked = provider.profile.isMasterExamLocked;
    final lockedLvl = provider.profile.masterExamLockedLevel ?? weakestLevel;
    final failures = provider.profile.masterExamFailedAttempts;

    final totWeak = _levelTotal[weakestLevel] ?? 0;
    final corrWeak = _levelCorrect[weakestLevel] ?? 0;
    final weakRatePercent = totWeak > 0 ? ((corrWeak / totWeak) * 100).round() : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                passed ? '🎓' : (isLocked ? '🔒' : '📖'),
                style: const TextStyle(fontSize: 52),
              ),
              const SizedBox(height: 12),
              Text(
                passed
                    ? 'CERTIFICAT D\'EXCELLENCE OBTENU !'
                    : (isLocked ? 'GRAND EXAMEN VERROUILLÉ' : 'Examen Non Validé'),
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
              if (passed) ...[
                const Text(
                  'Félicitations ! Vous avez validé avec brio le Grand Examen de Maîtrise couvrant l\'intégralité des 6 niveaux (A0 à C1) de Sawki English.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ] else if (isLocked) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '🚨 3 Échecs Consécutifs Atteints',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pour assurer une solide progression pédagogique, l\'examen final est temporairement verrouillé.\n\nVotre principale lacune a été identifiée sur le Niveau $lockedLvl (score de cette section : $weakRatePercent%).\n\nVous devez revalider l\'évaluation du Niveau $lockedLvl (≥ 80%) pour débloquer à nouveau le Grand Examen.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Tentative $failures/3 avant verrouillage',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Le seuil d\'excellence de 80% n\'a pas été atteint.\n\nPoint faible détecté : Niveau $weakestLevel ($weakRatePercent% de réussite).\nAttention : 3 échecs consécutifs verrouillent l\'examen jusqu\'à revalidation de ce niveau !',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
              const SizedBox(height: 20),
              if (passed) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.pop(context);
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
              ] else if (isLocked) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.pop(context);
                    final target = CurriculumData.getLevelById(lockedLvl) ?? CurriculumData.levels.first;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EvaluationScreen(level: target),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school),
                  label: Text('Revalider le Niveau $lockedLvl 📚'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    provider.watchAdForEnergy(context);
                    setState(() {
                      _currentIndex = 0;
                      _correctCount = 0;
                      _answered = false;
                      _selectedOption = null;
                      _textController.clear();
                      _builtSentence = [];
                      _cachedScrambledWords.clear();
                      _cachedShuffledOptions.clear();
                      _levelTotal.clear();
                      _levelCorrect.clear();
                      _questions = CurriculumData.getMasterExamQuestions(randomize: true);
                    });
                  },
                  icon: const Icon(Icons.movie_creation_outlined),
                  label: const Text('Regarder une vidéo pour retenter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.pop(context);
                    final target = CurriculumData.getLevelById(weakestLevel) ?? CurriculumData.levels.first;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EvaluationScreen(level: target),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: Text('Réviser le Niveau $weakestLevel'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
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
    final provider = context.watch<AppStateProvider>();
    if (provider.profile.isMasterExamLocked) {
      final lockedLevel = provider.profile.masterExamLockedLevel ?? 'A1';
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Grand Examen Verrouillé 🔒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          elevation: 0.5,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_clock, size: 72, color: AppColors.error),
                ),
                const SizedBox(height: 20),
                const Text(
                  'EXAMEN TEMPORAIREMENT VERROUILLÉ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Suite à 3 échecs consécutifs, vous devez revalider l\'évaluation du Niveau $lockedLevel (score ≥ 80%) pour combler vos lacunes avant de pouvoir repasser le Grand Examen.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    final target = CurriculumData.getLevelById(lockedLevel) ?? CurriculumData.levels.first;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EvaluationScreen(level: target)),
                    );
                  },
                  icon: const Icon(Icons.school),
                  label: Text('Revalider le Niveau $lockedLevel 📚'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour aux cours'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                        ...(_getOptions(q).map(
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
