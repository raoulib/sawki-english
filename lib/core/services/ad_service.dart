import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/monetization_config.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isInitialized = false;

  bool get isRewardedAdLoaded => _rewardedAd != null;

  /// Les identifiants publicitaires configurés sont uniquement Android.
  /// Sur iOS, il faudrait un App ID AdMob iOS (GADApplicationIdentifier) :
  /// sans lui, le SDK fait planter l'application au démarrage.
  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _adsActive => MonetizationConfig.enableAds && isSupportedPlatform;

  Future<void> init() async {
    if (_isInitialized) return;
    if (!_adsActive) {
      debugPrint("Ads disabled (configuration or unsupported platform).");
      return;
    }
    try {
      // 1. Recueillir le consentement (Google UMP) avant toute requête publicitaire.
      //    Obligatoire pour les utilisateurs de l'EEE, du Royaume-Uni et de Suisse.
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) {
        debugPrint("Consent not obtained: ads will not be requested.");
        return;
      }

      // 2. Limiter le contenu publicitaire à un niveau adapté à une app éducative.
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
      );

      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint("AdMob initialized successfully. Loading initial rewarded ad...");
      _loadRewardedAd();
    } catch (e) {
      debugPrint("Error initializing MobileAds: $e");
    }
  }

  /// Met à jour les informations de consentement puis affiche le formulaire si nécessaire.
  Future<void> _gatherConsent() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) {
            debugPrint("Consent form error: ${error.message}");
          }
        });
        if (!completer.isCompleted) completer.complete();
      },
      (FormError error) {
        debugPrint("Consent info update failed: ${error.message}");
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  /// Indique si l'utilisateur doit pouvoir modifier ses choix publicitaires
  /// (bouton « Choix de confidentialité publicitaire » dans les réglages).
  Future<bool> isPrivacyOptionsRequired() async {
    if (!_adsActive) return false;
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  /// Rouvre le formulaire de consentement publicitaire.
  Future<void> showPrivacyOptionsForm() async {
    await ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) debugPrint("Privacy options form error: ${error.message}");
    });
  }

  void _loadRewardedAd() {
    if (_isAdLoading || _rewardedAd != null) return;
    _isAdLoading = true;

    final adUnitId = MonetizationConfig.rewardedAdUnitId;
    debugPrint("Loading Rewarded Ad with unit ID: $adUnitId");

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint("Rewarded Ad loaded successfully.");
          _rewardedAd = ad;
          _isAdLoading = false;
          _setAdCallbacks(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint("Rewarded Ad failed to load: ${error.message} (code: ${error.code})");
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  void _setAdCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint("Rewarded Ad showed full screen content.");
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint("Rewarded Ad dismissed.");
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Précharger la prochaine pub
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("Rewarded Ad failed to show: ${error.message}");
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );
  }

  /// Affiche la vidéo récompensée Google AdMob officielle.
  /// Si l'annonce n'est pas disponible, informe l'utilisateur proprement.
  Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback onRewardEarned,
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailed,
  }) async {
    // Pubs désactivées volontairement dans la configuration : récompense directe.
    if (!MonetizationConfig.enableAds) {
      onRewardEarned();
      return;
    }

    // Plateforme sans pubs configurées (iOS, web) : pas de récompense gratuite,
    // sinon les crédits IA seraient illimités.
    if (!isSupportedPlatform) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les vidéos récompensées ne sont pas disponibles sur cet appareil. Vos sessions se rechargent chaque jour.'),
          ),
        );
      }
      if (onAdFailed != null) onAdFailed();
      return;
    }

    if (_rewardedAd != null) {
      // VRAIE PUB GOOGLE ADMOB OFFICIELLE
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint("User earned reward from AdMob: ${reward.amount} ${reward.type}");
          onRewardEarned();
        },
      );
      return;
    }

    // Si AdMob n'est pas prêt, informer l'utilisateur proprement
    debugPrint("AdMob not ready. Informing user.");
    _loadRewardedAd(); // Relancer le chargement

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E3A8A),
          duration: Duration(seconds: 4),
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.amber, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Publicité non disponible pour le moment. Vérifiez votre connexion et réessayez.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );

      if (onAdFailed != null) onAdFailed();
    }
  }
}
