import 'package:flutter_test/flutter_test.dart';
import 'package:sawki_english/core/models/user_profile.dart';
import 'package:sawki_english/core/data/curriculum_data.dart';
import 'package:sawki_english/core/services/gemini_service.dart';
import 'package:sawki_english/core/config/monetization_config.dart';
import 'dart:typed_data';
import 'package:sawki_english/core/config/app_config.dart';
import 'package:sawki_english/core/services/google_ai_tts_service.dart';
import 'package:sawki_english/core/services/tts_service.dart';

import 'package:sawki_english/core/services/cloud_sync_service.dart';
import 'package:sawki_english/core/theme/app_theme.dart';
import 'package:sawki_english/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sawki English Core Tests', () {
    test('CloudSyncService recovery key generation and lossless parsing', () {
      final original = UserProfile(
        name: 'Moudi',
        currentLevel: 'B1',
        xp: 1250,
        streakDays: 14,
        completedLessons: ['A0_1', 'A0_2', 'A1_1', 'B1_5'],
        evaluationScores: {'A0': 95, 'A1': 88},
        masterExamScore: 92,
        email: 'moudi@sawkigroup.com',
        isEmailVerified: true,
      );

      final key = CloudSyncService.generateRecoveryKey(original);
      expect(key.startsWith('SAWKI-REC-'), true);

      final restored = CloudSyncService.parseRecoveryKey(key);
      expect(restored, isNotNull);
      expect(restored!.name, 'Moudi');
      expect(restored.currentLevel, 'B1');
      expect(restored.xp, 1250);
      expect(restored.streakDays, 14);
      expect(restored.completedLessons, contains('B1_5'));
      expect(restored.evaluationScores['A0'], 95);
      expect(restored.masterExamScore, 92);
      expect(restored.isCertified, true);
      expect(restored.email, 'moudi@sawkigroup.com');
      expect(restored.isEmailVerified, true);

      // Verify invalid key handling
      expect(CloudSyncService.parseRecoveryKey('SAWKI-INVALID-KEY'), isNull);
      expect(CloudSyncService.parseRecoveryKey(''), isNull);
    });

    test('CloudSyncService Supabase row parsing roundtrip', () {
      final fakeSupabaseRow = {
        'id': 'abc-123',
        'email': 'apprenant@sawkigroup.com',
        'name': 'Fati',
        'current_level': 'B2',
        'target_goal': 'Travail & Carrière',
        'xp': 3400,
        'streak_days': 21,
        'completed_lessons': ['A0_1', 'A1_1', 'B2_10'],
        'evaluation_scores': {'A0': 100, 'A1': 95, 'B1': 88},
        'master_exam_score': 90,
        'is_certified': true,
        'is_premium': false,
      };

      final profile = CloudSyncService.fromSupabaseRow(fakeSupabaseRow);
      expect(profile.name, 'Fati');
      expect(profile.email, 'apprenant@sawkigroup.com');
      expect(profile.currentLevel, 'B2');
      expect(profile.xp, 3400);
      expect(profile.streakDays, 21);
      expect(profile.completedLessons, contains('B2_10'));
      expect(profile.evaluationScores['B1'], 88);
      expect(profile.masterExamScore, 90);
      expect(profile.isCertified, true);
      expect(profile.isEmailVerified, true);
    });

    test('UserProfile serialization test', () {
      final profile = UserProfile(
        name: 'Amadou',
        targetGoal: 'Voyage aux USA',
        currentLevel: 'A1',
        xp: 150,
        energyCredits: 7,
        email: 'amadou@example.com',
        isEmailVerified: true,
      );

      final map = profile.toMap();
      final reconstructed = UserProfile.fromMap(map);

      expect(reconstructed.name, 'Amadou');
      expect(reconstructed.currentLevel, 'A1');
      expect(reconstructed.xp, 150);
      expect(reconstructed.energyCredits, 7);
      expect(reconstructed.email, 'amadou@example.com');
      expect(reconstructed.isEmailVerified, true);
    });

    test('Curriculum levels have 80% passing threshold and 120 lessons total (20 per level)', () {
      final levels = CurriculumData.getLevels();
      expect(levels.length, 6);
      expect(levels.map((l) => l.id).toList(), ['A0', 'A1', 'A2', 'B1', 'B2', 'C1']);

      int totalLessons = 0;
      for (final level in levels) {
        expect(level.requiredPassingScore, 80,
            reason: 'Le niveau ${level.id} doit exiger 80% selon le cahier des charges');
        expect(level.lessons.length, 20,
            reason: 'Chaque niveau doit comporter exactement 20 leçons');
        expect(level.evaluationQuestions.isNotEmpty, true);
        totalLessons += level.lessons.length;
      }
      expect(totalLessons, 120);
    });

    test('Gemini offline smart fallback detects "I am agree" error', () {
      final response = GeminiService.generateOfflineSmartResponse(
        'Yes, I am agree with you',
        'A1',
      );

      expect(response.feedback.hasError, true);
      expect(response.feedback.correctedSegment, 'I agree');
      expect(response.feedback.explanationFr.isNotEmpty, true);
    });

    test('Gemini offline smart fallback detects "He don\'t" error', () {
      final response = GeminiService.generateOfflineSmartResponse(
        'He don\'t know the answer',
        'A1',
      );

      expect(response.feedback.hasError, true);
      expect(response.feedback.correctedSegment, 'he doesn\'t');
      expect(response.feedback.explanationFr.contains('doesn\'t'), true);
    });

    test('Gemini offline smart fallback answers French translation request in French', () {
      final response = GeminiService.generateOfflineSmartResponse(
        'peux-tu me traduire cela? ce un peu lourd pour moi je n\'ai pas bien compris',
        'A1',
      );

      expect(response.replyEn.contains('français'), true);
      expect(response.replyEn.contains('Pas de souci'), true);
    });

    test('Gemini offline smart fallback detects spelling error "watter"', () {
      final response = GeminiService.generateOfflineSmartResponse(
        'I drink watter every day',
        'A1',
      );

      expect(response.feedback.hasError, true);
      expect(response.feedback.correctedSegment, 'water');
      expect(response.feedback.errorType, 'spelling');
    });

    test('Master Exam questions and certification logic', () {
      final masterQuestions = CurriculumData.getMasterExamQuestions();
      expect(masterQuestions.length, greaterThanOrEqualTo(5));

      final profileUncertified = UserProfile(name: 'Sarah', masterExamScore: 75);
      expect(profileUncertified.isCertified, false);

      final profileCertified = UserProfile(name: 'Sarah', masterExamScore: 85);
      expect(profileCertified.isCertified, true);
    });

    test('Dynamic and randomized exam generation', () {
      final randomMaster = CurriculumData.getMasterExamQuestions(randomize: true);
      expect(randomMaster.length, 30); // 5 questions per level * 6 levels

      final levelA1 = CurriculumData.getLevelById('A1')!;
      final evalQuestions = CurriculumData.getEvaluationQuestionsForLevel(levelA1, count: 10, randomize: true);
      expect(evalQuestions.length, 10);
    });

    test('Grand Examen 3-failure lock and weakest level revalidation model logic', () {
      // 2 failures: not locked
      final p2 = UserProfile(name: 'Ali', masterExamFailedAttempts: 2, masterExamLockedLevel: 'A2');
      expect(p2.isMasterExamLocked, false);

      // 3 failures: locked to A2
      final p3 = UserProfile(name: 'Ali', masterExamFailedAttempts: 3, masterExamLockedLevel: 'A2');
      expect(p3.isMasterExamLocked, true);
      expect(p3.masterExamLockedLevel, 'A2');

      // Serialization in toMap & fromMap
      final map = p3.toMap();
      expect(map['masterExamFailedAttempts'], 3);
      expect(map['masterExamLockedLevel'], 'A2');

      final deserialized = UserProfile.fromMap(map);
      expect(deserialized.isMasterExamLocked, true);
      expect(deserialized.masterExamFailedAttempts, 3);
      expect(deserialized.masterExamLockedLevel, 'A2');
    });

    test('Monetization & Energy rules conform to user requirements', () {
      expect(MonetizationConfig.dailyFreeEnergyBase, 3);
      expect(MonetizationConfig.rewardXpPerAd, 20);
      expect(MonetizationConfig.rewardConversationsPerAd, 1);
    });

    test('Sentence builder punctuation normalization (Today is July fourth.)', () {
      String normalize(String s) =>
          s.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');

      final userWords = ['Today', 'is', 'July', 'fourth.'];
      const target = 'Today is July fourth.';

      expect(normalize(userWords.join(' ')), normalize(target));
    });

    test('TTS intelligent French vs American English speech routing', () {
      final tts = TtsService();

      expect(tts.isMainlyFrench("Bonjour, je n'ai pas bien compris la règle"), true);
      expect(tts.isMainlyFrench("En français, on utilise pour ou depuis ?"), true);
      expect(tts.isMainlyFrench("Hey there! How's your day going in Chicago?"), false);
      expect(tts.isMainlyFrench("I only stayed there for one night."), false);
    });

    test('Sawki Group copyright and branding metadata', () {
      expect(AppConfig.organization, 'Sawki Group');
      expect(AppConfig.copyright.contains('Sawki Group'), true);
      expect(AppConfig.copyright.contains('2026'), true);
      expect(AppConfig.poweredBy.contains('Sawki Group'), true);
    });

    test('Google AI TTS 44-byte WAV header generator from 24kHz PCM', () {
      final fakePcm = Uint8List(48000); // 1 second of 24kHz 16-bit mono
      final wav = GoogleAiTtsService.buildWavHeader(fakePcm, sampleRate: 24000);

      expect(wav.length, 48000 + 44);
      // 'RIFF' header
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      // 'WAVE'
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      // 'fmt '
      expect(String.fromCharCodes(wav.sublist(12, 16)), 'fmt ');
      // 'data'
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    });

    test('Free tier credit limits for Gemini AI conservation', () {
      final defaultProfile = UserProfile(name: 'TestUser');
      expect(defaultProfile.energyCredits, 3);
      expect(MonetizationConfig.dailyFreeEnergyBase, 3);
      expect(defaultProfile.isPremium, false);
    });

    test('AppTheme light and dark mode configurations and tokens', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.scaffoldBackgroundColor, AppColors.background);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBg);
      expect(dark.cardColor, AppColors.darkSurface);
      expect(AppColors.darkBg, const Color(0xFF0F172A));
      expect(AppColors.darkSurface, const Color(0xFF1E293B));
    });
  });
}
