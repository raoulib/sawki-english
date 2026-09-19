import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/models/correction_feedback.dart';
import '../premium/premium_screen.dart';

class TutorChatScreen extends StatefulWidget {
  const TutorChatScreen({super.key});

  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(AppStateProvider provider) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    provider.sendMessage(text, isSpoken: false);
    _scrollToBottom();
  }

  void _showFrenchExplanationModal(CorrectionFeedback feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.frenchExplanationLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school, color: AppColors.frenchExplanation),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Explication de la Règle (FR)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.frenchExplanation,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'Ce que vous avez dit : ',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(
                              text: feedback.originalSegment,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: 'Façon américaine correcte : ',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(
                              text: feedback.correctedSegment,
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  feedback.explanationFr,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                if (feedback.tip.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('💡 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            feedback.tip,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (feedback.americanVariant != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    "🇺🇸 Note US : ${feedback.americanVariant}",
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      TtsService().speakFrench(feedback.explanationFr);
                    },
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Écouter l\'explication en français'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.frenchExplanation,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpeedSelector(AppStateProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentRate = provider.profile.speechRate;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vitesse d\'élocution du Tuteur US',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ajustez selon votre niveau de compréhension orale.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.blue),
                title: const Text('Lent (0.6x) - Idéal Débutants'),
                trailing: currentRate <= 0.7 ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  provider.updateProfile(speechRate: 0.6);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.green),
                title: const Text('Normal (1.0x) - Conversation Standard'),
                trailing: (currentRate > 0.7 && currentRate < 1.2) ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  provider.updateProfile(speechRate: 1.0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bolt, color: Colors.amber),
                title: const Text('Rapide (1.2x) - Vitesse Réelle Natifs US'),
                trailing: currentRate >= 1.2 ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  provider.updateProfile(speechRate: 1.2);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final messages = provider.messages;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        elevation: 0.5,
        foregroundColor: AppColors.text(context),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                  child: const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.card(context), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sarah (Coach Américaine)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    provider.isAiResponding ? 'En train d\'écrire...' : 'Anglais Américain • En ligne',
                    style: TextStyle(
                      fontSize: 11,
                      color: provider.isAiResponding ? AppColors.primary : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Réglage de la vitesse
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Vitesse d\'élocution',
            onPressed: () => _showSpeedSelector(provider),
          ),
          // Crédits d'énergie
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.secondary, size: 18),
                const SizedBox(width: 4),
                Text(
                  provider.profile.isPremium ? '∞' : '${provider.profile.energyCredits}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bandeau vidéo récompensée si énergie basse ou épuisée
          if (!provider.profile.isPremium && provider.profile.energyCredits <= 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: provider.profile.energyCredits <= 0
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  Icon(
                    provider.profile.energyCredits <= 0
                        ? Icons.lock_clock
                        : Icons.movie_creation_outlined,
                    color: provider.profile.energyCredits <= 0 ? Colors.red : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.profile.energyCredits <= 0
                          ? 'Limite gratuite atteinte (0 crédit) : regardez une pub pour +1 message !'
                          : 'Énergie restante : ${provider.profile.energyCredits} message(s). Regardez une vidéo pour +1 !',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: provider.profile.energyCredits <= 0 ? Colors.red.shade900 : Colors.brown.shade900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => provider.watchAdForEnergy(context),
                    style: TextButton.styleFrom(
                      backgroundColor: provider.profile.energyCredits <= 0 ? Colors.red : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text('Débloquer', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Liste des messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageBubble(msg, provider);
              },
            ),
          ),

          // Suggestions de jeux de rôle immersifs US
          _buildRoleplaySuggestions(provider),

          // Visualiseur d'écoute vocale en direct
          if (provider.isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: provider.sttLocale == 'fr_FR' ? const Color(0xFFFEF3C7) : Colors.blue.shade50,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.sttLocale == 'fr_FR'
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.sttLocale == 'fr_FR' ? '🇫🇷 Français' : '🇺🇸 US English',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: provider.sttLocale == 'fr_FR'
                            ? const Color(0xFF92400E)
                            : const Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.graphic_eq,
                    color: provider.sttLocale == 'fr_FR' ? const Color(0xFFB45309) : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      provider.liveTranscription.isEmpty
                          ? (provider.sttLocale == 'fr_FR'
                              ? 'Parlez en français (posez votre question à Sarah)...'
                              : 'Parlez en anglais américain...')
                          : provider.liveTranscription,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: provider.sttLocale == 'fr_FR' ? const Color(0xFF92400E) : AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop_circle, color: Colors.red),
                    onPressed: () => provider.stopVoiceRecordingAndSend(),
                  ),
                ],
              ),
            ),

          // Zone de saisie hybride (Clavier & Micro)
          _buildInputBar(provider),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, AppStateProvider provider) {
    final isUser = msg.isUser;
    final feedback = msg.feedback;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.card(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppColors.cardBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.text(context),
                      fontSize: 15,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => TtsService().speak(msg.text),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.volume_up, size: 18, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Badge & Encadré de retour pédagogique si une faute a été analysée
            if (feedback != null && feedback.hasError) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_fix_high, color: AppColors.error, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Correction : "${feedback.correctedSegment}"',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _showFrenchExplanationModal(feedback),
                      child: const Row(
                        children: [
                          Icon(Icons.help_outline, color: AppColors.frenchExplanation, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Pourquoi ? Voir la règle en français',
                            style: TextStyle(
                              color: AppColors.frenchExplanation,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildRoleplaySuggestions(AppStateProvider provider) {
    final scenarios = [
      {
        'title': '🛂 Douane JFK New York',
        'prompt': 'Hi! Let\'s roleplay. You are an immigration officer at JFK Airport in New York, and I just landed. Start the conversation by asking for my passport and why I am visiting the USA!',
      },
      {
        'title': '☕ Commander au Starbucks',
        'prompt': 'Hi! Let\'s roleplay. You are a friendly barista at a busy Starbucks in Manhattan. Ask me what I would like to order and what size I prefer!',
      },
      {
        'title': '💼 Entretien d\'Embauche US',
        'prompt': 'Hi! Let\'s roleplay. You are a senior tech recruiter conducting a behavioral job interview using the STAR method. Ask me your first question!',
      },
      {
        'title': '🏨 Check-in Hôtel à Miami',
        'prompt': 'Hi! Let\'s roleplay. You are the front desk receptionist at a hotel in Miami. I am arriving with my luggage to check in. Start the conversation!',
      },
      {
        'title': '🚗 Uber & Chauffeur US',
        'prompt': 'Hi! Let\'s roleplay. You are an Uber driver picking me up in San Francisco. Ask me where we are heading and make some friendly small talk!',
      },
      {
        'title': '🤝 Négocier un Contrat',
        'prompt': 'Hi! Let\'s roleplay. You are an American business partner negotiating a contract with me. Express your budget constraints politely and ask for my proposal!',
      },
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: scenarios.length,
        itemBuilder: (context, index) {
          final s = scenarios[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: AppColors.isDark(context) ? const Color(0xFF1E293B) : Colors.blue.shade50,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
              label: Text(
                s['title']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.isDark(context) ? const Color(0xFF93C5FD) : AppColors.primary,
                ),
              ),
              onPressed: () {
                if (!provider.profile.isPremium && provider.profile.energyCredits <= 0) {
                  provider.watchAdForEnergy(context);
                  return;
                }
                provider.sendMessage(s['prompt']!, isSpoken: false);
                _scrollToBottom();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(AppStateProvider provider) {
    // Si l'utilisateur gratuit a épuisé ses crédits, afficher la barre de déblocage par vidéo
    if (!provider.profile.isPremium && provider.profile.energyCredits <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Limite gratuite quotidienne atteinte (0 crédit)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => provider.watchAdForEnergy(context),
                      icon: const Icon(Icons.play_circle_fill, size: 18),
                      label: const Text('Regarder une pub (+1 message)', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PremiumScreen()),
                      );
                    },
                    icon: const Icon(Icons.star, color: Colors.amber, size: 18),
                    label: const Text('Illimité', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final isFrench = provider.sttLocale == 'fr_FR';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Sélecteur de langue micro (🇺🇸 EN / 🇫🇷 FR)
            Tooltip(
              message: isFrench
                  ? 'Micro configuré en Français (Cliquez pour Anglais)'
                  : 'Micro configuré en Anglais US (Cliquez pour Français)',
              child: GestureDetector(
                onTap: () => provider.toggleSttLocale(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFrench
                        ? (AppColors.isDark(context) ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                        : (AppColors.isDark(context) ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFrench ? const Color(0xFFF59E0B) : AppColors.cardBorder(context),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isFrench ? '🇫🇷' : '🇺🇸', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        isFrench ? 'FR' : 'EN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isFrench ? const Color(0xFFF59E0B) : AppColors.text(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Bouton Micro
            GestureDetector(
              onTap: () {
                if (provider.isListening) {
                  provider.stopVoiceRecordingAndSend();
                } else {
                  provider.startVoiceRecording();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: provider.isListening ? Colors.red : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  provider.isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Champ de texte
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                style: TextStyle(color: AppColors.text(context)),
                onSubmitted: (_) => _handleSend(provider),
                decoration: InputDecoration(
                  hintText: isFrench
                      ? 'Posez votre question en français...'
                      : 'Écrivez ou appuyez sur le micro...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.isDark(context) ? const Color(0xFF334155) : AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Bouton Envoyer
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: () => _handleSend(provider),
            ),
          ],
        ),
      ),
    );
  }
}
