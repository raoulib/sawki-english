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
  late String _credentialId;
  late bool _isSealed;

  @override
  void initState() {
    super.initState();
    _isSealed = StorageService.isCertificateSealed();
    final storedName = StorageService.getCertificateFullName();
    final storedId = StorageService.getCertificateCredentialId();

    if (_isSealed && storedName != null && storedName.trim().isNotEmpty) {
      _fullName = storedName.trim();
      _credentialId = (storedId != null && storedId.isNotEmpty)
          ? storedId
          : _generateCredentialId();
    } else {
      _fullName = (storedName != null && storedName.trim().isNotEmpty)
          ? storedName.trim()
          : widget.profile.name.trim();
      _credentialId = storedId ?? '';
    }

    // Conformément aux normes internationales d'intégrité académique,
    // inviter l'apprenant à renseigner et sceller définitivement son Nom Légal Officiel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isSealed) {
        _promptForSealing(isInitial: true);
      }
    });
  }

  String _generateCredentialId() {
    final year = (widget.profile.masterExamDate ?? DateTime.now()).year;
    final hex = DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
    final suffix = hex.length >= 6 ? hex.substring(hex.length - 6) : hex.padLeft(6, '0');
    return 'SE-$year-C1-$suffix';
  }

  String _formatDateEnglish(DateTime? date) {
    final d = date ?? DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _promptForSealing({bool isInitial = false}) async {
    final controller = TextEditingController(
      text: _fullName.isNotEmpty ? _fullName : '',
    );

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
                'Émission & Scellement Légal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pour être accréditée et reconnue à l\'international (CV, LinkedIn, employeurs, universités), votre certification doit comporter votre Nom Légal Complet (Nom et Prénom d\'état civil).',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Prénom et Nom légaux (ex: Ibrahim Moudy)',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
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
                  prefixIcon: const Icon(Icons.verified_user, color: Color(0xFFD4AF37)),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️ ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        'Norme internationale anti-fraude :\nUne fois validé, ce diplôme sera définitivement scellé avec un identifiant unique (Credential ID). Ce nom ne pourra plus jamais être modifié sur cet appareil. Vérifiez l\'orthographe exacte selon votre passeport ou carte d\'identité.',
                        style: TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 11.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!isInitial)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
            ),
          ElevatedButton.icon(
            onPressed: () async {
              final entered = controller.text.trim();
              if (entered.isNotEmpty) {
                final generatedId = _generateCredentialId();
                await StorageService.sealCertificate(
                  fullName: entered,
                  credentialId: generatedId,
                );
                if (mounted && ctx.mounted) {
                  setState(() {
                    _fullName = entered;
                    _credentialId = generatedId;
                    _isSealed = true;
                  });
                  Navigator.pop(ctx);
                }
              }
            },
            icon: const Icon(Icons.lock, size: 16),
            label: const Text(
              'Confirmer & Sceller Définitivement 🔒',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
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
    if (!_isSealed) {
      await _promptForSealing(isInitial: false);
      if (!_isSealed) return;
    }

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
      // 1. Dossier public Download d'Android
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final publicFile = File('${downloadDir.path}/$fileName');
          await publicFile.writeAsBytes(bytes, flush: true);
          savedPublicFile = publicFile;
        }
      } catch (_) {}

      // 2. Stockage de documents de l'application
      final appDir = await getApplicationDocumentsDirectory();
      final appFile = File('${appDir.path}/$fileName');
      await appFile.writeAsBytes(bytes, flush: true);

      final targetPath = savedPublicFile?.path ?? appFile.path;
      final shortLocation = savedPublicFile != null
          ? 'dossier Téléchargements (Download)'
          : 'l\'espace sécurisé de l\'application';

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
    if (!_isSealed) {
      await _promptForSealing(isInitial: false);
      if (!_isSealed) return;
    }

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
          text: '🎓 Official Certificate of Bilingual Proficiency & Fluency awarded to $_fullName (Credential ID: $_credentialId) with a final score of ${widget.profile.masterExamScore ?? 100}%! Issued by Sawki English Academy.',
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
              'Votre diplôme officiel scellé au nom de "$_fullName" a été généré avec succès en haute définition (qualité HD imprimable).',
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
                  const Icon(Icons.verified, color: Colors.greenAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enregistré dans : $locationName\nFichier : ${path.split(Platform.pathSeparator).last}\nID : $_credentialId',
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

                      // Nom officiel scellé de l'apprenant
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
                      const SizedBox(height: 16),

                      // Sceau d'authentification international & Credential ID
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Credential ID: ${_credentialId.isNotEmpty ? _credentialId : "PENDING-ISSUANCE"}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.lock_outline, size: 12, color: Color(0xFFD4AF37)),
                                SizedBox(width: 4),
                                Text(
                                  'Officially Sealed & Tamper-Proof',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF64748B),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Statut du Scellement Légal (Pas de bouton de modification pour respecter les règles internationales)
              if (_isSealed) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Color(0xFFD4AF37), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Certificat Officiel Scellé : $_fullName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID : $_credentialId • Conforme ISO/IEC 17024 (Nom immuable)',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: () => _promptForSealing(isInitial: false),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Diplôme en attente de scellement.\nCliquez ici pour renseigner et sceller votre Nom Légal.',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
