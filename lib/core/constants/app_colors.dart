import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF1E40AF); // Bleu Royal Américain
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);

  static const Color secondary = Color(0xFFF59E0B); // Doré XP / Streaks
  static const Color secondaryLight = Color(0xFFFBBF24);

  // Couleurs sémantiques
  static const Color success = Color(0xFF58CC02); // Vert Duolingo iconique
  static const Color successLight = Color(0xFFD7FFB8);
  static const Color error = Color(0xFFFF4B4B); // Rouge Duolingo
  static const Color errorLight = Color(0xFFFFDFE0);
  static const Color warning = Color(0xFFFF9600);

  // Design System Duolingo 3D ("Djalingo" Tactile Palette)
  static const Color duoGreen = Color(0xFF58CC02);
  static const Color duoGreenDark = Color(0xFF46A302);
  static const Color duoGreenLight = Color(0xFFD7FFB8);

  static const Color duoBlue = Color(0xFF1CB0F6);
  static const Color duoBlueDark = Color(0xFF1899D6);
  static const Color duoBlueLight = Color(0xFFDDF4FF);

  static const Color duoGold = Color(0xFFFFC800);
  static const Color duoGoldDark = Color(0xFFE5A500);
  static const Color duoGoldLight = Color(0xFFFFF4D0);

  static const Color duoRed = Color(0xFFFF4B4B);
  static const Color duoRedDark = Color(0xFFEA2B2B);
  static const Color duoRedLight = Color(0xFFFFDFE0);

  static const Color duoOrange = Color(0xFFFF9600);
  static const Color duoOrangeDark = Color(0xFFE58500);

  static const Color duoGrey = Color(0xFFE5E5E5);
  static const Color duoGreyDark = Color(0xFFAFAFAF);
  static const Color duoGreyLight = Color(0xFFF7F7F7);

  static const Color duoCardBorder = Color(0xFFE5E7EB);
  static const Color duoTextDark = Color(0xFF4B4B4B);
  static const Color duoTextMuted = Color(0xFF777777);

  static const Color duoSuccessBg = Color(0xFFD7FFB8);
  static const Color duoErrorBg = Color(0xFFFFDFE0);

  // Couleurs Tuteur Bilingue & Explications FR
  static const Color frenchExplanation = Color(0xFF7C3AED); // Violet pédagogique
  static const Color frenchExplanationLight = Color(0xFFEDE9FE);

  // Neutres & Fonds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFF1F5F9);

  // Textes
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Tokens Thème Sombre (Dark Mode Slate 900 / 800)
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF334155);
  static const Color darkCardBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Helpers contextuels adaptatifs selon le thème actif (Clair / Sombre)
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color bg(BuildContext context) => isDark(context) ? darkBg : background;
  static Color card(BuildContext context) => isDark(context) ? darkSurface : surface;
  static Color cardElevated(BuildContext context) => isDark(context) ? darkSurfaceElevated : surfaceElevated;
  static Color cardBorder(BuildContext context) => isDark(context) ? darkCardBorder : duoCardBorder;
  static Color text(BuildContext context) => isDark(context) ? darkTextPrimary : textPrimary;
  static Color subtext(BuildContext context) => isDark(context) ? darkTextSecondary : textSecondary;

  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tutorGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
