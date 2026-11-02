import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../config/monetization_config.dart';
import 'storage_service.dart';
import 'auth_service.dart';

/// Service de sauvegarde et synchronisation de la progression de l'apprenant.
/// Intègre Supabase Cloud et la Clé Portable Sawki (double couche de sécurité).
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  // --- SUPABASE CLOUD ---
  //
  // Chaque profil appartient à un utilisateur Supabase Auth. Les règles RLS
  // (supabase/migrations) garantissent que chacun ne lit et n'écrit que sa
  // propre ligne. Le serveur remplit lui-même user_id, email et is_premium.

  /// Synchronise le profil de l'apprenant sur Supabase Cloud.
  /// Ne fait rien tant que l'email n'a pas été vérifié par code.
  Future<bool> syncProfileToSupabase(UserProfile profile) async {
    final auth = AuthService();
    final client = auth.client;
    if (client == null || auth.verifiedEmail == null) {
      debugPrint("Supabase sync skipped: no verified email session.");
      return false;
    }

    try {
      await client.from('user_profiles').upsert({
        'user_id': auth.currentUser!.id,
        'name': profile.name,
        'current_level': profile.currentLevel,
        'target_goal': profile.targetGoal,
        'xp': profile.xp,
        'streak_days': profile.streakDays,
        'completed_lessons': profile.completedLessons,
        'evaluation_scores': profile.evaluationScores,
        'master_exam_score': profile.masterExamScore,
        'is_certified': profile.isCertified,
      }, onConflict: 'user_id');
      await StorageService.saveLastBackupDate(DateTime.now());
      debugPrint("✅ Cloud sync success (${profile.xp} XP, Level ${profile.currentLevel})");
      return true;
    } catch (e) {
      debugPrint("❌ Cloud sync error: $e");
      return false;
    }
  }

  /// À appeler juste après la vérification du code email : reprend un éventuel
  /// ancien profil, le fusionne avec la progression locale et sauvegarde le tout.
  Future<UserProfile?> pullAndMergeAfterSignIn() async {
    final auth = AuthService();
    final client = auth.client;
    final email = auth.verifiedEmail;
    if (client == null || email == null) return null;

    try {
      // Reprend une ligne créée par une ancienne version (repérée par l'email).
      await client.rpc('claim_legacy_profile');

      final row = await client
          .from('user_profiles')
          .select()
          .eq('user_id', auth.currentUser!.id)
          .maybeSingle();

      final localProfile = StorageService.getUserProfile();
      final merged = row == null
          ? localProfile.copyWith(email: email, isEmailVerified: true)
          : mergeProfiles(localProfile, fromSupabaseRow(row))
              .copyWith(email: email, isEmailVerified: true);

      await StorageService.saveUserProfile(merged);
      await StorageService.setOnboardingCompleted(true);
      await syncProfileToSupabase(merged);
      debugPrint("✅ Profile restored and merged for: ${merged.name}");
      return merged;
    } catch (e) {
      debugPrint("❌ Supabase restore error: $e");
      return null;
    }
  }

  /// Fusionne intelligemment un profil local et un profil cloud pour ne JAMAIS perdre de progrès.
  static UserProfile mergeProfiles(UserProfile local, UserProfile cloud) {
    final allLessons = <String>{...local.completedLessons, ...cloud.completedLessons}.toList();
    final allScores = Map<String, int>.from(local.evaluationScores);
    cloud.evaluationScores.forEach((lvl, score) {
      final current = allScores[lvl] ?? 0;
      if (score > current) {
        allScores[lvl] = score;
      }
    });

    const levels = ['A0', 'A1', 'A2', 'B1', 'B2', 'C1'];
    final localLvlIdx = levels.indexOf(local.currentLevel.toUpperCase());
    final cloudLvlIdx = levels.indexOf(cloud.currentLevel.toUpperCase());
    final highestLevel = (cloudLvlIdx > localLvlIdx && cloudLvlIdx >= 0)
        ? cloud.currentLevel
        : (localLvlIdx >= 0 ? local.currentLevel : cloud.currentLevel);

    final localExam = local.masterExamScore ?? 0;
    final cloudExam = cloud.masterExamScore ?? 0;

    return cloud.copyWith(
      name: cloud.name.isNotEmpty ? cloud.name : local.name,
      currentLevel: highestLevel,
      targetGoal: cloud.targetGoal.isNotEmpty ? cloud.targetGoal : local.targetGoal,
      xp: cloud.xp > local.xp ? cloud.xp : local.xp,
      streakDays: cloud.streakDays > local.streakDays ? cloud.streakDays : local.streakDays,
      completedLessons: allLessons,
      evaluationScores: allScores,
      masterExamScore: cloudExam > localExam ? cloud.masterExamScore : local.masterExamScore,
      isPremium: cloud.isPremium || local.isPremium,
      email: cloud.email ?? local.email,
    );
  }

  /// Convertit une ligne de base de données Supabase en UserProfile
  static UserProfile fromSupabaseRow(Map<String, dynamic> row) {
    return UserProfile(
      name: row['name']?.toString() ?? '',
      currentLevel: row['current_level']?.toString() ?? 'A0',
      targetGoal: row['target_goal']?.toString() ?? '',
      xp: (row['xp'] as num?)?.toInt() ?? 0,
      streakDays: (row['streak_days'] as num?)?.toInt() ?? 1,
      completedLessons: () {
        final raw = row['completed_lessons'];
        if (raw is List) {
          return raw.map((e) => e.toString()).toList();
        } else if (raw is Map) {
          return raw.keys.map((e) => e.toString()).toList();
        }
        return <String>[];
      }(),
      evaluationScores: () {
        final raw = row['evaluation_scores'];
        if (raw is Map) {
          return raw.map((k, v) => MapEntry(
                k.toString(),
                (v is num) ? v.toInt() : (int.tryParse(v.toString()) ?? 0),
              ));
        }
        return <String, int>{};
      }(),
      masterExamScore: (row['master_exam_score'] as num?)?.toInt() ?? 0,
      isPremium: row['is_premium'] == true,
      email: row['email']?.toString(),
      isEmailVerified: true,
    );
  }

  // --- CLÉ PORTABLE SAWKI (Sauvegarde manuelle / hors-ligne) ---

  /// Clé d'obfuscation statique pour protéger les données de récupération
  static const String _obfuscationSalt = 'SawkiEnglish2026SecureKey';

  /// Obfusque les données avec XOR + sel
  static List<int> _xorObfuscate(List<int> data) {
    final saltBytes = utf8.encode(_obfuscationSalt);
    return List<int>.generate(data.length, (i) => data[i] ^ saltBytes[i % saltBytes.length]);
  }

  /// Calcule un checksum simple pour vérifier l'intégrité
  static String _checksum(List<int> data) {
    int hash = 0;
    for (final b in data) {
      hash = (hash * 31 + b) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Génère une clé de récupération obfusquée (Sawki Recovery ID)
  static String generateRecoveryKey(UserProfile profile) {
    try {
      final map = profile.toMap();
      map['_app'] = 'Sawki English';
      map['_v'] = '2.0';
      map['_ts'] = DateTime.now().toIso8601String();

      final jsonStr = jsonEncode(map);
      final plainBytes = utf8.encode(jsonStr);

      // Calculer le checksum avant obfuscation
      final check = _checksum(plainBytes);

      // Obfusquer les données
      final obfuscated = _xorObfuscate(plainBytes);
      final b64 = base64Url.encode(obfuscated).replaceAll('=', '');

      return 'SAWKI-REC-$check-$b64';
    } catch (e) {
      debugPrint("Error generating recovery key: $e");
      return '';
    }
  }

  /// Décode et valide une clé de récupération obfusquée
  static UserProfile? parseRecoveryKey(String rawInput) {
    try {
      String clean = rawInput.trim();
      if (clean.startsWith('SAWKI-REC-')) {
        clean = clean.substring('SAWKI-REC-'.length);
      } else if (clean.startsWith('SAWKI-')) {
        clean = clean.substring('SAWKI-'.length);
      }

      // Extraire le checksum (8 premiers caractères hex + tiret)
      String? expectedChecksum;
      if (clean.length > 9 && clean[8] == '-') {
        expectedChecksum = clean.substring(0, 8);
        clean = clean.substring(9);
      }

      // Rétablir le padding Base64 manquant
      final remainder = clean.length % 4;
      if (remainder > 0) {
        clean += '=' * (4 - remainder);
      }

      final obfuscatedBytes = base64Url.decode(clean);

      // Déobfusquer les données
      final plainBytes = _xorObfuscate(obfuscatedBytes);

      // Vérifier l'intégrité si un checksum est présent
      if (expectedChecksum != null) {
        final actualChecksum = _checksum(plainBytes);
        if (actualChecksum != expectedChecksum) {
          debugPrint("Recovery key checksum mismatch: expected=$expectedChecksum actual=$actualChecksum");
          // Essayer quand même (pourrait être une ancienne clé v1 sans obfuscation)
          return _tryParseLegacyKey(rawInput);
        }
      }

      final jsonStr = utf8.decode(plainBytes);
      final data = jsonDecode(jsonStr);

      if (data is Map) {
        final profileMap = Map<String, dynamic>.from(data);
        return _sanitizeRestoredProfile(UserProfile.fromMap(profileMap));
      }
    } catch (e) {
      debugPrint("Error parsing recovery key v2, trying legacy format: $e");
      return _tryParseLegacyKey(rawInput);
    }
    return null;
  }

  /// Une clé de récupération est générée et lue sur le téléphone : son contenu
  /// peut donc être fabriqué à la main. On n'accorde jamais depuis une clé ce qui
  /// doit être vérifié ailleurs (abonnement, email vérifié, crédits IA).
  static UserProfile _sanitizeRestoredProfile(UserProfile p) {
    final credits = p.energyCredits > MonetizationConfig.dailyFreeEnergyBase
        ? MonetizationConfig.dailyFreeEnergyBase
        : p.energyCredits;
    return p.copyWith(
      isPremium: false,
      isEmailVerified: false,
      energyCredits: credits,
    );
  }

  /// Compatibilité avec les anciennes clés v1 (plain base64)
  static UserProfile? _tryParseLegacyKey(String rawInput) {
    try {
      String clean = rawInput.trim();
      if (clean.startsWith('SAWKI-REC-')) {
        clean = clean.substring('SAWKI-REC-'.length);
      } else if (clean.startsWith('SAWKI-')) {
        clean = clean.substring('SAWKI-'.length);
      }
      // Retirer un éventuel checksum v2
      if (clean.length > 9 && clean[8] == '-') {
        clean = clean.substring(9);
      }

      final remainder = clean.length % 4;
      if (remainder > 0) {
        clean += '=' * (4 - remainder);
      }

      final bytes = base64Url.decode(clean);
      final jsonStr = utf8.decode(bytes);
      final data = jsonDecode(jsonStr);

      if (data is Map) {
        return _sanitizeRestoredProfile(
            UserProfile.fromMap(Map<String, dynamic>.from(data)));
      }
    } catch (e) {
      debugPrint("Legacy recovery key also failed: $e");
    }
    return null;
  }

  /// Enregistre une sauvegarde du profil et met à jour la date de synchronisation
  Future<String> backupProfile(UserProfile profile) async {
    final key = generateRecoveryKey(profile);
    await StorageService.saveLastBackupDate(DateTime.now());
    // Déclenche également la synchro Supabase si l'email est présent
    await syncProfileToSupabase(profile);
    return key;
  }

  /// Restaure un profil sur cet appareil depuis une clé de récupération
  /// et sauvegarde automatiquement dans la mémoire locale Hive.
  Future<UserProfile?> restoreProfile(String recoveryKey) async {
    final profile = parseRecoveryKey(recoveryKey);
    if (profile != null) {
      await StorageService.saveUserProfile(profile);
      await StorageService.setOnboardingCompleted(true);
      await StorageService.saveLastBackupDate(DateTime.now());
      debugPrint("Profile successfully restored for: ${profile.name} (${profile.currentLevel}, ${profile.xp} XP)");
      return profile;
    }
    return null;
  }
}
