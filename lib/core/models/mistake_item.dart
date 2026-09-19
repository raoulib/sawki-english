class MistakeItem {
  final String id;
  final String originalText;
  final String correctedText;
  final String errorType; // Grammaire, Vocabulaire, Orthographe, Prononciation, Syntaxe
  final String explanationFr;
  int occurrenceCount;
  DateTime lastSeen;
  bool mastered; // Vrai si l'utilisateur a réussi l'exercice de révision associé

  MistakeItem({
    required this.id,
    required this.originalText,
    required this.correctedText,
    required this.errorType,
    required this.explanationFr,
    this.occurrenceCount = 1,
    DateTime? lastSeen,
    this.mastered = false,
  }) : lastSeen = lastSeen ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalText': originalText,
      'correctedText': correctedText,
      'errorType': errorType,
      'explanationFr': explanationFr,
      'occurrenceCount': occurrenceCount,
      'lastSeen': lastSeen.toIso8601String(),
      'mastered': mastered,
    };
  }

  factory MistakeItem.fromMap(Map<String, dynamic> map) {
    return MistakeItem(
      id: map['id'] ?? '',
      originalText: map['originalText'] ?? '',
      correctedText: map['correctedText'] ?? '',
      errorType: map['errorType'] ?? 'Grammaire',
      explanationFr: map['explanationFr'] ?? '',
      occurrenceCount: map['occurrenceCount'] ?? 1,
      lastSeen: map['lastSeen'] != null
          ? DateTime.tryParse(map['lastSeen']) ?? DateTime.now()
          : DateTime.now(),
      mastered: map['mastered'] ?? false,
    );
  }
}
