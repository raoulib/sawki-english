/// Configuration centralisée de la monétisation pour Sawki English.
/// Éditeur : Sawki Group (Ibrahim Moudy Ibrahima)
/// Référence AdMob : pub-5380251672853075
/// App ID AdMob : ca-app-pub-5380251672853075~3361823057
class MonetizationConfig {
  // --- INTERRUPTEURS PRINCIPAUX ---
  /// Active ou désactive toutes les publicités dans l'application.
  /// Mettre à `false` pour une version sans aucune pub.
  static const bool enableAds = true;

  /// Active ou désactive le système d'abonnement in-app (Google Play Billing).
  static const bool enableInAppPurchases = true;

  /// ⚠️ MODE TEST / PRODUCTION
  /// Passez à `false` UNIQUEMENT après avoir :
  /// 1. Créé vos blocs d'annonces dans la console AdMob
  /// 2. Renseigné les vrais IDs ci-dessous (prodBanner... et prodRewarded...)
  /// 3. Publié l'app sur Google Play (les annonces prod ne marchent PAS en debug)
  static const bool isTestMode = true;

  // --- PARAMÈTRES DES VIDÉOS RÉCOMPENSÉES (REWARDED ADS) & ÉNERGIE ---
  /// Nombre de sessions de conversation IA quotidiennes de base offertes gratuitement (rechargées chaque jour).
  static const int dailyFreeEnergyBase = 3;

  /// Nombre de sessions de conversation IA offertes par vidéo publicitaire visionnée.
  static const int rewardConversationsPerAd = 1;

  /// Nombre de points XP offerts par vidéo publicitaire visionnée.
  static const int rewardXpPerAd = 20;

  /// Permet de retenter un examen de niveau sans attendre après avoir vu une vidéo.
  static const bool allowAdToRetryEvaluation = true;

  // --- IDENTIFIANTS ADMOB DE TEST OFFICIELS GOOGLE (Android) ---
  // Ces identifiants sont fournis par Google pour les tests uniquement.
  // Ils affichent des annonces fictives et ne génèrent aucun revenu.
  // https://developers.google.com/admob/android/test-ads
  static const String testBannerAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testRewardedAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';

  // --- IDENTIFIANTS DE PRODUCTION SAWKI ENGLISH ---
  // Éditeur : pub-5380251672853075
  // App : ca-app-pub-5380251672853075~3361823057
  //
  // ⚠️ INSTRUCTIONS POUR RENSEIGNER VOS IDS :
  // 1. Connectez-vous à https://admob.google.com
  // 2. Allez dans : Applications > Sawki English > Blocs d'annonces
  // 3. Cliquez "Ajouter un bloc d'annonces"
  // 4. Créez un bloc "Bannière" → copiez l'ID ici (prodBannerAdUnitIdAndroid)
  // 5. Créez un bloc "Avec récompense" → copiez l'ID ici (prodRewardedAdUnitIdAndroid)
  // 6. Passez isTestMode = false
  //
  // Format attendu : ca-app-pub-5380251672853075/XXXXXXXXXX
  static const String prodBannerAdUnitIdAndroid =
      'ca-app-pub-5380251672853075/XXXXXXXXXX'; // ← Remplacez XXXXXXXXXX par votre ID bannière
  static const String prodRewardedAdUnitIdAndroid =
      'ca-app-pub-5380251672853075/YYYYYYYYYY'; // ← Remplacez YYYYYYYYYY par votre ID récompense

  /// Récupère l'identifiant de bannière selon le mode
  static String get bannerAdUnitId =>
      isTestMode ? testBannerAdUnitIdAndroid : prodBannerAdUnitIdAndroid;

  /// Récupère l'identifiant de vidéo récompensée selon le mode
  static String get rewardedAdUnitId =>
      isTestMode ? testRewardedAdUnitIdAndroid : prodRewardedAdUnitIdAndroid;
}
