import 'package:flutter/foundation.dart';

/// Configuration globale de l'application Sawki English.
///
/// ⚠️ SÉCURITÉ : aucune clé secrète ne doit figurer dans l'application.
/// Seules l'URL Supabase et la clé publique (anon / publishable) y sont,
/// et elles sont faites pour être publiques : la protection vient des règles RLS.
class AppConfig {
  // La clé Gemini n'est PAS dans l'application : elle est stockée comme secret
  // de la fonction Supabase « gemini » (voir supabase/README.md).

  /// Nom de l'application
  static const String appName = 'Sawki English';

  /// Version de l'application
  static const String appVersion = '1.0.0';

  /// Éditeur & Copyright
  static const String organization = 'Sawki Group';
  static const String copyright = '© 2026 Sawki Group. Tous droits réservés.';
  static const String poweredBy = 'Propulsé par Sawki Group';

  /// URL publique officielle de la politique de confidentialité (Google Play Store)
  static const String privacyPolicyUrl =
      'https://raoulib.github.io/sawki-english/';

  /// Configuration Supabase Cloud Sync
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bkptrqfcnbnlodzyvrjs.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_WAdjJ20CCQTyxbLMp0-E3g_7T3mpQ8G',
  );

  /// Vérifie si Supabase est configuré
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Affiche les avertissements de configuration en mode debug
  static void validateConfig() {
    if (kDebugMode && !isSupabaseConfigured) {
      debugPrint('⚠️ SUPABASE_URL/SUPABASE_ANON_KEY non configurées.');
    }
  }
}
