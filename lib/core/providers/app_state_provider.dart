import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/mistake_item.dart';
import '../models/correction_feedback.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../services/gemini_service.dart';
import '../services/ad_service.dart';
import '../services/cloud_sync_service.dart';
import '../config/monetization_config.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final CorrectionFeedback? feedback;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.feedback,
  });
}

class AppStateProvider extends ChangeNotifier {
  late UserProfile _profile;
  List<MistakeItem> _mistakes = [];
  String _apiKey = '';

  // État audio & micro
  bool _isListening = false;
  double _soundLevel = 0.0;
  String _liveTranscription = '';
  String _sttLocale = 'en_US'; // 'en_US' ou 'fr_FR'

  // État conversation tuteur
  final List<ChatMessage> _messages = [];
  bool _isAiResponding = false;

  // État Thème (Clair / Sombre / Système)
  ThemeMode _themeMode = ThemeMode.system;

  // Getters
  UserProfile get profile => _profile;
  List<MistakeItem> get mistakes => _mistakes;
  String get apiKey => _apiKey;
  bool get isListening => _isListening;
  double get soundLevel => _soundLevel;
  String get liveTranscription => _liveTranscription;
  String get sttLocale => _sttLocale;
  List<ChatMessage> get messages => _messages;
  bool get isAiResponding => _isAiResponding;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    _profile = StorageService.getUserProfile();
    _mistakes = StorageService.getMistakes();
    _apiKey = StorageService.getApiKey() ?? '';

    final savedTheme = StorageService.getThemeMode();
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Initialiser les services audio
    await TtsService().init();
    await TtsService().setSpeedRate(_profile.speechRate);
    await SttService().init();
    await AdService().init();

    // Message d'accueil du tuteur si la boîte de discussion est vide
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          id: 'welcome_msg',
          text:
              "Hey ${_profile.name.isNotEmpty ? _profile.name : 'there'}! I'm Sarah, your American English coach. You can chat with me with your voice or type below. How's your day going?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
    await _checkDailyEnergyAndStreak();
    notifyListeners();
  }

  /// Recharge et synchronise le profil utilisateur, vérifie le bonus quotidien d'énergie et notifie l'UI.
  Future<void> refreshProfile() async {
    _profile = StorageService.getUserProfile();
    _mistakes = StorageService.getMistakes();
    _apiKey = StorageService.getApiKey() ?? '';
    await _checkDailyEnergyAndStreak();
    notifyListeners();
  }

  /// Gestion du Thème (Clair, Sombre, Système)
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await StorageService.saveThemeMode(modeStr);
    notifyListeners();
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentIsDark = Theme.of(context).brightness == Brightness.dark;
    if (currentIsDark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  Future<void> _checkDailyEnergyAndStreak() async {
    final now = DateTime.now();
    final lastActive = _profile.lastActiveDate;

    if (lastActive != null) {
      final isDifferentDay = now.year != lastActive.year ||
          now.month != lastActive.month ||
          now.day != lastActive.day;

      if (isDifferentDay) {
        final daysDiff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastActive.year, lastActive.month, lastActive.day))
            .inDays;

        int newStreak = _profile.streakDays;
        if (daysDiff == 1) {
          newStreak += 1;
        } else if (daysDiff > 1) {
          newStreak = 1;
        }

        // Recharger au moins le quota de base quotidien pour les non-premiums
        int updatedCredits = _profile.energyCredits;
        if (!_profile.isPremium && updatedCredits < MonetizationConfig.dailyFreeEnergyBase) {
          updatedCredits = MonetizationConfig.dailyFreeEnergyBase;
        }

        _profile = _profile.copyWith(
          streakDays: newStreak,
          lastActiveDate: now,
          energyCredits: updatedCredits,
        );
        await StorageService.saveUserProfile(_profile);
      }
    } else {
      _profile = _profile.copyWith(lastActiveDate: now);
      await StorageService.saveUserProfile(_profile);
    }
  }

  // --- MISE À JOUR DU PROFIL ---
  Future<void> updateProfile({
    String? name,
    String? targetGoal,
    String? currentLevel,
    bool? isPremium,
    double? speechRate,
  }) async {
    _profile = _profile.copyWith(
      name: name,
      targetGoal: targetGoal,
      currentLevel: currentLevel,
      isPremium: isPremium,
      speechRate: speechRate,
    );
    await StorageService.saveUserProfile(_profile);
    if (speechRate != null) {
      await TtsService().setSpeedRate(speechRate);
    }
    notifyListeners();
  }

  /// Sauvegarde le profil et retourne la clé de récupération Sawki
  Future<String> backupProfile() async {
    final key = await CloudSyncService().backupProfile(_profile);
    notifyListeners();
    return key;
  }

  /// Restaure un profil sur cet appareil à partir de sa clé de récupération
  Future<bool> restoreProfileFromKey(String recoveryKey) async {
    final restored = await CloudSyncService().restoreProfile(recoveryKey);
    if (restored != null) {
      _profile = restored;
      _mistakes = StorageService.getMistakes();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Restaure un profil directement depuis Supabase Cloud avec l'adresse email
  Future<bool> restoreFromCloudEmail(String email) async {
    final restored = await CloudSyncService().fetchProfileFromSupabase(email);
    if (restored != null) {
      _profile = restored;
      _mistakes = StorageService.getMistakes();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Force la synchronisation immédiate avec Supabase Cloud
  Future<bool> syncToCloud() async {
    final success = await CloudSyncService().syncProfileToSupabase(_profile);
    notifyListeners();
    return success;
  }

  /// Déconnecte le compte et efface les données locales de cet appareil
  Future<void> logoutAndReset() async {
    await StorageService.resetAllData();
    _profile = StorageService.getUserProfile();
    _mistakes = [];
    _messages.clear();
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    await StorageService.saveApiKey(_apiKey);
    notifyListeners();
  }

  // --- ENREGISTREMENT VOCAL (STT BILINGUE US/FR) ---
  void toggleSttLocale() {
    _sttLocale = (_sttLocale == 'en_US') ? 'fr_FR' : 'en_US';
    notifyListeners();
  }

  void setSttLocale(String locale) {
    _sttLocale = locale;
    notifyListeners();
  }

  Future<void> startVoiceRecording() async {
    _liveTranscription = '';
    _isListening = true;
    notifyListeners();

    await SttService().startListening(
      localeId: _sttLocale,
      onResult: (words, isFinal) {
        _liveTranscription = words;
        notifyListeners();
        if (isFinal && words.trim().isNotEmpty) {
          stopVoiceRecordingAndSend();
        }
      },
      onSoundLevelChange: (level) {
        _soundLevel = level;
        notifyListeners();
      },
    );
  }

  Future<void> stopVoiceRecordingAndSend() async {
    await SttService().stopListening();
    _isListening = false;
    final textToSend = _liveTranscription.trim();
    _liveTranscription = '';
    notifyListeners();

    if (textToSend.isNotEmpty) {
      await sendMessage(textToSend, isSpoken: true);
    }
  }

  Future<void> cancelVoiceRecording() async {
    await SttService().stopListening();
    _isListening = false;
    _liveTranscription = '';
    notifyListeners();
  }

  // --- ENVOI DE MESSAGE AU TUTEUR GEMINI ---
  Future<void> sendMessage(String text, {bool isSpoken = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Vérifier les crédits en mode gratuit
    if (!_profile.isPremium && _profile.energyCredits <= 0) {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text:
              "You've used all your free conversation energy for now! Watch a quick video to unlock 1 more session, or upgrade to Premium.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
      return;
    }

    // Déduire 1 crédit si non-premium
    if (!_profile.isPremium) {
      _profile = _profile.copyWith(
        energyCredits: (_profile.energyCredits - 1).clamp(0, 999),
      );
      await StorageService.saveUserProfile(_profile);
    }

    // Ajouter le message de l'utilisateur
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _isAiResponding = true;
    notifyListeners();

    // Préparer l'historique sans le dernier message utilisateur pour éviter tout doublon
    final previousMessages = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <ChatMessage>[];
    final history = previousMessages
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    // Appel à Gemini
    final response = await GeminiService.sendMessage(
      userMessage: trimmed,
      userLevel: _profile.currentLevel,
      apiKey: _apiKey,
      conversationHistory: history,
    );

    _isAiResponding = false;

    // Si une faute est détectée, l'enregistrer dans le traqueur de lacunes
    if (response.feedback.hasError) {
      await StorageService.recordMistake(
        originalText: response.feedback.originalSegment,
        correctedText: response.feedback.correctedSegment,
        errorType: response.feedback.errorType,
        explanationFr: response.feedback.explanationFr,
      );
      _mistakes = StorageService.getMistakes();
    }

    // Ajouter la réponse de l'IA
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response.replyEn,
        isUser: false,
        timestamp: DateTime.now(),
        feedback: response.feedback,
      ),
    );

    // Gagner des points d'XP pour la pratique
    _profile = _profile.copyWith(xp: _profile.xp + 10);
    await StorageService.saveUserProfile(_profile);

    notifyListeners();

    // Si la conversation a été initiée vocalement, prononcer la réponse en anglais US
    if (isSpoken) {
      await TtsService().speak(response.replyEn);
    }
  }

  // --- MONÉTISATION : REGARDER UNE PUB POUR OBTENIR DES CRÉDITS ET DES XP ---
  Future<void> watchAdForEnergy(BuildContext context) async {
    await AdService().showRewardedAd(
      context: context,
      onRewardEarned: () async {
        final newCredits =
            _profile.energyCredits + MonetizationConfig.rewardConversationsPerAd;
        final newXp = _profile.xp + 20; // 20 XP selon instruction utilisateur
        _profile = _profile.copyWith(
          energyCredits: newCredits,
          xp: newXp,
        );
        await StorageService.saveUserProfile(_profile);
        notifyListeners();

        // Pop-up automatique de confirmation (2.5 secondes)
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (popupCtx) {
              Future.delayed(const Duration(milliseconds: 2500), () {
                if (popupCtx.mounted) {
                  Navigator.of(popupCtx, rootNavigator: true).pop();
                }
              });
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Theme.of(popupCtx).dialogTheme.backgroundColor ?? Theme.of(popupCtx).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars, color: Color(0xFF16A34A), size: 40),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Succès ! Récompense Débloquée 🎉',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '+20 XP  •  +1 Session Tuteur',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nouveau Total : $newXp XP  |  $newCredits sessions',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<void> addXp(int amount) async {
    _profile = _profile.copyWith(xp: _profile.xp + amount);
    await StorageService.saveUserProfile(_profile);
    CloudSyncService().syncProfileToSupabase(_profile);
    notifyListeners();
  }

  // --- ENREGISTREMENT ET VÉRIFICATION D'EMAIL ---
  Future<void> saveUserEmail(String email, {bool isVerified = true}) async {
    _profile = _profile.copyWith(
      email: email.trim(),
      isEmailVerified: isVerified,
    );
    await StorageService.saveUserProfile(_profile);
    await CloudSyncService().syncProfileToSupabase(_profile);
    notifyListeners();
  }

  // --- LEÇONS & ÉVALUATIONS ---
  Future<void> completeLesson(String lessonId, int xpGained) async {
    final completed = List<String>.from(_profile.completedLessons);
    if (!completed.contains(lessonId)) {
      completed.add(lessonId);
    }
    _profile = _profile.copyWith(
      xp: _profile.xp + xpGained,
      completedLessons: completed,
    );
    await StorageService.saveUserProfile(_profile);
    CloudSyncService().syncProfileToSupabase(_profile);
    notifyListeners();
  }

  /// Enregistre le score d'évaluation d'un niveau.
  /// Seuil de réussite à 80% fixé par le cahier des charges !
  /// Si ce niveau était celui qui verrouillait le Grand Examen, la validation le déverrouille !
  Future<bool> submitEvaluation(String levelId, int scorePercent) async {
    final scores = Map<String, int>.from(_profile.evaluationScores);
    scores[levelId] = scorePercent;

    bool passed = scorePercent >= 80;
    String newLevel = _profile.currentLevel;

    if (passed) {
      // Déblocage du niveau suivant
      if (levelId == 'A0') newLevel = 'A1';
      if (levelId == 'A1') newLevel = 'A2';
      if (levelId == 'A2') newLevel = 'B1';
      if (levelId == 'B1') newLevel = 'B2';
      if (levelId == 'B2') newLevel = 'C1';
    }

    // Si l'élève a comblé ses lacunes et revalidé le niveau qui bloquait le Grand Examen :
    int updatedFailures = _profile.masterExamFailedAttempts;
    String? updatedLockedLevel = _profile.masterExamLockedLevel;
    if (passed &&
        _profile.masterExamLockedLevel?.toUpperCase() == levelId.toUpperCase()) {
      updatedFailures = 0;
      updatedLockedLevel = null;
    }

    _profile = _profile.copyWith(
      evaluationScores: scores,
      currentLevel: newLevel,
      masterExamFailedAttempts: updatedFailures,
      masterExamLockedLevel: updatedLockedLevel,
      xp: _profile.xp + (passed ? 100 : 20),
    );
    await StorageService.saveUserProfile(_profile);
    CloudSyncService().syncProfileToSupabase(_profile);
    notifyListeners();
    return passed;
  }

  /// Soumission du Grand Examen Final de Certification (Seuil : 80%)
  /// Si l'élève échoue 3 fois de suite, l'examen se verrouille
  /// et renvoie l'élève vers le palier où il a le plus de lacunes ([weakestLevel]).
  Future<bool> submitMasterExam(int scorePercent, {String? weakestLevel}) async {
    final bool passed = scorePercent >= 80;
    int newFailures = passed ? 0 : (_profile.masterExamFailedAttempts + 1);
    String? lockedLevel = passed ? null : _profile.masterExamLockedLevel;

    // Si 3 échecs consécutifs sont atteints, verrouillage automatique
    if (!passed && newFailures >= 3) {
      lockedLevel = weakestLevel ?? 'A1';
    }

    _profile = _profile.copyWith(
      masterExamScore: scorePercent,
      masterExamDate: passed ? DateTime.now() : _profile.masterExamDate,
      masterExamFailedAttempts: newFailures,
      masterExamLockedLevel: lockedLevel,
      xp: _profile.xp + (passed ? 250 : 50),
    );
    await StorageService.saveUserProfile(_profile);
    CloudSyncService().syncProfileToSupabase(_profile);
    notifyListeners();
    return passed;
  }
}
