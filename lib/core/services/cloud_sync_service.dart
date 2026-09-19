import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

/// Service de sauvegarde et synchronisation de la progression de l'apprenant.
/// Intègre Supabase Cloud et la Clé Portable Sawki (double couche de sécurité).
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  // --- SUPABASE CLOUD REST API ---

  static Map<String, String> get _supabaseHeaders => {
    'apikey': AppConfig.supabaseAnonKey,
    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
    'Content-Type': 'application/json; charset=utf-8',
  };

  /// Synchronise le profil de l'apprenant sur Supabase Cloud
  Future<bool> syncProfileToSupabase(UserProfile profile) async {
    final email = profile.email?.trim().toLowerCase();
    if (email == null || email.isEmpty || !email.contains('@')) {
      debugPrint("Supabase sync skipped: No valid email associated.");
      return false;
    }

    try {
      final url = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/user_profiles?on_conflict=email');
      final body = jsonEncode({
        'email': email,
        'name': profile.name,
        'current_level': profile.currentLevel,
        'target_goal': profile.targetGoal,
        'xp': profile.xp,
        'streak_days': profile.streakDays,
        'completed_lessons': profile.completedLessons,
        'evaluation_scores': profile.evaluationScores,
        'master_exam_score': profile.masterExamScore,
        'is_certified': profile.isCertified,
        'is_premium': profile.isPremium,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final headers = Map<String, String>.from(_supabaseHeaders);
      headers['Prefer'] = 'resolution=merge-duplicates';

      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await StorageService.saveLastBackupDate(DateTime.now());
        debugPrint("✅ Cloud sync success for $email (${profile.xp} XP, Level ${profile.currentLevel})");
        return true;
      } else {
        debugPrint("❌ Cloud sync failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Cloud sync network error: $e");
      return false;
    }
  }

  /// Restaure un profil depuis Supabase Cloud en utilisant l'email
  Future<UserProfile?> fetchProfileFromSupabase(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) return null;

    try {
      final encodedEmail = Uri.encodeComponent(email);
      final url = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/user_profiles?email=eq.$encodedEmail&select=*');

      final response = await http.get(url, headers: _supabaseHeaders);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final row = Map<String, dynamic>.from(data.first);
          final profile = fromSupabaseRow(row);

          // Sauvegarde locale Hive
          await StorageService.saveUserProfile(profile);
          await StorageService.setOnboardingCompleted(true);
          await StorageService.saveLastBackupDate(DateTime.now());
          debugPrint("✅ Profile successfully restored from Supabase for: ${profile.name}");
          return profile;
        }
      } else {
        debugPrint("❌ Supabase fetch failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Supabase fetch error: $e");
    }
    return null;
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
        return UserProfile.fromMap(profileMap);
      }
    } catch (e) {
      debugPrint("Error parsing recovery key v2, trying legacy format: $e");
      return _tryParseLegacyKey(rawInput);
    }
    return null;
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
        return UserProfile.fromMap(Map<String, dynamic>.from(data));
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
