import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Test Ad Unit IDs - Replace with your actual Ad Unit IDs for production
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Production Ad Unit IDs (replace these with your actual IDs)
  static const String _prodBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String _prodRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  String get bannerAdUnitId => kDebugMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
  String get interstitialAdUnitId => kDebugMode ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  String get rewardedAdUnitId => kDebugMode ? _testRewardedAdUnitId : _prodRewardedAdUnitId;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  // Initialize Mobile Ads SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    
    // Set COPPA compliance for apps targeted at children
    // MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(
    //     tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
    //   ),
    // );
    
    // Pre-load ads
    loadBannerAd();
    loadInterstitialAd();
    loadRewardedAd();
  }

  // Banner Ad
  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          if (kDebugMode) {
            print('Banner ad loaded');
          }
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdLoaded = false;
          ad.dispose();
          if (kDebugMode) {
            print('Banner ad failed to load: $error');
          }
        },
        onAdOpened: (ad) {
          if (kDebugMode) {
            print('Banner ad opened');
          }
        },
        onAdClosed: (ad) {
          if (kDebugMode) {
            print('Banner ad closed');
          }
        },
      ),
    );
    _bannerAd?.load();
  }

  // Interstitial Ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          if (kDebugMode) {
            print('Interstitial ad loaded');
          }
          
          _interstitialAd?.setImmersiveMode(true);
          
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              if (kDebugMode) {
                print('Interstitial ad showed');
              }
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              // Preload next ad
              loadInterstitialAd();
              if (kDebugMode) {
                print('Interstitial ad dismissed');
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              loadInterstitialAd();
              if (kDebugMode) {
                print('Interstitial ad failed to show: $error');
              }
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          if (kDebugMode) {
            print('Interstitial ad failed to load: $error');
          }
        },
      ),
    );
  }

  // Rewarded Ad
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          if (kDebugMode) {
            print('Rewarded ad loaded');
          }
          
          _rewardedAd?.setImmersiveMode(true);
          
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              if (kDebugMode) {
                print('Rewarded ad showed');
              }
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              loadRewardedAd();
              if (kDebugMode) {
                print('Rewarded ad dismissed');
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              loadRewardedAd();
              if (kDebugMode) {
                print('Rewarded ad failed to show: $error');
              }
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          if (kDebugMode) {
            print('Rewarded ad failed to load: $error');
          }
        },
      ),
    );
  }

  // Show ads
  void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          loadInterstitialAd();
          onAdDismissed?.call();
        },
      );
      _interstitialAd?.show();
    } else {
      if (kDebugMode) {
        print('Interstitial ad not ready');
      }
      onAdDismissed?.call();
    }
  }

  void showRewardedAd({
    required Function(RewardItem reward) onRewarded,
    VoidCallback? onAdDismissed,
  }) {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd?.show(onUserEarnedReward: (ad, reward) {
        onRewarded(reward);
        if (kDebugMode) {
          print('User earned reward: ${reward.amount} ${reward.type}');
        }
      });
      
      _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          loadRewardedAd();
          onAdDismissed?.call();
        },
      );
    } else {
      if (kDebugMode) {
        print('Rewarded ad not ready');
      }
      onAdDismissed?.call();
    }
  }

  // Getters
  BannerAd? get bannerAd => _isBannerAdLoaded ? _bannerAd : null;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  // Dispose
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  void disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
  }

  void disposeAll() {
    disposeBannerAd();
    disposeInterstitialAd();
    disposeRewardedAd();
  }
}
