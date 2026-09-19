import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state_provider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlanIndex = 0; // 0 = Annuel (recommandé), 1 = Mensuel

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'sawki_premium_annual',
      'title': 'Abonnement Annuel',
      'price': '29,99 € / an',
      'subprice': 'Soit seulement 2,49 € / mois',
      'badge': '🔥 ÉCONOMISEZ 50%',
      'isBest': true,
      'billingPeriod': 'Facturé 29,99 € tous les 12 mois',
    },
    {
      'id': 'sawki_premium_monthly',
      'title': 'Abonnement Mensuel',
      'price': '4,99 € / mois',
      'subprice': 'Sans engagement, annulable à tout moment',
      'badge': null,
      'isBest': false,
      'billingPeriod': 'Facturé 4,99 € chaque mois',
    },
  ];

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.bolt,
      'title': 'Tuteur Vocal IA Illimité',
      'desc': 'Pratiquez l\'anglais américain au micro sans aucune limite d\'énergie quotidienne.',
    },
    {
      'icon': Icons.block,
      'title': 'Zéro Publicité',
      'desc': 'Suppression intégrale des bannières et des vidéos publicitaires.',
    },
    {
      'icon': Icons.lock_open,
      'title': 'Accès Intégral Débloqué',
      'desc': 'Tous les niveaux (A0, A1, A2, B1, B2, C1), dictées et ateliers disponibles sans attente.',
    },
    {
      'icon': Icons.workspace_premium,
      'title': 'Certification Officielle',
      'desc': 'Grand Examen Final illimité avec diplôme téléchargeable et partageable.',
    },
  ];

  /// Informe l'utilisateur que l'abonnement Premium sera bientôt disponible
  /// via Google Play Billing officiel.
  void _openPremiumSubscription(AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 28),
              SizedBox(width: 10),
              Text(
                'Bientôt Disponible',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'L\'abonnement Sawki English Premium sera disponible très prochainement via Google Play.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'En attendant, vous pouvez profiter de toutes les leçons de A0 à C1 avec 3 sessions IA gratuites par jour.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isAlreadyPremium = provider.profile.isPremium;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sawki Premium',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // En-tête prestigieux
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.workspace_premium, size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Passez à la Vitesse Supérieure',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Libérez 100% de votre potentiel avec un tuteur IA illimité et zéro publicité.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Liste des avantages
            ..._features.map(
              (f) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(f['icon'] as IconData, color: const Color(0xFFD4AF37), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f['desc'] as String,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (!isAlreadyPremium) ...[
              const Text(
                'Choisissez votre formule :',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 14),

              // Choix des formules (Responsive sans overflow)
              ...List.generate(_plans.length, (index) {
                final plan = _plans[index];
                final isSelected = _selectedPlanIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlanIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white54,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    plan['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (plan['badge'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        plan['badge'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                plan['subprice'],
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          plan['price'],
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Bouton d'action Premium
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _openPremiumSubscription(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Passer à Premium 👑',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('L\'abonnement Premium sera disponible prochainement.'),
                      ),
                    );
                  },
                  child: const Text(
                    'En savoir plus sur Sawki Premium',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 40),
                    SizedBox(height: 10),
                    Text(
                      'Votre compte est déjà Premium !',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vous profitez de toutes les fonctionnalités illimitées sans aucune publicité.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

