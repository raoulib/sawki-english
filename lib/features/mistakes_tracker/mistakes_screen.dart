import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/models/mistake_item.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/stt_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/utils/shared_utils.dart';

class MistakesScreen extends StatefulWidget {
  const MistakesScreen({super.key});

  @override
  State<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends State<MistakesScreen> {
  String? _speakingMistakeId;
  String? _oralActiveItemId;
  String? _oralSpokenText;
  bool? _oralIsSuccess;
  bool _isListening = false;

  bool _evaluatePronunciation(String spoken, String expected) {
    return evaluatePronunciation(spoken, expected);
  }

  Future<void> _startOralPractice(MistakeItem item) async {
    // Si déjà en cours pour cet item, on arrête
    if (_isListening && _oralActiveItemId == item.id) {
      await _stopOralPractice(item);
      return;
    }

    await SttService().stopListening();
    setState(() {
      _oralActiveItemId = item.id;
      _oralSpokenText = '';
      _oralIsSuccess = null;
      _isListening = true;
    });

    await SttService().startListening(
      localeId: 'en_US',
      onResult: (words, isFinal) async {
        if (!mounted) return;
        setState(() {
          _oralSpokenText = words;
        });

        if (isFinal) {
          await SttService().stopListening();
          final isSuccess = _evaluatePronunciation(words, item.correctedText);
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _oralIsSuccess = isSuccess;
          });

          if (isSuccess) {
            await SoundService().playCorrect();
          } else {
            await SoundService().playIncorrect();
          }
        }
      },
    );
  }

  Future<void> _stopOralPractice(MistakeItem item) async {
    await SttService().stopListening();
    final words = _oralSpokenText ?? '';
    final isSuccess = _evaluatePronunciation(words, item.correctedText);
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _oralIsSuccess = isSuccess;
    });

    if (isSuccess) {
      await SoundService().playCorrect();
    } else {
      await SoundService().playIncorrect();
    }
  }

  Future<void> _playVoice(MistakeItem item) async {
    setState(() => _speakingMistakeId = item.id);
    try {
      await TtsService().speak(item.correctedText);
    } finally {
      if (mounted) setState(() => _speakingMistakeId = null);
    }
  }

  @override
  void dispose() {
    SttService().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mistakes = StorageService.getMistakes();
    final activeMistakes = mistakes.where((m) => !m.mastered).toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text(
          'Suivi Intelligent des Lacunes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.card(context),
        foregroundColor: AppColors.text(context),
        elevation: 0.5,
      ),
      body: activeMistakes.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // En-tête résumé & Mode entraînement ciblé
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${activeMistakes.length} point(s) à consolider',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'L\'application analyse vos erreurs récurrentes pour vous faire progresser deux fois plus vite.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _launchDrill(context, activeMistakes),
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('Éliminer mes lacunes (Entraînement ciblé)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Historique de vos erreurs récurrentes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                ),
                const SizedBox(height: 12),
                ...activeMistakes.map((item) => _buildMistakeCard(item)),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune lacune enregistrée !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pratiquez avec le tuteur vocal Sawki ou faites des leçons. Vos erreurs seront automatiquement répertoriées ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeCard(MistakeItem item) {
    final isThisActive = _oralActiveItemId == item.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.frenchExplanationLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.errorType,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.frenchExplanation,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Vu ${item.occurrenceCount}x',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.close, color: AppColors.error, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.originalText,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.error,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check, color: AppColors.success, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.correctedText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
              IconButton(
                icon: _speakingMistakeId == item.id
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.volume_up, color: AppColors.primary, size: 22),
                tooltip: 'Écouter la voix de Sarah',
                onPressed: () => _playVoice(item),
              ),
            ],
          ),
          if (item.explanationFr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.explanationFr,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],

          // Module interactif de répétition orale
          if (isThisActive) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.blue.shade50
                    : (_oralIsSuccess == true ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isListening
                      ? Colors.blue.shade300
                      : (_oralIsSuccess == true ? Colors.green.shade400 : Colors.red.shade300),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isListening
                            ? Icons.mic
                            : (_oralIsSuccess == true ? Icons.check_circle : Icons.error_outline),
                        color: _isListening
                            ? Colors.blue.shade800
                            : (_oralIsSuccess == true ? Colors.green.shade800 : Colors.red.shade800),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isListening
                              ? 'Écoute en cours... Répétez la phrase :'
                              : (_oralIsSuccess == true
                                  ? '🎉 Bravo ! Excellente prononciation !'
                                  : '❌ Erreur de prononciation. Réessayez !'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isListening
                                ? Colors.blue.shade900
                                : (_oralIsSuccess == true ? Colors.green.shade900 : Colors.red.shade900),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isListening
                        ? (_oralSpokenText?.isEmpty ?? true
                            ? 'Parlez distinctement en anglais dans le micro...'
                            : 'Entendu : "$_oralSpokenText"')
                        : (_oralIsSuccess == true
                            ? 'Vous avez bien prononcé : "$_oralSpokenText"'
                            : 'Vous avez dit : "${_oralSpokenText?.isEmpty ?? true ? "(Rien entendu)" : _oralSpokenText}"\nAttendu : "${item.correctedText}"'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isListening
                          ? Colors.blue.shade800
                          : (_oralIsSuccess == true ? Colors.green.shade800 : Colors.red.shade800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isListening)
                        ElevatedButton.icon(
                          onPressed: () => _stopOralPractice(item),
                          icon: const Icon(Icons.stop, size: 14),
                          label: const Text('Arrêter et valider', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        )
                      else ...[
                        OutlinedButton.icon(
                          onPressed: () => _playVoice(item),
                          icon: const Icon(Icons.volume_up, size: 14),
                          label: const Text('Réécouter Sarah', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _startOralPractice(item),
                          icon: const Icon(Icons.refresh, size: 14),
                          label: Text(
                            _oralIsSuccess == true ? 'Répéter encore' : 'Réessayer au micro',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _oralIsSuccess == true ? Colors.green.shade700 : Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _startOralPractice(item),
                icon: Icon(
                  _isListening && isThisActive ? Icons.stop : Icons.mic,
                  size: 16,
                  color: _isListening && isThisActive ? Colors.red : Colors.white,
                ),
                label: Text(
                  _isListening && isThisActive ? 'Arrêter' : 'Répéter à l\'oral 🎙️',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListening && isThisActive ? Colors.red.shade100 : AppColors.primary,
                  foregroundColor: _isListening && isThisActive ? Colors.red.shade900 : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await StorageService.markMistakeMastered(item.id);
                  if (!mounted) return;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('🎉 Lacune marquée comme maîtrisée !'),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                },
                icon: const Icon(Icons.done_all, size: 16, color: AppColors.success),
                label: const Text(
                  'Maîtrisé',
                  style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _launchDrill(BuildContext context, List<MistakeItem> mistakes) {
    if (mistakes.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DrillSessionSheet(
          mistakes: mistakes,
          onMastered: () => setState(() {}),
        );
      },
    );
  }
}

/// Feuille modale dédiée pour la session d'entraînement ciblé.
/// StatefulWidget indépendant pour préserver le contrôleur de saisie
/// sans être réinitialisé ni fermé lors de l'ouverture du clavier virtuel.
class _DrillSessionSheet extends StatefulWidget {
  final List<MistakeItem> mistakes;
  final VoidCallback onMastered;

  const _DrillSessionSheet({
    required this.mistakes,
    required this.onMastered,
  });

  @override
  State<_DrillSessionSheet> createState() => _DrillSessionSheetState();
}

class _DrillSessionSheetState extends State<_DrillSessionSheet> {
  late final TextEditingController _controller;
  int _currentIndex = 0;
  bool _isListening = false;
  String? _oralResultText;
  bool? _isOralSuccess;
  bool _isPlayingAudio = false;

  MistakeItem get currentMistake => widget.mistakes[_currentIndex];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    SttService().stopListening();
    super.dispose();
  }

  bool _evaluatePronunciation(String spoken, String expected) {
    return evaluatePronunciation(spoken, expected);
  }

  Future<void> _listenOral() async {
    if (_isListening) {
      await SttService().stopListening();
      setState(() => _isListening = false);
      return;
    }

    await SttService().stopListening();
    setState(() {
      _isListening = true;
      _oralResultText = '';
      _isOralSuccess = null;
    });

    await SttService().startListening(
      localeId: 'en_US',
      onResult: (words, isFinal) async {
        if (!mounted) return;
        setState(() {
          _oralResultText = words;
        });

        if (isFinal) {
          await SttService().stopListening();
          final success = _evaluatePronunciation(words, currentMistake.correctedText);
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _isOralSuccess = success;
            if (success) {
              _controller.text = currentMistake.correctedText;
            }
          });

          if (success) {
            await SoundService().playCorrect();
            await StorageService.markMistakeMastered(currentMistake.id);
            widget.onMastered();
          } else {
            await SoundService().playIncorrect();
          }
        }
      },
    );
  }

  Future<void> _validateWritten() async {
    final userText = _controller.text.trim();
    final isCorrect = _evaluatePronunciation(userText, currentMistake.correctedText);

    if (isCorrect) {
      await SoundService().playCorrect();
      await StorageService.markMistakeMastered(currentMistake.id);
      widget.onMastered();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('🎉 Bravo ! Écrit avec exactitude !'),
          duration: Duration(milliseconds: 1500),
        ),
      );

      if (_currentIndex < widget.mistakes.length - 1) {
        setState(() {
          _currentIndex++;
          _controller.clear();
          _oralResultText = null;
          _isOralSuccess = null;
        });
      } else {
        Navigator.pop(context);
      }
    } else {
      await SoundService().playIncorrect();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Réponse attendue : "${currentMistake.correctedText}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _playSarahVoice() async {
    setState(() => _isPlayingAudio = true);
    try {
      await TtsService().speak(currentMistake.correctedText);
    } finally {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sample = currentMistake;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: keyboardHeight + 20,
        left: 20,
        right: 20,
        top: 14,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de préhension
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Session Élimination de Lacune',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_currentIndex + 1}/${widget.mistakes.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pratiquez par écrit ou au microphone pour éliminer cette lacune :',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Carte d'erreur
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Formulation erronée :',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '"${sample.originalText}"',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Écouter la bonne version
            InkWell(
              onTap: _isPlayingAudio ? null : _playSarahVoice,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _isPlayingAudio
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.volume_up, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Écouter la prononciation avec Sarah 🇺🇸',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Champ de saisie texte
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _validateWritten(),
              decoration: InputDecoration(
                hintText: 'Écrivez la bonne formulation...',
                prefixIcon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: _isListening ? Colors.red : AppColors.primary,
                  ),
                  tooltip: 'Prononcer au micro',
                  onPressed: _listenOral,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            // Retour oral s'il existe
            if (_oralResultText != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isListening
                      ? Colors.blue.shade50
                      : (_isOralSuccess == true ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isListening
                          ? Icons.mic
                          : (_isOralSuccess == true ? Icons.check_circle : Icons.error),
                      size: 18,
                      color: _isListening
                          ? Colors.blue.shade800
                          : (_isOralSuccess == true ? Colors.green.shade800 : Colors.red.shade800),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isListening
                            ? 'Écoute en cours : "$_oralResultText"'
                            : (_isOralSuccess == true
                                ? '🎉 Bonne prononciation ! Lacune validée !'
                                : '❌ Prononcé : "$_oralResultText". Réessayez au micro !'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isListening
                              ? Colors.blue.shade900
                              : (_isOralSuccess == true ? Colors.green.shade900 : Colors.red.shade900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _listenOral,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic, size: 18),
                    label: Text(_isListening ? 'Arrêter' : 'Oral 🎙️'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red.shade600 : Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _validateWritten,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Valider ma réponse', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

