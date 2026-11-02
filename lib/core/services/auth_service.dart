import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Résultat d'une vérification de code email.
enum EmailCodeResult { success, invalidCode, networkError }

/// Gestion de la session Supabase.
///
/// - Au premier lancement, l'app ouvre une session anonyme : chaque appareil a
///   ainsi un identifiant serveur, utilisé pour la limite quotidienne de l'IA.
/// - Pour sauvegarder ou récupérer sa progression, l'utilisateur prouve son
///   email avec un code à 6 chiffres envoyé par Supabase.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _initialized = false;

  bool get isAvailable => _initialized;

  SupabaseClient? get client => _initialized ? Supabase.instance.client : null;

  User? get currentUser => client?.auth.currentUser;

  /// Email vérifié de la session en cours (null pour une session anonyme).
  String? get verifiedEmail {
    final user = currentUser;
    if (user == null || user.isAnonymous) return null;
    final email = user.email?.trim().toLowerCase();
    return (email == null || email.isEmpty) ? null : email;
  }

  Future<void> init() async {
    if (_initialized || !AppConfig.isSupabaseConfigured) return;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
  }

  /// Ouvre une session anonyme si aucune session n'existe (sans bloquer l'app hors ligne).
  Future<bool> ensureSession() async {
    final c = client;
    if (c == null) return false;
    if (c.auth.currentSession != null) return true;
    try {
      await c.auth.signInAnonymously();
      return true;
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      return false;
    }
  }

  /// Envoie un code de connexion à 6 chiffres à cette adresse.
  Future<bool> sendEmailCode(String email) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
        shouldCreateUser: true,
      );
      return true;
    } catch (e) {
      debugPrint('sendEmailCode failed: $e');
      return false;
    }
  }

  /// Vérifie le code reçu par email et ouvre la session de cet utilisateur.
  Future<EmailCodeResult> verifyEmailCode(String email, String code) async {
    final c = client;
    if (c == null) return EmailCodeResult.networkError;
    try {
      final res = await c.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: code.trim(),
        type: OtpType.email,
      );
      return res.session != null ? EmailCodeResult.success : EmailCodeResult.invalidCode;
    } on AuthException catch (e) {
      debugPrint('verifyEmailCode refused: ${e.message}');
      return EmailCodeResult.invalidCode;
    } catch (e) {
      debugPrint('verifyEmailCode failed: $e');
      return EmailCodeResult.networkError;
    }
  }

  /// Supprime définitivement le compte côté serveur (profil, usage IA, compte Auth).
  Future<bool> deleteAccount() async {
    final c = client;
    if (c == null || c.auth.currentSession == null) return false;
    try {
      final res = await c.functions.invoke('delete-account');
      if (res.status == 200) {
        await c.auth.signOut();
        // Repartir sur une nouvelle session anonyme propre.
        await ensureSession();
        return true;
      }
      debugPrint('delete-account status: ${res.status}');
    } catch (e) {
      debugPrint('deleteAccount failed: $e');
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      await client?.auth.signOut();
    } catch (e) {
      debugPrint('signOut failed: $e');
    }
  }
}
