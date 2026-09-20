import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/storage_service.dart';

class CertificateScreen extends StatefulWidget {
  final UserProfile profile;

  const CertificateScreen({super.key, required this.profile});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final GlobalKey _certificateKey = GlobalKey();
  bool _isExporting = false;
  late String _fullName;

  @override
  void initState() {
    super.initState();
    final stored = StorageService.getCertificateFullName();
    if (stored != null && stored.trim().isNotEmpty) {
      _fullName = stored.trim();
    } else {
      _fullName = widget.profile.name.trim();
    }

    // Si aucun nom complet officiel n'a encore été enregistré,
    // inviter immédiatement l'apprenant à saisir son nom complet pour le document
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (stored == null || stored.trim().isEmpty) {
        _promptForFullName(isInitial: true);
      }
    });
  }

  String _formatDateEnglish(DateTime? date) {
    final d = date ?? DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _promptForFullName({bool isInitial = false}) async {
    final controller = TextEditingController(text: _fullName);
    await showDialog(
      context: context,
      barrierDismissible: !isInitial,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🎓', style: TextStyle(fontSize: 26)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nom Complet Officiel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Veuillez saisir votre Nom et Prénom complets (pour votre CV, LinkedIn, employeurs) tels qu\'ils doivent figurer sur votre certification officielle :',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Prénom et Nom (ex: Ibrahim Moudy)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                ),
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
        actions: [
          if (!isInitial)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
            ),
          ElevatedButton(
            onPressed: () {
              final entered = controller.text.trim();
              if (entered.isNotEmpty) {
                setState(() {
                  _fullName = entered;
                });
                StorageService.saveCertificateFullName(entered);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Valider pour le Diplôme', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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

      final cleanName = _fullName.trim().replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = 'Certificate_Sawki_English_${cleanName.isEmpty ? "Graduate" : cleanName}.png';

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

      final cleanName = _fullName.trim().replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = 'Certificate_Sawki_English_${cleanName.isEmpty ? "Graduate" : cleanName}.png';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
          text: '🎓 Official Certificate of Bilingual Proficiency & Fluency awarded to $_fullName with a final score of ${widget.profile.masterExamScore ?? 100}%! Issued by Sawki English Academy.',
          subject: 'Official Sawki English Certificate - $_fullName',
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
            Text(
              'Votre diplôme officiel au nom de "$_fullName" a été généré avec succès en haute définition (qualité HD imprimable).',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Official Certificate of Fluency', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFFD4AF37)),
            tooltip: 'Modifier le nom officiel',
            onPressed: () => _promptForFullName(isInitial: false),
          ),
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
                        'CERTIFICATE OF EXCELLENCE &\nBILINGUAL PROFICIENCY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: Color(0xFF1E3A8A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This official certificate is proudly awarded to',
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),

                      // Nom officiel de l'apprenant
                      Text(
                        _fullName.isNotEmpty ? _fullName : 'Distinguished Graduate',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'for successfully completing all 6 levels of the comprehensive Sawki English Curriculum (Foundations A0 through Advanced Mastery C1), demonstrating exceptional proficiency in spoken and written American English, spontaneous conversational fluency, and international professional communication skills.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textPrimary),
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
                                    'Final Examination Score: ${widget.profile.masterExamScore ?? 100}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const Text(
                                    'Proficiency Level: C1 - Bilingual Mastery (Passing Grade ≥ 80%)',
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
                                const Text('Date Issued:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDateEnglish(widget.profile.masterExamDate),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Certified & Validated by:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  'Sarah 🇺🇸 (Lead American Coach)',
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
              const SizedBox(height: 18),

              // Bouton pour modifier le Nom Complet
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _promptForFullName(isInitial: false),
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFFD4AF37), size: 18),
                  label: Text(
                    'Nom sur le document : ${_fullName.isNotEmpty ? _fullName : "À renseigner"} (Modifier ✏️)',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

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
                    _isExporting ? 'Generating Certificate...' : 'Télécharger mon Diplôme (Image HD) 📥',
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
                    'Partager mon Diplôme (LinkedIn, WhatsApp...) 📤',
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
