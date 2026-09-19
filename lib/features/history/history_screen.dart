import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/data/curriculum_data.dart';
import '../evaluation/certificate_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final profile = provider.profile;
    final completedCount = profile.completedLessons.length;
    final totalLessons = 120;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Historique & Progression 📜',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte Résumé Global
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('⭐ XP Total', '${profile.xp}', Colors.amber),
                    _buildStatItem('🔥 Série', '${profile.streakDays} j', Colors.orangeAccent),
                    _buildStatItem('📚 Leçons', '$completedCount / $totalLessons', Colors.lightBlueAccent),
                  ],
                ),
                const Divider(height: 28, color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Niveau actuel : ${profile.currentLevel}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: profile.isCertified ? Colors.amber : Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        profile.isCertified ? '🏅 Certifié Master' : 'En apprentissage',
                        style: TextStyle(
                          color: profile.isCertified ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1 : Statut du Grand Examen Master & Certification
          const Text(
            'Certification Officielle Sawki English',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: profile.isCertified ? Colors.amber.shade100 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.military_tech,
                    color: profile.isCertified ? Colors.amber.shade800 : Colors.grey,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.isCertified
                            ? 'Diplôme Validé (${profile.masterExamScore}%) 🎉'
                            : (profile.masterExamScore != null
                                ? 'Dernier score : ${profile.masterExamScore}% (Seuil 80%)'
                                : 'Grand Examen non encore passé'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.isCertified && profile.masterExamDate != null
                            ? 'Délivré le ${DateFormat('dd/MM/yyyy').format(profile.masterExamDate!)}'
                            : 'Nécessite 80% de bonnes réponses pour l\'obtention du diplôme.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (profile.isCertified)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificateScreen(
                              profile: profile,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download, size: 15),
                      label: const Text('Diplôme', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2 : Historique des Examens de Niveau
          const Text(
            'Examens de Paliers Validés (CECRL)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...['A0', 'A1', 'A2', 'B1', 'B2', 'C1'].map((levelId) {
            final score = profile.evaluationScores[levelId];
            final passed = (score ?? 0) >= 80;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: passed ? Colors.green.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: passed ? Colors.green.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            levelId,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: passed ? Colors.green.shade800 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getLevelName(levelId),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: passed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$score% ${passed ? '✓ Validé' : 'Non validé'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: passed ? const Color(0xFF16A34A) : Colors.red,
                        ),
                      ),
                    )
                  else
                    const Text('Non passé', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Section 3 : Leçons Récentes Complétées
          const Text(
            'Journal des Leçons Terminées',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (profile.completedLessons.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  'Aucune leçon complétée pour le moment.\nCommencez votre première leçon dans l\'onglet Parcours !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...profile.completedLessons.reversed.take(10).map((lessonId) {
              final lesson = CurriculumData.getLessonById(lessonId);
              final title = lesson != null ? lesson.title : 'Leçon $lessonId';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+20 XP',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  String _getLevelName(String id) {
    switch (id) {
      case 'A0':
        return 'Débutant Absolu';
      case 'A1':
        return 'Débutant Fondations';
      case 'A2':
        return 'Élémentaire Pratique';
      case 'B1':
        return 'Intermédiaire Autonome';
      case 'B2':
        return 'Intermédiaire Supérieur';
      case 'C1':
        return 'Avancé Professionnel';
      default:
        return 'Palier $id';
    }
  }
}
