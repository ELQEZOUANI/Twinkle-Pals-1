import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Access the SDK's registered ads to deliver native callbacks in this harness.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:pocket_pals/services/ads/ad_contract.dart';
import 'package:pocket_pals/services/ads/ad_mobile.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late MobileGameAds ads;
  late DateTime now;
  late List<MethodCall> calls;
  late List<AppOpenAd> loaded;
  late List<AdWithoutView> shown;
  bool deliverAppOpen = true;
  setUp(() {
    now = DateTime(2026, 10, 9);
    calls = [];
    loaded = [];
    shown = [];
    deliverAppOpen = true;
    ads = MobileGameAds(
      rewardedId: 'reward-test',
      interstitialId: 'interstitial-test',
      appOpenId: 'app-open-test',
      clock: () => now,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      instanceManager.channel,
      (call) async {
        calls.add(call);
        if (call.method == 'MobileAds#initialize') {
          return InitializationStatus({});
        }
        if (call.method.startsWith('load') ||
            call.method == 'showAdWithoutView') {
          final ad = instanceManager.adFor(call.arguments['adId'] as int);
          if (call.method == 'loadAppOpenAd') {
            loaded.add(ad! as AppOpenAd);
            if (deliverAppOpen) {
              scheduleMicrotask(
                () => (ad as AppOpenAd).adLoadCallback.onAdLoaded(ad),
              );
            }
          } else if (call.method == 'loadRewardedAd') {
            scheduleMicrotask(
              () => (ad as RewardedAd).rewardedAdLoadCallback.onAdLoaded(ad),
            );
          } else if (call.method == 'loadInterstitialAd') {
            scheduleMicrotask(
              () => (ad as InterstitialAd).adLoadCallback.onAdLoaded(ad),
            );
          } else if (call.method == 'showAdWithoutView') {
            shown.add(ad! as AdWithoutView);
          }
        }
        return null;
      },
    );
  });
  tearDown(() {
    ads.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      instanceManager.channel,
      null,
    );
  });
  Future<BuildContext> game(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const Text('Game');
          },
        ),
      ),
    );
    await ads.prepareAppOpen();
    await tester.pump();
    return context;
  }

  test('The iOS factory uses only iOS test ad units', () {
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final iosAds = createGameAds() as MobileGameAds;
      expect(iosAds.rewardedId, 'ca-app-pub-3940256099942544/1712485313');
      expect(iosAds.interstitialId, 'ca-app-pub-3940256099942544/4411468910');
      expect(iosAds.appOpenId, 'ca-app-pub-3940256099942544/5575463023');
      iosAds.dispose();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Closing a native rewarded ad without earning grants nothing', (
    tester,
  ) async {
    final context = await game(tester);
    var earned = false;
    final reward = ads.showRewarded(
      context,
      rewardLabel: 'Zara',
      onEarned: () async {
        earned = true;
        return true;
      },
    );
    await tester.pump();
    final ad = shown.single as RewardedAd;
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    expect(await reward, RewardOutcome.cancelled);
    expect(earned, false);
    await tester.pump();
  });

  testWidgets(
    'A native earned-reward callback grants the reward exactly once',
    (tester) async {
      final context = await game(tester);
      var saves = 0;
      final reward = ads.showRewarded(
        context,
        rewardLabel: 'Zara',
        onEarned: () async {
          saves++;
          return true;
        },
      );
      await tester.pump();
      final ad = shown.single as RewardedAd;
      ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'unlock'));
      ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'unlock'));
      ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
      expect(await reward, RewardOutcome.earned);
      expect(saves, 1);
      await tester.pump();
    },
  );

  testWidgets(
    'Native app-open shares the fullscreen lock and reloads with a cooldown',
    (tester) async {
      final context = await game(tester);
      final presentation = ads.showAppOpen(context);
      await tester.pump();
      expect(shown, [loaded.first]);
      await ads.showAppOpen(context);
      await ads.showInterstitial(context);
      expect(
        await ads.showRewarded(
          context,
          rewardLabel: 'Zara',
          onEarned: () async => true,
        ),
        RewardOutcome.unavailable,
      );
      expect(shown.length, 1);
      loaded.first.fullScreenContentCallback!.onAdDismissedFullScreenContent!(
        loaded.first,
      );
      await presentation;
      await tester.pump();
      expect(loaded.length, 2);
      await ads.showAppOpen(context);
      expect(shown.length, 1);
      now = now.add(const Duration(seconds: 31));
      final second = ads.showAppOpen(context);
      await tester.pump();
      expect(shown.length, 2);
      loaded[1].fullScreenContentCallback!.onAdDismissedFullScreenContent!(
        loaded[1],
      );
      await second;
      await tester.pump();
      final config = calls.firstWhere(
        (c) => c.method == 'MobileAds#updateRequestConfiguration',
      );
      expect(
        config.arguments['ageRestrictedTreatment'],
        AgeRestrictedTreatment.child.index,
      );
      expect(config.arguments['maxAdContentRating'], MaxAdContentRating.g);
      final request =
          calls
                  .firstWhere((c) => c.method == 'loadAppOpenAd')
                  .arguments['request']
              as AdRequest;
      expect(request.nonPersonalizedAds, true);
    },
  );

  testWidgets(
    'Expired app-open ad is discarded; a replacement never pops up late',
    (tester) async {
      final context = await game(tester);
      now = now.add(const Duration(hours: 4));
      await ads.showAppOpen(context);
      await tester.pump();
      expect(shown, isEmpty);
      expect(loaded.length, 2);
      expect(calls.where((c) => c.method == 'disposeAd'), isNotEmpty);
      final presentation = ads.showAppOpen(context);
      await tester.pump();
      expect(shown, [loaded[1]]);
      loaded[1].fullScreenContentCallback!.onAdFailedToShowFullScreenContent!(
        loaded[1],
        AdError(0, 'test', 'Presentation failed'),
      );
      await presentation;
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'An unready ad is skipped and a late callback after disposal is cleaned up',
    (tester) async {
      deliverAppOpen = false;
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const Text('Game');
            },
          ),
        ),
      );
      await ads.prepare();
      await tester.pump();
      await ads.showAppOpen(context);
      expect(shown, isEmpty);
      ads.dispose();
      loaded.single.adLoadCallback.onAdLoaded(loaded.single);
      await tester.pump(const Duration(seconds: 13));
      expect(shown, isEmpty);
      expect(calls.where((c) => c.method == 'disposeAd'), isNotEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
