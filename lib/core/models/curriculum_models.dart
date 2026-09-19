enum ExerciseType {
  dictation, // Dictée américaine (écoute l'audio US, écris le texte)
  multipleChoice, // QCM classique avec règle expliquée
  sentenceBuilder, // Réorganisation des mots dans l'ordre de la syntaxe US
  oralRepetition, // Écoute et prononce au micro
  translation, // Traduction ciblée Français -> Anglais US
}

class QuizQuestion {
  final String id;
  final ExerciseType type;
  final String prompt; // Consigne
  final String? audioText; // Texte prononcé par le TTS
  final List<String>? options; // Options pour QCM
  final String correctAnswer; // Bonne réponse
  final List<String>? scrambledWords; // Mots désordonnés pour sentenceBuilder
  final String explanationFr; // Explication pédagogique en français
  final String? phoneticHint; // Indice phonétique US (ex: /wɔːtər/)

  QuizQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    this.audioText,
    this.options,
    required this.correctAnswer,
    this.scrambledWords,
    required this.explanationFr,
    this.phoneticHint,
  });
}

class Lesson {
  final String id;
  final String levelId; // A1, A2, B1, B2, C1
  final String title;
  final String description;
  final String category; // 'Conversation', 'Grammaire US', 'Vocabulaire', 'Écoute'
  final List<QuizQuestion> questions;
  final int xpReward;

  Lesson({
    required this.id,
    required this.levelId,
    required this.title,
    required this.description,
    required this.category,
    required this.questions,
    this.xpReward = 20,
  });
}

class LevelCurriculum {
  final String id; // A1, A2, B1, B2, C1
  final String name;
  final String subtitle;
  final String cefrTag;
  final int requiredPassingScore; // 80% par défaut selon le cahier des charges
  final List<Lesson> lessons;
  final List<QuizQuestion> evaluationQuestions; // Examen final (oral + écrit)

  LevelCurriculum({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.cefrTag,
    this.requiredPassingScore = 80,
    required this.lessons,
    required this.evaluationQuestions,
  });
}
