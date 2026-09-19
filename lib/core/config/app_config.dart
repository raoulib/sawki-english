import 'package:flutter/foundation.dart';

/// Configuration globale de l'application Sawki English.
///
/// ⚠️ SÉCURITÉ : Les clés API sont injectées au build via --dart-define.
/// Exemple : flutter run --dart-define=GEMINI_API_KEY=votre_cle
///
/// Ne JAMAIS committer de clés en dur dans ce fichier.
class AppConfig {
  /// Clé API Google AI Studio — injectée via --dart-define=GEMINI_API_KEY=...
  static const String defaultGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Vérifie si la clé Gemini est configurée
  static bool get isGeminiConfigured => defaultGeminiApiKey.isNotEmpty;

  /// Modèle Gemini utilisé par défaut
  static const String geminiModel = 'gemini-3.6-flash';

  /// Nom de l'application
  static const String appName = 'Sawki English';

  /// Version de l'application
  static const String appVersion = '1.0.0';

  /// Éditeur & Copyright
  static const String organization = 'Sawki Group';
  static const String copyright = '© 2026 Sawki Group. Tous droits réservés.';
  static const String poweredBy = 'Propulsé par Sawki Group';

  /// Configuration Supabase Cloud Sync — injectée via --dart-define
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Vérifie si Supabase est configuré
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Affiche les avertissements de configuration en mode debug
  static void validateConfig() {
    if (kDebugMode) {
      if (!isGeminiConfigured) {
        debugPrint('⚠️ GEMINI_API_KEY non configurée. Utilisez --dart-define=GEMINI_API_KEY=votre_cle');
      }
      if (!isSupabaseConfigured) {
        debugPrint('⚠️ SUPABASE_URL/SUPABASE_ANON_KEY non configurées.');
      }
    }
  }
}
