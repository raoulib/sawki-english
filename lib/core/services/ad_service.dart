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

  Future<void> init() async {
    if (_isInitialized) return;
    if (!MonetizationConfig.enableAds) {
      debugPrint("Ads disabled by configuration.");
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint("AdMob initialized successfully. Loading initial rewarded ad...");
      _loadRewardedAd();
    } catch (e) {
      debugPrint("Error initializing MobileAds: $e");
    }
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
    if (!MonetizationConfig.enableAds) {
      onRewardEarned();
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
