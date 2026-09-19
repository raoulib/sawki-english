import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';

/// Boîte de dialogue partagée pour l'association et la vérification de l'email
void showEmailVerificationDialog(BuildContext context, AppStateProvider provider) {
  final emailController = TextEditingController(text: provider.profile.email ?? '');
  final codeController = TextEditingController();
  int step = 1;
  String generatedCode = '';

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  step == 1 ? Icons.email_outlined : Icons.verified_user_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  step == 1 ? 'Associer mon Email' : 'Code de Confirmation',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step == 1) ...[
                  const Text(
                    'Entrez votre adresse email pour sauvegarder vos progrès, XP et certificats officiels de langue.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Adresse email',
                      hintText: 'exemple@gmail.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mark_email_read, color: Color(0xFF1E40AF), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Email : ${emailController.text.trim()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E40AF)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Code : $generatedCode',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.auto_fix_high, size: 14),
                              label: const Text('Remplir', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              onPressed: () {
                                codeController.text = generatedCode;
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      labelText: 'Code de vérification',
                      hintText: '••••',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (step == 1) {
                    final email = emailController.text.trim();
                    if (!email.contains('@') || !email.contains('.')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('Veuillez entrer une adresse email valide.'),
                        ),
                      );
                      return;
                    }
                    final randomNum = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
                    generatedCode = randomNum.toString();

                    setState(() {
                      step = 2;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1E3A8A),
                        duration: const Duration(seconds: 8),
                        content: Row(
                          children: [
                            const Icon(Icons.security, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Sawki Security : Votre code est $generatedCode'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    final entered = codeController.text.trim();
                    if (entered == generatedCode) {
                      provider.saveUserEmail(emailController.text.trim(), isVerified: true);
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF16A34A),
                          content: Text('🎉 Email vérifié avec succès ! Vos données sont sauvegardées.'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('Code incorrect. Veuillez réessayer.'),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(step == 1 ? 'Recevoir le code' : 'Confirmer'),
              ),
            ],
          );
        },
      );
    },
  );
}
