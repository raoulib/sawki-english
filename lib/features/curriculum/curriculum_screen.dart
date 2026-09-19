import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/data/curriculum_data.dart';
import '../../core/models/curriculum_models.dart';
import '../../core/models/user_profile.dart';
import '../../core/widgets/tactile_button.dart';
import '../../core/widgets/tactile_node.dart';
import '../exercises/lesson_quiz_screen.dart';
import '../evaluation/evaluation_screen.dart';
import '../evaluation/master_exam_screen.dart';
import '../evaluation/certificate_screen.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  int _selectedLevelIndex = 0;

  bool _isLevelUnlocked(String levelId, UserProfile profile) {
    if (profile.isPremium) return true;
    if (levelId == 'A0') return true;
    if (levelId == 'A1') return (profile.evaluationScores['A0'] ?? 0) >= 80;
    if (levelId == 'A2') return (profile.evaluationScores['A1'] ?? 0) >= 80;
    if (levelId == 'B1') return (profile.evaluationScores['A2'] ?? 0) >= 80;
    if (levelId == 'B2') return (profile.evaluationScores['B1'] ?? 0) >= 80;
    if (levelId == 'C1') return (profile.evaluationScores['B2'] ?? 0) >= 80;
    return false;
  }

  bool _isMasterExamUnlocked(List<LevelCurriculum> levels, UserProfile profile) {
    if (profile.isPremium) return true;
    return levels.every((lvl) => (profile.evaluationScores[lvl.id] ?? 0) >= lvl.requiredPassingScore);
  }

  Color _getLevelColor(int index) {
    const colors = [
      AppColors.duoGreen,
      AppColors.duoBlue,
      Color(0xFF8B5CF6), // Violet
      AppColors.duoGold,
      AppColors.duoOrange,
      Color(0xFF0284C7), // Cyan soutenu
    ];
    return colors[index % colors.length];
  }

  Color _getLevelDarkColor(int index) {
    const colors = [
      AppColors.duoGreenDark,
      AppColors.duoBlueDark,
      Color(0xFF6D28D9),
      AppColors.duoGoldDark,
      AppColors.duoOrangeDark,
      Color(0xFF0369A1),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final levels = CurriculumData.getLevels();
    final profile = provider.profile;

    final currentLevel = levels[_selectedLevelIndex.clamp(0, levels.length - 1)];
    final isCurrentLevelUnlocked = _isLevelUnlocked(currentLevel.id, profile);
    final completedInLevel = currentLevel.lessons
        .where((l) => profile.completedLessons.contains(l.id))
        .length;
    final isExamUnlocked = profile.isPremium || completedInLevel == currentLevel.lessons.length;
    final lastScore = profile.evaluationScores[currentLevel.id];
    final isLevelPassed = (lastScore ?? 0) >= currentLevel.requiredPassingScore;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getLevelColor(_selectedLevelIndex).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'SECTION ${_selectedLevelIndex + 1}',
                style: TextStyle(
                  color: _getLevelDarkColor(_selectedLevelIndex),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentLevel.name,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.text(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder(context), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '${profile.streakDays} j',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.duoOrangeDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de sélection de niveau Duolingo (Pill Selector)
          Container(
            height: 54,
            color: AppColors.card(context),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: levels.length + 1,
              itemBuilder: (context, idx) {
                if (idx == levels.length) {
                  // Bouton Grand Examen
                  final isMasterUnlocked = _isMasterExamUnlocked(levels, profile);
                  final isSelected = _selectedLevelIndex == idx;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLevelIndex = idx),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0F172A) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F172A) : AppColors.duoGrey,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(profile.isCertified ? '🏆' : (isMasterUnlocked ? '👑' : '🔒')),
                          const SizedBox(width: 6),
                          Text(
                            'Grand Examen C1',
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.duoTextDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final lvl = levels[idx];
                final isUnlocked = _isLevelUnlocked(lvl.id, profile);
                final isSelected = _selectedLevelIndex == idx;
                final lvlColor = _getLevelColor(idx);

                return GestureDetector(
                  onTap: () => setState(() => _selectedLevelIndex = idx),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? lvlColor : AppColors.card(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _getLevelDarkColor(idx) : AppColors.cardBorder(context),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _getLevelDarkColor(idx),
                                offset: const Offset(0, 2),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        if (!isUnlocked)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.lock, size: 12, color: AppColors.duoTextMuted),
                          ),
                        Text(
                          lvl.id,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.text(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.duoGrey),

          // Contenu principal : Snake Path sinueux ou Vue Grand Examen
          Expanded(
            child: _selectedLevelIndex == levels.length
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildMasterExamCard(context, profile, _isMasterUnlocked(levels, profile)),
                  )
                : _buildSnakePathView(
                    context,
                    currentLevel,
                    isCurrentLevelUnlocked,
                    completedInLevel,
                    isExamUnlocked,
                    isLevelPassed,
                    lastScore,
                    profile,
                  ),
          ),
        ],
      ),
    );
  }

  bool _isMasterUnlocked(List<LevelCurriculum> levels, UserProfile profile) =>
      _isMasterExamUnlocked(levels, profile);

  Widget _buildSnakePathView(
    BuildContext context,
    LevelCurriculum level,
    bool isLevelUnlocked,
    int completedCount,
    bool isExamUnlocked,
    bool isPassed,
    int? lastScore,
    UserProfile profile,
  ) {
    final themeColor = _getLevelColor(_selectedLevelIndex);
    final themeDarkColor = _getLevelDarkColor(_selectedLevelIndex);

    // Trouver la première leçon non complétée (leçon active)
    int firstActiveLessonIndex = -1;
    if (isLevelUnlocked) {
      for (int i = 0; i < level.lessons.length; i++) {
        if (!profile.completedLessons.contains(level.lessons[i].id)) {
          firstActiveLessonIndex = i;
          break;
        }
      }
      // Si toutes sont complétées, la dernière reste accessible
      if (firstActiveLessonIndex == -1 && level.lessons.isNotEmpty) {
        firstActiveLessonIndex = level.lessons.length - 1;
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Bannière d'Unité Duolingo (Section Header)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isLevelUnlocked ? themeColor : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isLevelUnlocked ? themeDarkColor : Colors.grey.shade600,
                offset: const Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECTION ${_selectedLevelIndex + 1} • ${level.cefrTag}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLevelUnlocked
                          ? level.subtitle
                          : '🔒 Verrouillé • Obtenez 80% à l\'examen précédent',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$completedCount/${level.lessons.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Le Chemin Sinueux Duolingo ("Snake Path")
        ...List.generate(level.lessons.length, (i) {
          final lesson = level.lessons[i];
          final isDone = profile.completedLessons.contains(lesson.id);
          final isActive = isLevelUnlocked && (i == firstActiveLessonIndex);
          final isLocked = !isLevelUnlocked || (!isDone && !isActive && (i > firstActiveLessonIndex));

          NodeStatus nodeStatus;
          if (isDone) {
            nodeStatus = NodeStatus.completed;
          } else if (isActive) {
            nodeStatus = NodeStatus.active;
          } else {
            nodeStatus = NodeStatus.locked;
          }

          // Ondulation sinusoïdale Duolingo (S-curve)
          // 0 -> center, 1 -> right, 2 -> far right, 3 -> right, 4 -> center, 5 -> left...
          final double xOffset = math.sin(i * 0.9) * 65.0;

          // Présence de Coach Sarah toutes les 5 leçons sur le bord opposé
          final bool showSarahCheer = (i % 5 == 2);
          final bool sarahOnRight = xOffset < 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Mascotte Coach Sarah en bordure encourageant l'élève
                if (showSarahCheer)
                  Positioned(
                    left: sarahOnRight ? null : 8,
                    right: sarahOnRight ? 8 : null,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.duoGrey, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.duoGrey,
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              width: 22,
                              height: 22,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            i == 2 ? 'Great start!' : 'Keep going!',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.duoTextDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Nœud ondulant le long du Snake Path
                Transform.translate(
                  offset: Offset(xOffset, 0),
                  child: Column(
                    children: [
                      TactileLessonNode(
                        lessonNumber: i + 1,
                        title: lesson.title,
                        status: nodeStatus,
                        speechBubbleText: isActive ? 'START !' : null,
                        onTap: () {
                          if (isLocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.duoRed,
                                content: Text(
                                  !isLevelUnlocked
                                      ? '🔒 Le niveau ${level.id} est verrouillé ! Validez d\'abord le niveau précédent avec 80%.'
                                      : '🔒 Terminez d\'abord la leçon ${firstActiveLessonIndex + 1} pour débloquer celle-ci !',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LessonQuizScreen(lesson: lesson),
                            ),
                          );
                        },
                      ),
                      // Titre court sous le nœud
                      Container(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          lesson.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                            color: isLocked ? AppColors.duoTextMuted : AppColors.duoTextDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 36),

        // Nœud de fin d'unité : Grand Examen / Checkpoint Trophy Duolingo
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed
                      ? AppColors.duoGold
                      : (isExamUnlocked ? themeColor : AppColors.duoGreyLight),
                  border: Border.all(
                    color: isPassed
                        ? AppColors.duoGoldDark
                        : (isExamUnlocked ? themeDarkColor : AppColors.duoGrey),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPassed
                          ? AppColors.duoGoldDark
                          : (isExamUnlocked ? themeDarkColor : AppColors.duoGreyDark),
                      offset: const Offset(0, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: IconButton(
                  iconSize: 44,
                  icon: Icon(
                    isPassed
                        ? Icons.workspace_premium_rounded
                        : (isExamUnlocked ? Icons.flag_circle_rounded : Icons.lock_rounded),
                    color: isExamUnlocked || isPassed ? Colors.white : AppColors.duoGreyDark,
                  ),
                  onPressed: () {
                    if (!isLevelUnlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.duoRed,
                          content: Text('🔒 Ce niveau est encore verrouillé !'),
                        ),
                      );
                      return;
                    }

                    if (!isExamUnlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.duoOrangeDark,
                          content: Text(
                            '🔒 Terminez toutes les leçons ($completedCount/${level.lessons.length}) pour débloquer cet examen !',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EvaluationScreen(level: level),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ÉVALUATION FINALE ${level.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.duoTextDark,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                isPassed
                    ? 'Validé avec succès ($lastScore%) ⭐'
                    : (isExamUnlocked
                        ? 'Seuil de passage : 80% requis'
                        : 'Terminez les ${level.lessons.length} leçons pour débloquer'),
                style: TextStyle(
                  fontSize: 12,
                  color: isPassed ? AppColors.duoGreenDark : AppColors.duoTextMuted,
                  fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 16),
              if (isExamUnlocked)
                SizedBox(
                  width: 220,
                  child: TactileButton(
                    text: isPassed ? 'REPASSER L\'EXAMEN' : 'PASSER L\'EXAMEN',
                    type: isPassed ? TactileButtonType.gold : TactileButtonType.primary,
                    height: 44,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EvaluationScreen(level: level),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMasterExamCard(BuildContext context, UserProfile profile, bool isMasterUnlocked) {
    final bool isCertified = profile.isCertified;
    final int? score = profile.masterExamScore;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isCertified ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCertified ? AppColors.duoGold : Colors.blueGrey.shade700,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF020617),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCertified ? AppColors.duoGold : Colors.white.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    isCertified ? '🏆' : (!isMasterUnlocked ? '🔒' : '👑'),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCertified
                          ? 'CERTIFICATION OFFICIELLE C1'
                          : 'GRAND EXAMEN DE MAÎTRISE',
                      style: TextStyle(
                        color: isCertified ? AppColors.duoGold : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCertified
                          ? 'Score validé : $score% • Diplôme prêt'
                          : (!isMasterUnlocked
                              ? 'Validez les 6 niveaux (A0 à C1) à 80%'
                              : 'Épreuve d\'excellence finale'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            isCertified
                ? 'Félicitations ! Vous avez validé avec succès l\'ensemble des 6 niveaux de Sawki English (de Fondations Zéro à Maîtrise Bilingue C1). Votre certificat officiel atteste de votre bilinguisme américain.'
                : (!isMasterUnlocked
                    ? 'Ce test prestigieux couronne l\'ensemble du cursus Sawki English. Validez tous les niveaux (A0, A1, A2, B1, B2, C1) avec au moins 80% pour débloquer l\'épreuve finale.'
                    : 'Ce test exhaustif met à l\'épreuve l\'ensemble de vos compétences : compréhension orale US native, fluidité spontanée, phrasal verbs et leadership. Un score de 80% est requis pour décrocher la certification.'),
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          TactileButton(
            text: isCertified
                ? 'VOIR & TÉLÉCHARGER MON DIPLÔME 📜'
                : (!isMasterUnlocked ? 'DÉBLOQUER VIA LES NIVEAUX 🔒' : 'COMMENCER LE GRAND EXAMEN 🚀'),
            type: isCertified
                ? TactileButtonType.gold
                : (!isMasterUnlocked ? TactileButtonType.neutral : TactileButtonType.primary),
            onPressed: () {
              if (isCertified) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CertificateScreen(profile: profile),
                  ),
                );
              } else if (!isMasterUnlocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.duoRed,
                    content: Text(
                      '🔒 Le Grand Examen est verrouillé ! Validez d\'abord les examens de tous les niveaux avec au moins 80%.',
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MasterExamScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
