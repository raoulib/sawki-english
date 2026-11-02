import 'package:flutter/foundation.dart';
import '../models/correction_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class GeminiResponse {
  final String replyEn;
  final CorrectionFeedback feedback;

  GeminiResponse({
    required this.replyEn,
    required this.feedback,
  });
}

class GeminiService {
  /// Analyse le message de l'apprenant et génère une réponse du tuteur.
  ///
  /// L'appel passe par la fonction Supabase « gemini » : la clé Gemini reste sur
  /// le serveur, qui applique aussi la limite quotidienne. Sans réseau, ou si
  /// le serveur ne répond pas, le moteur hors-ligne prend le relais.
  static Future<GeminiResponse> sendMessage({
    required String userMessage,
    required String userLevel,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final cleanInput = userMessage.trim();
    if (cleanInput.isEmpty) {
      return GeminiResponse(
        replyEn: "I'm listening! Feel free to say or type anything in English.",
        feedback: CorrectionFeedback.clean(),
      );
    }

    final auth = AuthService();
    final client = auth.client;
    if (client != null && await auth.ensureSession()) {
      try {
        final history = conversationHistory == null
            ? <Map<String, String>>[]
            : (conversationHistory.length > 4
                ? conversationHistory.sublist(conversationHistory.length - 4)
                : conversationHistory);

        final res = await client.functions
            .invoke('gemini', body: {
              'mode': 'chat',
              'message': cleanInput,
              'level': userLevel,
              'history': history,
            })
            .timeout(const Duration(seconds: 20));

        final data = res.data;
        if (res.status == 200 && data is Map) {
          final jsonMap = Map<String, dynamic>.from(data);
          return GeminiResponse(
            replyEn: jsonMap['reply_en'] ?? "Hey there! How's your English practice going today?",
            feedback: CorrectionFeedback.fromMap(jsonMap),
          );
        }
        debugPrint("Gemini function status: ${res.status}");
      } on FunctionException catch (e) {
        if (e.status == 429) return dailyLimitResponse();
        debugPrint("Gemini function error: ${e.status} ${e.details}");
      } catch (e) {
        debugPrint("Gemini function exception: $e");
      }
    }

    // Moteur dynamique hors-ligne si le réseau ou le serveur n'a pas répondu
    return generateOfflineSmartResponse(cleanInput, userLevel);
  }

  /// Réponse affichée quand la limite quotidienne fixée par le serveur est atteinte.
  static GeminiResponse dailyLimitResponse() {
    return GeminiResponse(
      replyEn:
          "We've reached today's limit for live AI conversations. Come back tomorrow, and keep practicing with your lessons in the meantime!\n\n(Limite quotidienne atteinte pour le tuteur IA. Elle se recharge demain.)",
      feedback: CorrectionFeedback.clean(),
    );
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
