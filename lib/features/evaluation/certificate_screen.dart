import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_profile.dart';

class CertificateScreen extends StatefulWidget {
  final UserProfile profile;

  const CertificateScreen({super.key, required this.profile});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final GlobalKey _certificateKey = GlobalKey();
  bool _isExporting = false;

  Future<Uint8List?> _captureCertificate() async {
    try {
      final boundary = _certificateKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Erreur capture diplôme: $e');
      return null;
    }
  }

  Future<void> _downloadDiploma() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureCertificate();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de générer l\'image du diplôme.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final cleanName = widget.profile.name.trim().replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = 'Diplome_Sawki_English_${cleanName.isEmpty ? "Apprenant" : cleanName}.png';

      File? savedPublicFile;
      // 1. Essayer le dossier public Download d'Android
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final publicFile = File('${downloadDir.path}/$fileName');
          await publicFile.writeAsBytes(bytes, flush: true);
          savedPublicFile = publicFile;
        }
      } catch (_) {}

      // 2. Sauvegarde dans le stockage de documents de l'application
      final appDir = await getApplicationDocumentsDirectory();
      final appFile = File('${appDir.path}/$fileName');
      await appFile.writeAsBytes(bytes, flush: true);

      final targetPath = savedPublicFile?.path ?? appFile.path;
      final shortLocation = savedPublicFile != null ? 'dossier Téléchargements (Download)' : 'l\'espace sécurisé de l\'application';

      if (mounted) {
        _showDownloadSuccessDialog(targetPath, shortLocation, appFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareDiploma() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureCertificate();
      if (bytes == null) return;

      final cleanName = widget.profile.name.trim().replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = 'Diplome_Sawki_English_${cleanName.isEmpty ? "Apprenant" : cleanName}.png';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
          text: '🎓 Diplôme Officiel de Maîtrise Bilingue Sawki English décerné à ${widget.profile.name.isNotEmpty ? widget.profile.name : "l'Apprenant Exemplaire"} avec un score de ${widget.profile.masterExamScore ?? 100}% ! Félicitations !',
          subject: 'Diplôme Officiel Sawki English - ${widget.profile.name}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showDownloadSuccessDialog(String path, String locationName, File file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 26)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Diplôme Enregistré !',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre diplôme officiel a été généré avec succès en haute définition (qualité HD imprimable).',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enregistré dans : $locationName\nFichier : ${path.split(Platform.pathSeparator).last}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _shareDiploma();
            },
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Partager / Transférer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.profile.masterExamDate != null
        ? '${widget.profile.masterExamDate!.day.toString().padLeft(2, '0')}/${widget.profile.masterExamDate!.month.toString().padLeft(2, '0')}/${widget.profile.masterExamDate!.year}'
        : 'Aujourd\'hui';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Diplôme Officiel Sawki English', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Partager le diplôme',
            onPressed: _isExporting ? null : _shareDiploma,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              // RepaintBoundary pour capturer le diplôme au pixel près
              RepaintBoundary(
                key: _certificateKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 4), // Bordure or
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // En-tête avec sceau
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('🇺🇸', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'SAWKI ENGLISH ACADEMY',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const Text(
                                  'OFFICIAL CERTIFICATE OF FLUENCY',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    letterSpacing: 1.5,
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('🎓', style: TextStyle(fontSize: 32)),
                        ],
                      ),
                      const SizedBox(height: 22),

                      const Text(
                        'CERTIFICAT D\'EXCELLENCE & MAÎTRISE BILINGUE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ce certificat officiel atteste que',
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),

                      // Nom de l'apprenant
                      Text(
                        widget.profile.name.isNotEmpty ? widget.profile.name : 'L\'Apprenant Exemplaire',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'a validé avec brio l\'intégralité des 6 niveaux du cursus Sawki English (de Fondations Zéro à Maîtrise C1), attestant de son excellente maîtrise de l\'anglais américain parlé et écrit, de sa fluidité spontanée et de ses compétences professionnelles internationales.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 20),

                      // Score et Sceau doré
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD4AF37)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, color: Color(0xFFD4AF37), size: 28),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Score Final : ${widget.profile.masterExamScore ?? 100}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const Text(
                                    'Niveau : C1 - Maîtrise Bilingue (Score ≥ 80%)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Date et Signature
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Délivré le :', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Validé par :', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(
                                  'Sarah 🇺🇸 (Coach Américaine)',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bouton Télécharger mon Diplôme
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _downloadDiploma,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.file_download_outlined, color: Colors.black, size: 22),
                  label: Text(
                    _isExporting ? 'Génération en cours...' : 'Télécharger mon Diplôme (Image HD) 📥',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37), // Couleur dorée prestigieuse
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bouton Partager le diplôme
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : _shareDiploma,
                  icon: const Icon(Icons.share, color: Colors.white, size: 18),
                  label: const Text(
                    'Partager mon Diplôme (WhatsApp, Drive...) 📤',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton Fermer
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  label: const Text('Fermer et continuer ma pratique', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
