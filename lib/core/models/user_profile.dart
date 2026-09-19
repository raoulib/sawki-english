class UserProfile {
  final String name;
  final String? email;
  final bool isEmailVerified;
  final String targetGoal;
  final String currentLevel; // A0, A1, A2, B1, B2, C1
  final int xp;
  final int streakDays;
  final DateTime? lastActiveDate;
  final bool isPremium;
  final int energyCredits; // Conversations IA disponibles
  final List<String> completedLessons;
  final Map<String, int> evaluationScores; // Level -> score %
  final double speechRate; // 0.6 = slow, 1.0 = normal, 1.2 = fast
  final int? masterExamScore; // Score au Grand Examen Final
  final DateTime? masterExamDate; // Date d'obtention de la certification

  bool get isCertified => (masterExamScore ?? 0) >= 80;

  UserProfile({
    required this.name,
    this.email,
    this.isEmailVerified = false,
    this.targetGoal = 'Parler avec fluidité',
    this.currentLevel = 'A0',
    this.xp = 0,
    this.streakDays = 1,
    this.lastActiveDate,
    this.isPremium = false,
    this.energyCredits = 3,
    List<String>? completedLessons,
    Map<String, int>? evaluationScores,
    this.speechRate = 1.0,
    this.masterExamScore,
    this.masterExamDate,
  })  : completedLessons = completedLessons ?? [],
        evaluationScores = evaluationScores ?? {};

  UserProfile copyWith({
    String? name,
    String? email,
    bool? isEmailVerified,
    String? targetGoal,
    String? currentLevel,
    int? xp,
    int? streakDays,
    DateTime? lastActiveDate,
    bool? isPremium,
    int? energyCredits,
    List<String>? completedLessons,
    Map<String, int>? evaluationScores,
    double? speechRate,
    int? masterExamScore,
    DateTime? masterExamDate,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      targetGoal: targetGoal ?? this.targetGoal,
      currentLevel: currentLevel ?? this.currentLevel,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isPremium: isPremium ?? this.isPremium,
      energyCredits: energyCredits ?? this.energyCredits,
      completedLessons: completedLessons ?? this.completedLessons,
      evaluationScores: evaluationScores ?? this.evaluationScores,
      speechRate: speechRate ?? this.speechRate,
      masterExamScore: masterExamScore ?? this.masterExamScore,
      masterExamDate: masterExamDate ?? this.masterExamDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'isEmailVerified': isEmailVerified,
      'targetGoal': targetGoal,
      'currentLevel': currentLevel,
      'xp': xp,
      'streakDays': streakDays,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'isPremium': isPremium,
      'energyCredits': energyCredits,
      'completedLessons': completedLessons,
      'evaluationScores': evaluationScores,
      'speechRate': speechRate,
      'masterExamScore': masterExamScore,
      'masterExamDate': masterExamDate?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? 'Apprenant',
      email: map['email'] as String?,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      targetGoal: map['targetGoal'] ?? 'Parler avec fluidité',
      currentLevel: map['currentLevel'] ?? 'A0',
      xp: map['xp'] ?? 0,
      streakDays: map['streakDays'] ?? 1,
      lastActiveDate: map['lastActiveDate'] != null
          ? DateTime.tryParse(map['lastActiveDate'])
          : null,
      isPremium: map['isPremium'] ?? false,
      energyCredits: map['energyCredits'] ?? 3,
      completedLessons: List<String>.from(map['completedLessons'] ?? []),
      evaluationScores: Map<String, int>.from(map['evaluationScores'] ?? {}),
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 1.0,
      masterExamScore: map['masterExamScore'] as int?,
      masterExamDate: map['masterExamDate'] != null
          ? DateTime.tryParse(map['masterExamDate'])
          : null,
    );
  }
}
