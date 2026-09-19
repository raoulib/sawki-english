class DailyIdiom {
  final String idiom;
  final String phonetic;
  final String meaningFr;
  final String exampleUs;
  final String exampleTranslationFr;
  final String culturalNote;

  const DailyIdiom({
    required this.idiom,
    required this.phonetic,
    required this.meaningFr,
    required this.exampleUs,
    required this.exampleTranslationFr,
    required this.culturalNote,
  });
}

class DailyIdiomsData {
  static const List<DailyIdiom> idioms = [
    DailyIdiom(
      idiom: "Hit the road",
      phonetic: "/hɪt ðə roʊd/",
      meaningFr: "Prendre la route, partir",
      exampleUs: "It's getting late, we'd better hit the road.",
      exampleTranslationFr: "Il commence à se faire tard, on ferait mieux de prendre la route.",
      culturalNote: "Très populaire aux USA pour annoncer qu'on s'en va sans formalisme.",
    ),
    DailyIdiom(
      idiom: "Piece of cake",
      phonetic: "/piːs əv keɪk/",
      meaningFr: "C'est du gâteau, un jeu d'enfant",
      exampleUs: "Don't worry about the interview, it's going to be a piece of cake!",
      exampleTranslationFr: "Ne t'en fais pas pour l'entretien, ce sera du gâteau !",
      culturalNote: "L'équivalent américain parfait de notre 'simple comme bonjour'.",
    ),
    DailyIdiom(
      idiom: "Call it a day",
      phonetic: "/kɔːl ɪt ə deɪ/",
      meaningFr: "S'arrêter là, plier bagage pour aujourd'hui",
      exampleUs: "We've made great progress today. Let's call it a day.",
      exampleTranslationFr: "On a bien avancé aujourd'hui. On s'arrête là pour aujourd'hui.",
      culturalNote: "Indispensable dans le monde du travail américain à la fin d'une réunion.",
    ),
    DailyIdiom(
      idiom: "Under the weather",
      phonetic: "/ˈʌn.dər ðə ˈweð.ər/",
      meaningFr: "Pas dans son assiette, un peu malade",
      exampleUs: "I'm feeling a little under the weather today, so I'll stay home.",
      exampleTranslationFr: "Je me sens un peu patraque aujourd'hui, donc je vais rester à la maison.",
      culturalNote: "Formule polie et courante pour s'excuser de son absence.",
    ),
    DailyIdiom(
      idiom: "Bite the bullet",
      phonetic: "/baɪt ðə ˈbʊl.ɪt/",
      meaningFr: "Serrer les dents, affronter une situation difficile",
      exampleUs: "I hate going to the dentist, but I just need to bite the bullet.",
      exampleTranslationFr: "Je déteste aller chez le dentiste, mais il faut que je serre les dents.",
      culturalNote: "Origine historique américaine : mordre une balle pour supporter une douleur.",
    ),
  ];

  static DailyIdiom getIdiomForToday() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return idioms[dayOfYear % idioms.length];
  }
}
