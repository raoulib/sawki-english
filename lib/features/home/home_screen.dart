import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/data/daily_idioms_data.dart';
import '../../core/services/tts_service.dart';
import '../tutor_chat/tutor_chat_screen.dart';
import '../curriculum/curriculum_screen.dart';
import '../mistakes_tracker/mistakes_screen.dart';
import '../accent_workshop/accent_workshop_screen.dart';
import '../settings/settings_screen.dart';
import '../premium/premium_screen.dart';
import '../revision/revision_screen.dart';
import '../../core/utils/email_verification_dialog.dart';
import '../history/history_screen.dart';
import '../../core/config/app_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;

  final List<Widget> _screens = [
    const HomeDashboardTab(),
    const TutorChatScreen(),
    const CurriculumScreen(),
    const MistakesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTabIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        elevation: 2,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.record_voice_over_outlined),
            selectedIcon: Icon(Icons.record_voice_over, color: AppColors.primary),
            label: 'Tuteur IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.primary),
            label: 'Parcours',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology, color: AppColors.primary),
            label: 'Lacunes',
          ),
        ],
      ),
    );
  }
}

class HomeDashboardTab extends StatefulWidget {
  const HomeDashboardTab({super.key});

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  bool _isEmailBannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final profile = provider.profile;
    final todayIdiom = DailyIdiomsData.getIdiomForToday();
    final mistakesCount = provider.mistakes.where((m) => !m.mastered).length;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        elevation: 0.5,
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Sawki English',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Streak
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.duoOrange, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.duoOrangeDark,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                Text(
                  '${profile.streakDays} j',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.duoOrangeDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // XP
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.duoGold, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.duoGoldDark,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                Text(
                  '${profile.xp}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.duoGoldDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Énergie / Sessions (cliquable pour recharger ou voir les détails)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showEnergyRechargeModal(context, provider),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: profile.isPremium
                      ? const Color(0xFF8B5CF6)
                      : (profile.energyCredits > 0 ? AppColors.duoBlue : AppColors.duoRed),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: profile.isPremium
                        ? const Color(0xFF6D28D9)
                        : (profile.energyCredits > 0 ? AppColors.duoBlueDark : AppColors.duoRedDark),
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    profile.isPremium ? '∞' : '${profile.energyCredits}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: profile.isPremium
                          ? const Color(0xFF6D28D9)
                          : (profile.energyCredits > 0 ? AppColors.duoBlueDark : AppColors.duoRedDark),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bouton Bascule Thème Rapide (☀️ / 🌙)
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber
                  : AppColors.text(context),
              size: 20,
            ),
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Activer le mode clair'
                : 'Activer le mode sombre',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              provider.toggleTheme(context);
            },
          ),
          // Bouton Actualiser
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
            tooltip: 'Actualiser la page',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () async {
              await provider.refreshProfile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Données et énergie actualisées ! 🔄'),
                    duration: Duration(milliseconds: 1200),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
          ),
          // Bouton Paramètres
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.text(context), size: 20),
            padding: const EdgeInsets.only(right: 4, left: 1),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.refreshProfile();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil et progression actualisés ! 🔄'),
                duration: Duration(milliseconds: 1000),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Hero Card Moderne & Unifié : Accueil + Sarah + Statut Énergie
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TutorChatScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.tutorGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Hello, ${profile.name.isNotEmpty ? profile.name : "Champion"} ! 👋',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Niveau ${profile.currentLevel}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pratiquez l\'anglais américain avec votre coach Sarah.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic, color: AppColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Parler avec Sarah',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _showEnergyRechargeModal(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⚡', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  profile.isPremium
                                      ? 'Illimité'
                                      : '${profile.energyCredits} session${profile.energyCredits > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Rappel Quotidien de Pratique (Série / Streak si non pratiqué)
            _buildDailyReminderBanner(context, profile),

            // 3. Invitation Enregistrement & Vérification Email (Format fin et fermable)
            if (!profile.isEmailVerified && !_isEmailBannerDismissed) ...[
              const SizedBox(height: 10),
              _buildEmailPromptBanner(context, provider),
            ],

            // 4. Sawki Premium (Format VIP fin & discret)
            if (!profile.isPremium) ...[
              const SizedBox(height: 10),
              _buildPremiumStrip(context),
            ],

            const SizedBox(height: 18),

          // Carte Expression Américaine du Jour (Expert Addition)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🇺🇸', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Expression Américaine du Jour',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.isDark(context) ? const Color(0xFF93C5FD) : Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: AppColors.primary),
                      onPressed: () {
                        TtsService().speak(todayIdiom.idiom);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '"${todayIdiom.idiom}"',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      todayIdiom.phonetic,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '💡 Sens : ${todayIdiom.meaningFr}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ex: "${todayIdiom.exampleUs}"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        todayIdiom.exampleTranslationFr,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grille des Ateliers & Modules Rapides
          const Text(
            'Modules d\'Entraînement',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Atelier Accent US
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  title: 'Atelier Accent & Flap T',
                  subtitle: 'Prononciation US',
                  icon: Icons.record_voice_over,
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccentWorkshopScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Suivi des Lacunes
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  title: 'Mes Lacunes',
                  subtitle: '$mistakesCount erreur(s) à fixer',
                  icon: Icons.psychology,
                  color: Colors.redAccent,
                  badgeText: mistakesCount > 0 ? '$mistakesCount' : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MistakesScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Parcours A1-C1
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  title: 'Leçons & Examens',
                  subtitle: 'Seuil 80% pour monter',
                  icon: Icons.military_tech,
                  color: Colors.amber.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CurriculumScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Paramètres / Clé API
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  title: 'Vitesse & Réglages',
                  subtitle: 'Contrôle audio & Clé IA',
                  icon: Icons.tune,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Centre de Révision
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  title: 'Centre de Révision',
                  subtitle: 'Flashcards & Règles US',
                  icon: Icons.style,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RevisionScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Historique & Progression
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  title: 'Historique & Journal',
                  subtitle: 'Examens & Diplômes',
                  icon: Icons.history_edu,
                  color: Colors.brown.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Footer Copyright Sawki Group
          Center(
            child: Column(
              children: [
                Text(
                  '${AppConfig.appName} v${AppConfig.appVersion}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppConfig.copyright,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPremiumStrip(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sawki Premium : IA illimitée & Zéro publicité',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF92400E)),
          ],
        ),
      ),
    );
  }

  void _showEnergyRechargeModal(BuildContext context, AppStateProvider provider) {
    final profile = provider.profile;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Text('⚡', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Énergie & Sessions Conversation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                profile.isPremium
                    ? 'Vous bénéficiez de sessions illimitées avec Sarah grâce à Sawki Premium !'
                    : 'Solde actuel : ${profile.energyCredits} session${profile.energyCredits > 1 ? 's' : ''} disponible${profile.energyCredits > 1 ? 's' : ''}.\nChaque session vocale/écrite avec Sarah consomme 1 éclair. Vous recevez 3 sessions gratuites chaque jour !',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 22),
              if (!profile.isPremium) ...[
                // Option 1 : Regarder une vidéo pub
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(modalCtx);
                      provider.watchAdForEnergy(context);
                    },
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                    label: const Text(
                      'Regarder une vidéo (+1⚡ & +20 XP)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Option 2 : Passer à Premium
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(modalCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PremiumScreen()),
                      );
                    },
                    icon: const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37)),
                    label: const Text(
                      'Passer à Sawki Premium (Illimité)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Compte Premium Actif • Accès Illimité',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder(context), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardBorder(context),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: AppColors.subtext(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReminderBanner(BuildContext context, UserProfile profile) {
    final now = DateTime.now();
    final lastActive = profile.lastActiveDate;
    final bool hasNotPracticedToday = lastActive == null ||
        lastActive.year != now.year ||
        lastActive.month != now.month ||
        lastActive.day != now.day;

    if (!hasNotPracticedToday) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Série de ${profile.streakDays} j en jeu ! Entraînez-vous aujourd\'hui.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorChatScreen()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Pratiquer',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPromptBanner(BuildContext context, AppStateProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_outlined, color: Color(0xFF2563EB), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Sauvegardez vos diplômes avec un email vérifié',
              style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => _showEmailVerificationDialog(context, provider),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Vérifier',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              setState(() {
                _isEmailBannerDismissed = true;
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 15, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailVerificationDialog(BuildContext context, AppStateProvider provider) {
    showEmailVerificationDialog(context, provider);
  }
}
