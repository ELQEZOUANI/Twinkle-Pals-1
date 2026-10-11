import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_contract.dart';

GameAds createGameAds() {
  if (defaultTargetPlatform != TargetPlatform.iOS) {
    return const DisabledAds('Rewarded ads are available in the iOS app.');
  }
  const configuredRewarded = String.fromEnvironment('ADMOB_REWARDED_IOS');
  const configuredInterstitial = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
  );
  const configuredAppOpen = String.fromEnvironment('ADMOB_APP_OPEN_IOS');
  const productionRewarded = 'ca-app-pub-2535194044471316/3260901736';
  const productionInterstitial = 'ca-app-pub-2535194044471316/3564154065';
  const productionAppOpen = 'ca-app-pub-2535194044471316/2251072399';
  const testRewarded = 'ca-app-pub-3940256099942544/1712485313';
  const testInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  const testAppOpen = 'ca-app-pub-3940256099942544/5575463023';
  final rewarded = configuredRewarded.isNotEmpty
      ? configuredRewarded
      : (kReleaseMode ? productionRewarded : testRewarded);
  final interstitial = configuredInterstitial.isNotEmpty
      ? configuredInterstitial
      : (kReleaseMode ? productionInterstitial : testInterstitial);
  final appOpen = configuredAppOpen.isNotEmpty
      ? configuredAppOpen
      : (kReleaseMode ? productionAppOpen : testAppOpen);
  // Production serving requires an explicit release configuration. Kids Category
  // iOS advertising also needs a provider/creative review before enabling it.
  if (kReleaseMode &&
      (!const bool.fromEnvironment('ENABLE_LIVE_ADS') ||
          !const bool.fromEnvironment('ENABLE_KIDS_IOS_ADS') ||
          rewarded.isEmpty ||
          interstitial.isEmpty)) {
    return const DisabledAds('Ads are not available in this version yet.');
  }
  return MobileGameAds(
    rewardedId: rewarded,
    interstitialId: interstitial,
    appOpenId: appOpen,
  );
}

class MobileGameAds implements GameAds {
  final String rewardedId, interstitialId, appOpenId;
  MobileGameAds({
    required this.rewardedId,
    required this.interstitialId,
    required this.appOpenId,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;
  final DateTime Function() _now;
  Future<void>? _preparing;
  Future<RewardedAd?>? _rewardedLoad;
  Future<InterstitialAd?>? _interstitialLoad;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  Future<AppOpenAd?>? _appOpenLoad;
  AppOpenAd? _appOpen;
  DateTime? _appOpenLoadedAt, _lastFullScreenClosed;
  bool _ready = false, _disposed = false, _showing = false;
  static const _loadTimeout = Duration(seconds: 12);
  static const _request = AdRequest(nonPersonalizedAds: true);

  @override
  String get unavailableMessage =>
      'No ad is available right now. Please try again later. Luna and Milo are always free.';

  @override
  Future<void> prepare() async {
    if (_ready || _disposed) return;
    await (_preparing ??= _initialize());
    if (!_ready) _preparing = null;
  }

  Future<void> _initialize() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          ageRestrictedTreatment: AgeRestrictedTreatment.child,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
      if (kReleaseMode && !await _privacyReady()) return;
      if (_disposed) return;
      await MobileAds.instance.initialize();
      if (_disposed) return;
      _ready = true;
      unawaited(_ensureRewarded());
      unawaited(_ensureInterstitial());
      unawaited(_ensureAppOpen());
    } catch (_) {
      // A privacy or SDK failure never prevents offline play.
      _ready = false;
    }
  }

  @override
  Future<void> prepareAppOpen() async {
    await prepare();
    await _ensureAppOpen();
  }

  Future<AppOpenAd?> _ensureAppOpen() async {
    if (!_ready || _disposed || appOpenId.isEmpty) return null;
    if (_appOpen != null) {
      if (_now().difference(_appOpenLoadedAt!) < const Duration(hours: 4)) {
        return _appOpen;
      }
      _appOpen!.dispose();
      _appOpen = null;
    }
    if (_appOpenLoad != null) return _appOpenLoad;
    _appOpenLoad = _loadAppOpen();
    try {
      return await _appOpenLoad;
    } finally {
      _appOpenLoad = null;
    }
  }

  Future<AppOpenAd?> _loadAppOpen() async {
    final result = Completer<AppOpenAd?>();
    final timeout = Timer(_loadTimeout, () {
      if (!result.isCompleted) result.complete(null);
    });
    try {
      await AppOpenAd.load(
        adUnitId: appOpenId,
        request: _request,
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            if (_disposed || result.isCompleted) {
              ad.dispose();
              return;
            }
            _appOpen = ad;
            _appOpenLoadedAt = _now();
            result.complete(ad);
          },
          onAdFailedToLoad: (_) {
            if (!result.isCompleted) result.complete(null);
          },
        ),
      );
    } catch (_) {
      if (!result.isCompleted) result.complete(null);
    }
    final ad = await result.future;
    timeout.cancel();
    return ad;
  }

  @override
  Future<void> showAppOpen(BuildContext context) async {
    if (_showing || _disposed || !context.mounted) return;
    // Returning from another ad must not immediately trigger an app-open ad.
    if (_lastFullScreenClosed != null &&
        _now().difference(_lastFullScreenClosed!) <
            const Duration(seconds: 30)) {
      return;
    }
    final ad = _appOpen;
    if (ad == null) {
      unawaited(prepareAppOpen());
      return;
    }
    if (_now().difference(_appOpenLoadedAt!) >= const Duration(hours: 4)) {
      ad.dispose();
      _appOpen = null;
      unawaited(_ensureAppOpen());
      return;
    }
    // Never await a load here: a late ad must not interrupt the game.
    _appOpen = null;
    _showing = true;
    final dismissed = Completer<void>();
    void finish(Ad ad) {
      ad.dispose();
      if (!dismissed.isCompleted) dismissed.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, _) => finish(ad),
    );
    try {
      await ad.show();
      await dismissed.future;
    } catch (_) {
      finish(ad);
    } finally {
      _showing = false;
      _lastFullScreenClosed = _now();
      if (!_disposed) unawaited(_ensureAppOpen());
    }
  }

  Future<bool> _privacyReady() async {
    final result = Completer<bool>();
    final timeout = Timer(const Duration(seconds: 15), () {
      if (!result.isCompleted) result.complete(false);
    });
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(tagForUnderAgeOfConsent: true),
      () async {
        if (result.isCompleted || _disposed) return;
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) async {
            try {
              final canRequest =
                  error == null &&
                  await ConsentInformation.instance.canRequestAds();
              if (!result.isCompleted) result.complete(canRequest);
            } catch (_) {
              if (!result.isCompleted) result.complete(false);
            }
          });
        } catch (_) {
          if (!result.isCompleted) result.complete(false);
        }
      },
      (_) {
        if (!result.isCompleted) result.complete(false);
      },
    );
    final ready = await result.future;
    timeout.cancel();
    return ready;
  }

  Future<RewardedAd?> _ensureRewarded() async {
    if (!_ready || _disposed) return null;
    if (_rewarded != null) return _rewarded;
    if (_rewardedLoad != null) return _rewardedLoad;
    _rewardedLoad = _loadRewarded();
    try {
      return await _rewardedLoad;
    } finally {
      _rewardedLoad = null;
    }
  }

  Future<RewardedAd?> _loadRewarded() async {
    final result = Completer<RewardedAd?>();
    final timeout = Timer(_loadTimeout, () {
      if (!result.isCompleted) result.complete(null);
    });
    try {
      await RewardedAd.load(
        adUnitId: rewardedId,
        request: _request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (_disposed || result.isCompleted) {
              ad.dispose();
              return;
            }
            _rewarded = ad;
            result.complete(ad);
          },
          onAdFailedToLoad: (_) {
            if (!result.isCompleted) result.complete(null);
          },
        ),
      );
    } catch (_) {
      if (!result.isCompleted) result.complete(null);
    }
    final ad = await result.future;
    timeout.cancel();
    return ad;
  }

  Future<InterstitialAd?> _ensureInterstitial() async {
    if (!_ready || _disposed) return null;
    if (_interstitial != null) return _interstitial;
    if (_interstitialLoad != null) return _interstitialLoad;
    _interstitialLoad = _loadInterstitial();
    try {
      return await _interstitialLoad;
    } finally {
      _interstitialLoad = null;
    }
  }

  Future<InterstitialAd?> _loadInterstitial() async {
    final result = Completer<InterstitialAd?>();
    final timeout = Timer(_loadTimeout, () {
      if (!result.isCompleted) result.complete(null);
    });
    try {
      await InterstitialAd.load(
        adUnitId: interstitialId,
        request: _request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (_disposed || result.isCompleted) {
              ad.dispose();
              return;
            }
            _interstitial = ad;
            result.complete(ad);
          },
          onAdFailedToLoad: (_) {
            if (!result.isCompleted) result.complete(null);
          },
        ),
      );
    } catch (_) {
      if (!result.isCompleted) result.complete(null);
    }
    final ad = await result.future;
    timeout.cancel();
    return ad;
  }

  @override
  Future<RewardOutcome> showRewarded(
    BuildContext context, {
    required String rewardLabel,
    required Future<bool> Function() onEarned,
  }) async {
    if (_showing || _disposed) return RewardOutcome.unavailable;
    _showing = true;
    try {
      await prepare();
      final ad = await _ensureRewarded();
      if (ad == null || _disposed || !context.mounted) {
        return RewardOutcome.unavailable;
      }
      _rewarded = null;
      final dismissed = Completer<void>();
      Future<bool>? reward;
      bool failed = false;
      void finish(Ad ad) {
        ad.dispose();
        if (!dismissed.isCompleted) dismissed.complete();
      }

      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdDismissedFullScreenContent: finish,
        onAdFailedToShowFullScreenContent: (ad, _) {
          failed = true;
          finish(ad);
        },
      );
      try {
        await ad.show(
          onUserEarnedReward: (_, _) {
            // Persist at the reward event, even if the widget is later disposed.
            reward ??= onEarned();
          },
        );
        await dismissed.future;
      } catch (_) {
        failed = true;
        finish(ad);
      }
      if (reward != null) {
        return await reward! ? RewardOutcome.earned : RewardOutcome.saveFailed;
      }
      return failed ? RewardOutcome.unavailable : RewardOutcome.cancelled;
    } finally {
      _showing = false;
      _lastFullScreenClosed = _now();
      if (!_disposed) unawaited(_ensureRewarded());
    }
  }

  @override
  Future<void> showInterstitial(BuildContext context) async {
    if (_showing || _disposed || !context.mounted) return;
    // Only show a preloaded ad at the mission transition. Never wait and pop
    // an ad over gameplay later if loading is slow or the device is offline.
    final ad = _interstitial;
    if (ad == null) {
      unawaited(_ensureInterstitial());
      return;
    }
    _interstitial = null;
    _showing = true;
    final dismissed = Completer<void>();
    void finish(Ad ad) {
      ad.dispose();
      if (!dismissed.isCompleted) dismissed.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, _) => finish(ad),
    );
    try {
      await ad.show();
      await dismissed.future;
    } catch (_) {
      finish(ad);
    } finally {
      _showing = false;
      _lastFullScreenClosed = _now();
      if (!_disposed) unawaited(_ensureInterstitial());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _rewarded?.dispose();
    _interstitial?.dispose();
    _appOpen?.dispose();
    _rewarded = null;
    _interstitial = null;
    _appOpen = null;
  }
}
