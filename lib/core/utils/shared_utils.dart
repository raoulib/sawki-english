/// Utilitaires partagés pour Sawki English.
/// Regroupe les fonctions dupliquées extraites de plusieurs écrans.
library;

/// Évalue si la prononciation orale correspond à la phrase attendue.
/// Utilise une correspondance par mots avec un seuil de 70%.
bool evaluatePronunciation(String spoken, String expected) {
  final normSpoken = _normalizeForPronunciation(spoken);
  final normExpected = _normalizeForPronunciation(expected);

  if (normSpoken.isEmpty) return false;
  if (normSpoken == normExpected) return true;

  final spokenWords = normSpoken.split(' ').where((w) => w.isNotEmpty).toList();
  final expectedWords = normExpected.split(' ').where((w) => w.isNotEmpty).toList();

  if (expectedWords.isEmpty) return false;

  int matchedCount = 0;
  for (final word in expectedWords) {
    if (spokenWords.contains(word)) {
      matchedCount++;
    }
  }

  final ratio = matchedCount / expectedWords.length;
  return ratio >= 0.70;
}

/// Normalise une chaîne pour la comparaison de prononciation.
/// Convertit les nombres en mots anglais et supprime la ponctuation.
///
/// ⚠️ IMPORTANT : Les nombres multi-chiffres DOIVENT être traités AVANT
/// les chiffres simples (ex: '100' avant '1') sinon '10' sera transformé
/// en 'onezero' au lieu de 'ten'.
String _normalizeForPronunciation(String s) {
  return s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      // Nombres multi-chiffres D'ABORD (du plus grand au plus petit)
      .replaceAll('100', 'hundred')
      .replaceAll('90', 'ninety')
      .replaceAll('80', 'eighty')
      .replaceAll('70', 'seventy')
      .replaceAll('60', 'sixty')
      .replaceAll('50', 'fifty')
      .replaceAll('40', 'forty')
      .replaceAll('30', 'thirty')
      .replaceAll('20', 'twenty')
      .replaceAll('10', 'ten')
      // PUIS chiffres simples
      .replaceAll('9', 'nine')
      .replaceAll('8', 'eight')
      .replaceAll('7', 'seven')
      .replaceAll('6', 'six')
      .replaceAll('5', 'five')
      .replaceAll('4', 'four')
      .replaceAll('3', 'three')
      .replaceAll('2', 'two')
      .replaceAll('1', 'one')
      .replaceAll('0', 'zero')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
