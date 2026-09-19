import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/sound_service.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Flashcards interactives
  final List<Map<String, String>> _flashcards = [
    {
      'en': 'Call it a day',
      'ipa': '/ˈkɔːl ɪt ə deɪ/',
      'fr': 'S\'arrêter là pour aujourd\'hui / Plier bagage',
      'example': 'We have worked enough for tonight. Let\'s call it a day!',
      'exampleFr': 'Nous avons assez travaillé ce soir. On s\'arrête là !',
    },
    {
      'en': 'Break a leg',
      'ipa': '/breɪk ə leɡ/',
      'fr': 'Bonne chance ! (Utilisé avant un spectacle ou un défi)',
      'example': 'You are going to do great in the interview. Break a leg!',
      'exampleFr': 'Tu vas assurer à l\'entretien. Bonne chance !',
    },
    {
      'en': 'Piece of cake',
      'ipa': '/piːs əv keɪk/',
      'fr': 'C\'est du gâteau / C\'est un jeu d\'enfant',
      'example': 'Don\'t worry about the English test, it will be a piece of cake.',
      'exampleFr': 'Ne t\'inquiète pas pour le test d\'anglais, c\'est du gâteau.',
    },
    {
      'en': 'Hit the books',
      'ipa': '/hɪt ðə bʊks/',
      'fr': 'Se mettre à bûcher / Réviser intensément',
      'example': 'I have an exam with Sarah tomorrow, so I need to hit the books.',
      'exampleFr': 'J\'ai un examen avec Sarah demain, je dois réviser.',
    },
    {
      'en': 'Under the weather',
      'ipa': '/ˈʌn.dɚ ðə ˈweð.ɚ/',
      'fr': 'Être patraque / Ne pas être dans son assiette',
      'example': 'I am feeling a little under the weather today.',
      'exampleFr': 'Je ne suis pas très en forme aujourd\'hui.',
    },
    {
      'en': 'Hang out',
      'ipa': '/hæŋ aʊt/',
      'fr': 'Passer du temps ensemble / Traîner avec des amis',
      'example': 'Do you want to hang out this Saturday in Chicago?',
      'exampleFr': 'Tu veux passer du temps ensemble ce samedi à Chicago ?',
    },
    {
      'en': 'Bite the bullet',
      'ipa': '/baɪt ðə ˈbʊl.ɪt/',
      'fr': 'Prendre son courage à deux mains / Serrer les dents',
      'example': 'I didn\'t want to speak in public, but I had to bite the bullet.',
      'exampleFr': 'Je ne voulais pas parler en public, mais j\'ai dû prendre mon courage à deux mains.',
    },
  ];

  int _currentCardIndex = 0;
  bool _showBack = false;

  // Règles clés
  final List<Map<String, String>> _grammarRules = [
    {
      'title': 'I agree (et JAMAIS "I am agree")',
      'desc': 'En anglais, "agree" est un verbe et non un adjectif. On conjugue : I agree, He agrees, We agree.',
      'correct': 'I agree with you.',
      'wrong': 'I am agree with you.',
    },
    {
      'title': 'He doesn\'t (et JAMAIS "He don\'t")',
      'desc': 'À la 3ème personne du singulier (he, she, it), la négation du présent est "doesn\'t".',
      'correct': 'He doesn\'t know the answer.',
      'wrong': 'He don\'t know the answer.',
    },
    {
      'title': 'People are (et JAMAIS "People is")',
      'desc': '"People" est le pluriel irrégulier de "person". Il s\'accorde toujours au pluriel.',
      'correct': 'People are friendly here.',
      'wrong': 'People is friendly here.',
    },
    {
      'title': 'Le "Flap T" Américain',
      'desc': 'Quand un "T" se trouve entre deux voyelles, il se prononce comme un "D" très court et fluide.',
      'correct': 'Water -> se prononce "wader"',
      'wrong': 'Prononcer un T dur britannique',
    },
    {
      'title': 'For vs Since (Durée vs Point de départ)',
      'desc': '"For" s\'utilise pour une durée complète ("for 2 years"). "Since" s\'utilise pour un point précis de départ ("since 2020").',
      'correct': 'I have lived here for 5 years.',
      'wrong': 'I have lived here since 5 years.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Centre de Révision 🔄',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.style), text: 'Flashcards Vocab'),
            Tab(icon: Icon(Icons.menu_book), text: 'Règles Clés US'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlashcardsTab(),
          _buildRulesTab(),
        ],
      ),
    );
  }

  Widget _buildFlashcardsTab() {
    final card = _flashcards[_currentCardIndex];
    final provider = Provider.of<AppStateProvider>(context, listen: false);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Carte ${_currentCardIndex + 1} sur ${_flashcards.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text('+2 XP si maîtrisé', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Carte Recto / Verso
        GestureDetector(
          onTap: () {
            setState(() {
              _showBack = !_showBack;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(minHeight: 260),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: _showBack
                  ? const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Colors.white, Color(0xFFF8FAFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _showBack ? Colors.transparent : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _showBack ? Colors.white24 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _showBack ? 'VERSO (Français)' : 'RECTO (Anglais)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _showBack ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_showBack) ...[
                  // Recto : Expression anglaise
                  Text(
                    card['en']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card['ipa']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.volume_up, size: 20),
                    label: const Text('Écouter Sarah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      TtsService().speak(card['en']!);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Touchez la carte pour voir la traduction 👆',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ] else ...[
                  // Verso : Traduction française
                  Text(
                    card['fr']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exemple : "${card['example']}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card['exampleFr']!,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white, size: 28),
                    onPressed: () {
                      TtsService().speak(card['example']!);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Boutons de contrôle
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.replay, color: Colors.orange),
                label: const Text('À revoir', style: TextStyle(color: Colors.orange)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  setState(() {
                    _showBack = false;
                    _currentCardIndex = (_currentCardIndex + 1) % _flashcards.length;
                  });
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Maîtrisé (+2 XP)', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  SoundService().playCorrect();
                  provider.addXp(2);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 +2 XP ajoutés pour votre maîtrise !'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                  setState(() {
                    _showBack = false;
                    _currentCardIndex = (_currentCardIndex + 1) % _flashcards.length;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRulesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _grammarRules.length,
      itemBuilder: (context, index) {
        final rule = _grammarRules[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rule['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                rule['desc']!,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rule['correct']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rule['wrong']!,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
