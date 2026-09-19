import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/correction_feedback.dart';
import '../config/app_config.dart';

class GeminiResponse {
  final String replyEn;
  final CorrectionFeedback feedback;

  GeminiResponse({
    required this.replyEn,
    required this.feedback,
  });
}

class GeminiService {
  static const String _defaultModel = AppConfig.geminiModel;

  /// Analyse le message de l'apprenant et génère une réponse interactive fluide
  static Future<GeminiResponse> sendMessage({
    required String userMessage,
    required String userLevel,
    required String apiKey,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final cleanInput = userMessage.trim();
    if (cleanInput.isEmpty) {
      return GeminiResponse(
        replyEn: "I'm listening! Feel free to say or type anything in English.",
        feedback: CorrectionFeedback.clean(),
      );
    }

    final effectiveApiKey = apiKey.trim().isNotEmpty
        ? apiKey.trim()
        : AppConfig.defaultGeminiApiKey.trim();

    // Système prompt d'instruction pédagogique
    final systemInstruction = '''
You are "Sarah", a warm, witty, enthusiastic American English coach from Chicago teaching French speakers.
The student's level is CEFR: $userLevel.

CORE TEACHING INSTRUCTIONS:
1. Speak in natural, modern American English (idiomatic, friendly, upbeat).
2. CRITICAL BILINGUAL RULE: When the student speaks in French, asks for a translation, asks for clarification, or says they did not understand (e.g. "peux-tu traduire ?", "je n'ai pas compris", "c'est trop lourd", "en français svp"), YOU MUST reply in FRENCH to translate, explain clearly, and encourage them! Then give the easy American English equivalent to practice and end with a friendly question.
3. SPELLING, GRAMMAR & PRONUNCIATION CORRECTIONS:
   - Carefully check the student's message for English spelling typos (e.g. "watter", "alot", "wich"), grammar issues ("I am agree", "he don't"), syntax errors, and phonetic misunderstandings.
   - Whenever an error is present, set "has_error": true, provide "original_segment", "corrected_segment", "error_type", and "explanation_fr".
4. Return your output STRICTLY as a single JSON object with these keys:
{
  "reply_en": "Your conversational reply. If the user asked in French or needed clarification, explain in FRENCH first then give the English phrase and a question. Otherwise, conversational American English (2-3 sentences max).",
  "has_error": true/false,
  "original_segment": "the exact error if any",
  "corrected_segment": "natural American equivalent",
  "error_type": "grammar" | "vocabulary" | "syntax" | "spelling" | "pronunciation" | "idiom",
  "explanation_fr": "Encouraging rule explanation or translation in FRENCH (2-3 sentences max).",
  "tip": "Short memorable tip for French speakers.",
  "american_variant": "American nuance note (e.g., Flap T, gonna, wanna, sidewalk)."
}
''';

    // Construire des échanges alternés valides pour l'API Gemini
    final contents = <Map<String, dynamic>>[];

    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      // Optimisation stricte des tokens Gemini AI :
      // Fenêtre glissante conservant uniquement les 4 derniers échanges (2 tours)
      final effectiveHistory = conversationHistory.length > 4
          ? conversationHistory.sublist(conversationHistory.length - 4)
          : conversationHistory;

      // Filtrer et alterner rigoureusement user / model
      String? lastRole;
      for (final msg in effectiveHistory) {
        final role = msg['role'] == 'user' ? 'user' : 'model';
        final text = (msg['text'] ?? '').trim();
        if (text.isEmpty) continue;

        // L'API Gemini exige que le premier tour soit 'user'
        if (contents.isEmpty && role != 'user') {
          continue;
        }

        if (role == lastRole) {
          // Fusionner si deux rôles consécutifs identiques
          final lastContent = contents.last;
          final parts = lastContent['parts'] as List;
          parts.add({'text': text});
        } else {
          contents.add({
            'role': role,
            'parts': [
              {'text': text}
            ],
          });
          lastRole = role;
        }
      }
    }

    // Ajouter le message actuel de l'utilisateur
    if (contents.isNotEmpty && contents.last['role'] == 'user') {
      final lastParts = contents.last['parts'] as List;
      lastParts.add({'text': cleanInput});
    } else {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': cleanInput}
        ],
      });
    }

    final requestBody = {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'generationConfig': {
        'temperature': 0.7,
        'responseMimeType': 'application/json',
        'maxOutputTokens': 350, // Économise le quota de tokens de sortie
      },
    };

    final modelsToTry = [
      _defaultModel,
      'gemini-3.6-flash',
      'gemini-flash-latest',
    ];

    for (final model in modelsToTry.toSet()) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$effectiveApiKey',
        );

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final rawText = parts[0]['text'] as String;
              final cleanJson = _cleanJsonString(rawText);
              final jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;

              return GeminiResponse(
                replyEn: jsonMap['reply_en'] ?? "Hey there! How's your English practice going today?",
                feedback: CorrectionFeedback.fromMap(jsonMap),
              );
            }
          }
        } else {
          debugPrint("Gemini API ($model) status: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        debugPrint("Gemini request exception for $model: $e");
      }
    }

    // Moteur dynamique hors-ligne si le réseau ou l'API n'a pas répondu
    return generateOfflineSmartResponse(cleanInput, userLevel);
  }

  static String _cleanJsonString(String raw) {
    var s = raw.trim();
    if (s.startsWith('```json')) {
      s = s.substring(7);
    } else if (s.startsWith('```')) {
      s = s.substring(3);
    }
    if (s.endsWith('```')) {
      s = s.substring(0, s.length - 3);
    }
    return s.trim();
  }

  /// Moteur conversationnel intelligent hors-ligne riche et diversifié
  static GeminiResponse generateOfflineSmartResponse(String input, String level) {
    final lower = input.toLowerCase().trim();

    // 1. Salutations et présentations directes
    if (lower == 'hi' ||
        lower == 'hello' ||
        lower.startsWith('hi sarah') ||
        lower.startsWith('hello sarah') ||
        lower.startsWith('hey sarah') ||
        lower == 'hey') {
      return GeminiResponse(
        replyEn: "Hey! Awesome to hear from you. I'm excited to practice English with you today! What's on your mind right now?",
        feedback: CorrectionFeedback.clean(),
      );
    }

    if (lower.contains('how are you') || lower.contains("how's it going")) {
      return GeminiResponse(
        replyEn: "I'm doing great, thank you! It's always a highlight of my day to help you improve your American English. How's your day treating you so far?",
        feedback: CorrectionFeedback.clean(),
      );
    }

    if (lower.contains('who are you') || lower.contains('your name')) {
      return GeminiResponse(
        replyEn: "I'm Sarah, your dedicated American English coach! I'm here to help you nail that natural US accent and speak with total confidence. What would you like to work on?",
        feedback: CorrectionFeedback.clean(),
      );
    }

    // 1b. Demande de traduction ou d'incompréhension en français
    if (lower.contains('traduire') ||
        lower.contains('pas compris') ||
        lower.contains('comprends pas') ||
        lower.contains('en français') ||
        lower.contains('trop rapide') ||
        lower.contains('un peu lourd') ||
        lower.contains('aide-moi') ||
        lower.contains('que veut dire')) {
      return GeminiResponse(
        replyEn: "Pas de souci du tout ! En français, je disais : 'Génial, je suis ravie ! Je passe une super journée ici à Chicago avec mon café chaud. Quel temps fait-il chez toi aujourd'hui ?'.\n\nTu peux me répondre en toute simplicité : 'It is sunny' (Il fait beau) ou 'It is nice' (C'est agréable) ! Is it sunny where you are?",
        feedback: CorrectionFeedback(
          hasError: false,
          originalSegment: "",
          correctedSegment: "",
          errorType: "vocabulary",
          explanationFr: "Quand tu n'as pas compris, tu peux me demander en anglais : 'Could you translate that, please?' ou 'Could you speak a little slower?' (Pourrais-tu parler un peu plus lentement ?).",
          tip: "Astuce : 'No problem at all!' = 'Aucun problème du tout !'",
          americanVariant: "Aux USA, on utilise beaucoup 'No worries!' ou 'You got it!'.",
        ),
      );
    }

    // 1c. Détection de fautes d'orthographe fréquentes
    if (lower.contains('watter')) {
      return GeminiResponse(
        replyEn: "Water is so essential! How many glasses of water do you drink every day?",
        feedback: CorrectionFeedback(
          hasError: true,
          originalSegment: "watter",
          correctedSegment: "water",
          errorType: "spelling",
          explanationFr: "En anglais, 'water' (l'eau) s'écrit avec un seul 't'. Avec l'accent américain (Flap T), on le prononce 'wader'.",
          tip: "Orthographe : W-A-T-E-R.",
          americanVariant: "Flap T : le T entre deux voyelles sonne comme un D rapide.",
        ),
      );
    }
    if (lower.contains('alot')) {
      return GeminiResponse(
        replyEn: "That's awesome! What else do you enjoy doing a lot?",
        feedback: CorrectionFeedback(
          hasError: true,
          originalSegment: "alot",
          correctedSegment: "a lot",
          errorType: "spelling",
          explanationFr: "'A lot' s'écrit toujours en deux mots séparés, jamais collé en 'alot'.",
          tip: "Pensez à 'a cat' ou 'a car' : 'a' + 'lot'.",
        ),
      );
    }

    // 2. Erreur : "I am agree" / "I'm agree"
    if (lower.contains('i am agree') || lower.contains("i'm agree")) {
      return GeminiResponse(
        replyEn: "I totally agree with you! What makes you think so?",
        feedback: CorrectionFeedback(
          hasError: true,
          originalSegment: "I am agree",
          correctedSegment: "I agree",
          errorType: "syntax",
          explanationFr: "En anglais, 'agree' est un verbe d'action directe, jamais un adjectif. On dit donc 'I agree' et JAMAIS 'I am agree'.",
          tip: "Astuce : Pensez 'I agree' = 'J'adhère / Je suis d'accord'.",
          americanVariant: "Aux USA, on utilise aussi souvent 'Totally!' ou 'I hear you!'.",
        ),
      );
    }

    // 3. Erreur : "He don't" ou "She don't"
    if (lower.contains("he don't") || lower.contains("she don't") || lower.contains("it don't")) {
      final isHe = lower.contains("he don't");
      return GeminiResponse(
        replyEn: "That's an interesting point! Could you give me a specific example of that?",
        feedback: CorrectionFeedback(
          hasError: true,
          originalSegment: isHe ? "he don't" : "she don't",
          correctedSegment: isHe ? "he doesn't" : "she doesn't",
          errorType: "grammar",
          explanationFr: "À la 3ème personne du singulier (He, She, It), l'auxiliaire de négation au présent est 'doesn't' et non 'don't'.",
          tip: "Règle d'or : He/She/It prend le -s : He doesn't like, She doesn't have.",
        ),
      );
    }

    // 4. Erreur : "People is"
    if (lower.contains("people is") || lower.contains("peoples")) {
      return GeminiResponse(
        replyEn: "People are definitely fascinating! What did you notice about them?",
        feedback: CorrectionFeedback(
          hasError: true,
          originalSegment: "people is",
          correctedSegment: "people are",
          errorType: "grammar",
          explanationFr: "'People' est un nom pluriel en anglais (le pluriel de 'person'). Il s'accorde donc toujours avec 'are' : 'People are'.",
          tip: "1 person is -> 2 people are.",
        ),
      );
    }

    // 5. Erreur : "I have went"
    if (lower.contains("have went") || lower.contains("has went")) {
      return GeminiResponse(
        replyEn: "Oh nice! Tell me more about that experience. How was it?",
        feedback: CorrectionFeedback(
          hasError: true,
          originalSegment: "have went",
          correctedSegment: "have gone / went",
          errorType: "grammar",
          explanationFr: "Le participe passé du verbe 'go' est 'gone'. Si l'action est terminée dans le passé, utilisez simplement le prétérit 'I went'.",
          tip: "Triptyque : Go -> Went -> Gone.",
        ),
      );
    }

    // 6. Erreur : "depend of"
    if (lower.contains("depend of") || lower.contains("depends of")) {
      return GeminiResponse(
        replyEn: "You're right, context really matters! What does it depend on the most?",
        feedback: CorrectionFeedback(
          hasError: true,
          originalSegment: "depend of",
          correctedSegment: "depend on",
          errorType: "preposition",
          explanationFr: "En anglais, le verbe 'depend' se construit TOUJOURS avec la préposition 'on' (ou 'upon'), jamais avec 'of'.",
          tip: "Pensez : 'It depends ON...' (dépendre de).",
          americanVariant: "Aux USA, l'expression 'It depends on you' est omniprésente.",
        ),
      );
    }

    // 7. Erreur : "since 2 years" (au lieu de "for 2 years")
    if (lower.contains("since two years") || lower.contains("since 2 years")) {
      return GeminiResponse(
        replyEn: "Wow, two whole years is a long time! How has that journey been?",
        feedback: CorrectionFeedback(
          hasError: true,
          originalSegment: "since 2 years",
          correctedSegment: "for 2 years",
          errorType: "grammar",
          explanationFr: "Pour exprimer une durée écoulée, on utilise 'for' (for 2 years). 'Since' s'utilise uniquement pour un point de départ précis (since 2024).",
          tip: "For + durée (for 3 days) vs Since + date précise (since Monday).",
        ),
      );
    }

    // Réponses ouvertes variées selon la longueur du texte
    final responses = [
      "That makes total sense! In American English, we love keeping conversations direct and engaging. Could you tell me a little more about that?",
      "That's really interesting! How would you explain that if you were talking to an American colleague?",
      "I love how you phrased that! What was the most exciting part of it for you?",
      "Spot on! Practice makes progress. What would you like us to explore next together?",
    ];
    final selectedReply = responses[input.length % responses.length];

    return GeminiResponse(
      replyEn: selectedReply,
      feedback: CorrectionFeedback.clean(),
    );
  }
}
