import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  static String get interstitialAdUnitId => 'ca-app-pub-3940256099942544/1033173712';
  static String get bannerAdUnitId => 'ca-app-pub-3940256099942544/6300978111';
  static String get rewardAdUnitId => 'ca-app-pub-3940256099942544/5224354917';
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;

  void createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => print('InterstitialAd failed to load: $error'),
      ),
    );
  }

  void createRewardAd() {
    RewardedAd.load(
      adUnitId: rewardAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) => print('RewardedVideoAd failed to load: $error'),
      ),
    );
  }

  void showRewardAd(VoidCallback callback){
    if(_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad,reward) {
              callback.call();
        },
      );
    }
  }

  void showAd() {
    if (_interstitialAd == null) return;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        print('Admob error: $error');
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  Widget showAdBanner() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => print('Admob banner loaded.'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Admob banner failed to load: $error');
        },
      ),
    )..load();
    return Container(
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
    );
  }
}