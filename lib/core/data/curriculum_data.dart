import '../models/curriculum_models.dart';
import 'curriculum/curriculum_a0.dart';
import 'curriculum/curriculum_a1.dart';
import 'curriculum/curriculum_a2.dart';
import 'curriculum/curriculum_b1.dart';
import 'curriculum/curriculum_b2.dart';
import 'curriculum/curriculum_c1.dart';

class CurriculumData {
  /// Retourne l'ensemble des 6 niveaux du cursus officiel Sawki English
  /// Chaque niveau comporte 20 leçons structurées (soit 120 leçons complètes au total)
  /// avec exercices interactifs de phonétique américaine, grammaire, dictée et syntaxe.
  static List<LevelCurriculum> getLevels() {
    return [
      CurriculumA0.getLevel(),
      CurriculumA1.getLevel(),
      CurriculumA2.getLevel(),
      CurriculumB1.getLevel(),
      CurriculumB2.getLevel(),
      CurriculumC1.getLevel(),
    ];
  }

  /// Liste des 6 niveaux
  static List<LevelCurriculum> get levels => getLevels();

  /// Recherche un niveau par son identifiant ('A0', 'A1', 'A2', 'B1', 'B2', 'C1')
  static LevelCurriculum? getLevelById(String id) {
    try {
      return getLevels().firstWhere((l) => l.id.toUpperCase() == id.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  /// Recherche une leçon spécifique par son identifiant unique
  static Lesson? getLessonById(String lessonId) {
    for (final level in getLevels()) {
      for (final lesson in level.lessons) {
        if (lesson.id == lessonId) {
          return lesson;
        }
      }
    }
    return null;
  }

  /// Questions officielles de certification Master Sawki English.
  /// Couvrant l'ensemble des compétences de A0 (fondations) à C1 (avancé).
  /// Tire 5 questions par niveau de manière équilibrée = 30 questions au total.
  /// Si [randomize] est activé, pioche dynamiquement dans les 630 questions du cursus
  /// et mélange l'ordre pour que chaque tentative d'examen soit unique et infalsifiable.
  static List<QuizQuestion> getMasterExamQuestions({int countPerLevel = 5, bool randomize = false}) {
    final questions = <QuizQuestion>[];
    for (final level in getLevels()) {
      final pool = <QuizQuestion>[];
      pool.addAll(level.evaluationQuestions);
      for (final lesson in level.lessons) {
        pool.addAll(lesson.questions);
      }

      if (randomize) {
        final shuffledPool = List<QuizQuestion>.from(pool)..shuffle();
        questions.addAll(shuffledPool.take(countPerLevel));
      } else {
        questions.addAll(level.evaluationQuestions.take(countPerLevel));
      }
    }

    if (randomize) {
      questions.shuffle();
    }
    return questions;
  }

  /// Génère un ensemble de questions d'examen dynamique et aléatoire pour un palier donné.
  /// Pioche parmi les questions d'évaluation et les 100 exercices des 20 leçons du niveau.
  static List<QuizQuestion> getEvaluationQuestionsForLevel(
    LevelCurriculum level, {
    int count = 10,
    bool randomize = false,
  }) {
    if (!randomize) {
      return List<QuizQuestion>.from(level.evaluationQuestions);
    }
    final pool = <QuizQuestion>[];
    pool.addAll(level.evaluationQuestions);
    for (final lesson in level.lessons) {
      pool.addAll(lesson.questions);
    }
    final shuffled = List<QuizQuestion>.from(pool)..shuffle();
    return shuffled.take(count).toList();
  }
}
