import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/mistake_item.dart';

class StorageService {
  static const String _profileBoxName = 'sawki_profile_box';
  static const String _mistakesBoxName = 'sawki_mistakes_box';
  static const String _settingsBoxName = 'sawki_settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_profileBoxName);
    await Hive.openBox(_mistakesBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  // --- PROFIL UTILISATEUR ---
  static UserProfile getUserProfile() {
    final box = Hive.box(_profileBoxName);
    final data = box.get('current_user');
    if (data != null && data is Map) {
      return UserProfile.fromMap(Map<String, dynamic>.from(data));
    }
    // Profil par défaut
    return UserProfile(
      name: '',
      targetGoal: 'Parler couramment en anglais américain',
      currentLevel: 'A1',
      xp: 0,
      streakDays: 1,
      lastActiveDate: DateTime.now(),
      energyCredits: 3,
    );
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    final box = Hive.box(_profileBoxName);
    await box.put('current_user', profile.toMap());
  }

  // --- SUIVI INTELLIGENT DES LACUNES (MISTAKES) ---
  static List<MistakeItem> getMistakes() {
    final box = Hive.box(_mistakesBoxName);
    final List<MistakeItem> list = [];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item is Map) {
        list.add(MistakeItem.fromMap(Map<String, dynamic>.from(item)));
      }
    }
    // Trier par nombre d'occurrences (les lacunes les plus fréquentes en premier)
    list.sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount));
    return list;
  }

  static Future<void> recordMistake({
    required String originalText,
    required String correctedText,
    required String errorType,
    required String explanationFr,
  }) async {
    final box = Hive.box(_mistakesBoxName);
    // Vérifier si cette faute a déjà été enregistrée
    final existingKey = box.keys.firstWhere(
      (k) {
        final val = box.get(k);
        return val is Map &&
            val['originalText']?.toString().toLowerCase().trim() ==
                originalText.toLowerCase().trim();
      },
      orElse: () => null,
    );

    if (existingKey != null) {
      final map = Map<String, dynamic>.from(box.get(existingKey));
      final count = (map['occurrenceCount'] as int? ?? 1) + 1;
      map['occurrenceCount'] = count;
      map['lastSeen'] = DateTime.now().toIso8601String();
      map['mastered'] = false; // Réactiver la lacune si refaite
      await box.put(existingKey, map);
    } else {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newItem = MistakeItem(
        id: id,
        originalText: originalText,
        correctedText: correctedText,
        errorType: errorType,
        explanationFr: explanationFr,
        occurrenceCount: 1,
        lastSeen: DateTime.now(),
        mastered: false,
      );
      await box.put(id, newItem.toMap());
    }
  }

  static Future<void> markMistakeMastered(String mistakeId) async {
    final box = Hive.box(_mistakesBoxName);
    final data = box.get(mistakeId);
    if (data != null && data is Map) {
      final map = Map<String, dynamic>.from(data);
      map['mastered'] = true;
      await box.put(mistakeId, map);
    }
  }

  // --- CLÉ API GEMINI & PARAMÈTRES ---
  static String? getApiKey() {
    final box = Hive.box(_settingsBoxName);
    return box.get('gemini_api_key');
  }

  static Future<void> saveApiKey(String apiKey) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('gemini_api_key', apiKey.trim());
  }

  static bool isOnboardingCompleted() {
    final box = Hive.box(_settingsBoxName);
    return box.get('onboarding_completed') == true;
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('onboarding_completed', completed);
  }

  static DateTime? getLastBackupDate() {
    final box = Hive.box(_settingsBoxName);
    final val = box.get('last_backup_date');
    if (val is String) {
      return DateTime.tryParse(val);
    }
    return null;
  }

  static Future<void> saveLastBackupDate(DateTime date) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('last_backup_date', date.toIso8601String());
  }

  // --- THÈME D'AFFICHAGE (Clair / Sombre / Système) ---
  static String getThemeMode() {
    final box = Hive.box(_settingsBoxName);
    return (box.get('theme_mode') as String?) ?? 'system';
  }

  static Future<void> saveThemeMode(String mode) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('theme_mode', mode);
  }

  // --- RAPPEL QUOTIDIEN (Notifications locales) ---
  static bool isDailyReminderEnabled() {
    final box = Hive.box(_settingsBoxName);
    return (box.get('daily_reminder_enabled') as bool?) ?? false;
  }

  static Future<void> saveDailyReminderEnabled(bool enabled) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('daily_reminder_enabled', enabled);
  }

  static int getDailyReminderHour() {
    final box = Hive.box(_settingsBoxName);
    return (box.get('daily_reminder_hour') as int?) ?? 19;
  }

  static int getDailyReminderMinute() {
    final box = Hive.box(_settingsBoxName);
    return (box.get('daily_reminder_minute') as int?) ?? 0;
  }

  static Future<void> saveDailyReminderTime(int hour, int minute) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('daily_reminder_hour', hour);
    await box.put('daily_reminder_minute', minute);
  }

  // --- CERTIFICATION NOM COMPLET OFFICIEL & SCELLEMENT ---
  static String? getCertificateFullName() {
    final box = Hive.box(_settingsBoxName);
    return box.get('certificate_full_name') as String?;
  }

  static Future<void> saveCertificateFullName(String fullName) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('certificate_full_name', fullName.trim());
  }

  static String? getCertificateCredentialId() {
    final box = Hive.box(_settingsBoxName);
    return box.get('certificate_credential_id') as String?;
  }

  static bool isCertificateSealed() {
    final box = Hive.box(_settingsBoxName);
    return box.get('certificate_is_sealed') == true;
  }

  static Future<void> sealCertificate({
    required String fullName,
    required String credentialId,
  }) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('certificate_full_name', fullName.trim());
    await box.put('certificate_credential_id', credentialId.trim());
    await box.put('certificate_is_sealed', true);
  }

  // --- DÉCONNEXION & RÉINITIALISATION DE L'APPAREIL ---
  /// Supprime toutes les données locales de l'appareil pour permettre
  /// une déconnexion propre ou la cession du téléphone à une autre personne.
  static Future<void> resetAllData() async {
    final profileBox = Hive.box(_profileBoxName);
    final mistakesBox = Hive.box(_mistakesBoxName);
    final settingsBox = Hive.box(_settingsBoxName);

    await profileBox.clear();
    await mistakesBox.clear();
    await settingsBox.put('onboarding_completed', false);
    await settingsBox.delete('last_backup_date');
  }
}
