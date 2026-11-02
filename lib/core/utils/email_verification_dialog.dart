import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../services/auth_service.dart';

/// Boîte de dialogue partagée : associer son email ou récupérer son compte.
///
/// 1. L'utilisateur saisit son email : Supabase lui envoie un code à 6 chiffres.
/// 2. Il saisit le code : la session est ouverte, puis la progression cloud est
///    récupérée et fusionnée avec celle de l'appareil.
///
/// Renvoie `true` si l'email a été vérifié et la progression restaurée.
Future<bool> showEmailVerificationDialog(
  BuildContext context,
  AppStateProvider provider, {
  bool restoreMode = false,
}) async {
  final emailController = TextEditingController(text: provider.profile.email ?? '');
  final codeController = TextEditingController();
  int step = 1;
  bool busy = false;
  String? error;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> onSubmit() async {
            if (busy) return;
            final email = emailController.text.trim().toLowerCase();
            if (step == 1) {
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                setState(() => error = 'Veuillez entrer une adresse email valide.');
                return;
              }
              setState(() {
                busy = true;
                error = null;
              });
              final sent = await provider.sendEmailCode(email);
              setState(() {
                busy = false;
                if (sent) {
                  step = 2;
                } else {
                  error = 'Envoi impossible. Vérifiez votre connexion ou réessayez dans une minute.';
                }
              });
            } else {
              final code = codeController.text.trim();
              if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                setState(() => error = 'Le code contient 6 chiffres.');
                return;
              }
              setState(() {
                busy = true;
                error = null;
              });
              final res = await provider.verifyEmailCodeAndRestore(email, code);
              if (res == EmailCodeResult.success) {
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                return;
              }
              setState(() {
                busy = false;
                error = res == EmailCodeResult.invalidCode
                    ? 'Code incorrect ou expiré. Vérifiez votre email ou renvoyez un code.'
                    : 'Connexion impossible. Vérifiez votre accès à internet.';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  step == 1
                      ? (restoreMode ? Icons.cloud_download : Icons.email_outlined)
                      : Icons.verified_user_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step == 1
                        ? (restoreMode ? 'Récupérer mon compte' : 'Associer mon email')
                        : 'Code de confirmation',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step == 1) ...[
                  Text(
                    restoreMode
                        ? 'Entrez l\'email de votre compte. Nous vous envoyons un code pour récupérer vos leçons, XP et niveau.'
                        : 'Entrez votre email pour sauvegarder vos progrès. Nous vous envoyons un code de confirmation.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    enabled: !busy,
                    decoration: InputDecoration(
                      labelText: 'Adresse email',
                      hintText: 'exemple@gmail.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Un code à 6 chiffres a été envoyé à ${emailController.text.trim()}. Pensez à regarder dans les spams.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    enabled: !busy,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      labelText: 'Code de vérification',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                                step = 1;
                                codeController.clear();
                                error = null;
                              }),
                      child: const Text('Changer d\'email ou renvoyer un code'),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: busy ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(step == 1 ? 'Recevoir le code' : 'Confirmer'),
              ),
            ],
          );
        },
      );
    },
  );

  emailController.dispose();
  codeController.dispose();

  final ok = result == true;
  if (ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        content: Text(
          restoreMode
              ? '🎉 Bon retour ${provider.profile.name} ! Vos progrès (${provider.profile.xp} XP, niveau ${provider.profile.currentLevel}) sont restaurés.'
              : '🎉 Email vérifié ! Vos progrès sont sauvegardés.',
        ),
      ),
    );
  }
  return ok;
}
