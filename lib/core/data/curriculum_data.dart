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

  /// Questions officielles de certification Master Sawki English
  /// Couvrant l'ensemble des compétences de A0 (fondations) à C1 (avancé)
  /// 5 questions par niveau = 30 questions au total pour une certification crédible
  static List<QuizQuestion> getMasterExamQuestions() {
    final questions = <QuizQuestion>[];
    for (final level in getLevels()) {
      // Prend toutes les questions d'évaluation de chaque palier (5 par niveau = 30 questions)
      questions.addAll(level.evaluationQuestions.take(5));
    }
    return questions;
  }
}
