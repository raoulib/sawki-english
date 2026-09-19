class CorrectionFeedback {
  final bool hasError;
  final String originalSegment;
  final String correctedSegment;
  final String errorType; // 'grammar', 'syntax', 'vocabulary', 'spelling', 'pronunciation'
  final String explanationFr; // Explication en français de la règle
  final String tip; // Astuce mnémotechnique
  final String? americanVariant; // Précision culturelle/lexicale américaine

  CorrectionFeedback({
    required this.hasError,
    this.originalSegment = '',
    this.correctedSegment = '',
    this.errorType = 'grammar',
    this.explanationFr = '',
    this.tip = '',
    this.americanVariant,
  });

  factory CorrectionFeedback.clean() {
    return CorrectionFeedback(hasError: false);
  }

  factory CorrectionFeedback.fromMap(Map<String, dynamic> map) {
    return CorrectionFeedback(
      hasError: map['has_error'] == true || map['hasError'] == true,
      originalSegment: map['original_segment'] ?? map['originalSegment'] ?? '',
      correctedSegment: map['corrected_segment'] ?? map['correctedSegment'] ?? '',
      errorType: map['error_type'] ?? map['errorType'] ?? 'grammar',
      explanationFr: map['explanation_fr'] ?? map['explanationFr'] ?? '',
      tip: map['tip'] ?? '',
      americanVariant: map['american_variant'] ?? map['americanVariant'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'has_error': hasError,
      'original_segment': originalSegment,
      'corrected_segment': correctedSegment,
      'error_type': errorType,
      'explanation_fr': explanationFr,
      'tip': tip,
      'american_variant': americanVariant,
    };
  }
}
