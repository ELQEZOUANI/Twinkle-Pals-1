import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_pals/main.dart';

import 'adventure_helpers.dart';

import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/services/ads/ad_contract.dart';
import 'package:pocket_pals/services/game_store.dart';

class ControlledAds implements GameAds {
  RewardOutcome outcome = RewardOutcome.cancelled;
  int rewards = 0, interstitials = 0;
  bool failInterstitial = false;
  VoidCallback? atInterstitial;
  @override
  String get unavailableMessage => 'No test ad is available.';
  @override
  Future<void> prepare() async {}
  @override
  Future<void> prepareAppOpen() async {}
  @override
  Future<void> showAppOpen(BuildContext context) async {}
  @override
  Future<RewardOutcome> showRewarded(
    BuildContext context, {
    required String rewardLabel,
    required Future<bool> Function() onEarned,
  }) async {
    rewards++;
    if (outcome == RewardOutcome.earned && !await onEarned()) {
      return RewardOutcome.saveFailed;
    }
    return outcome;
  }

  @override
  Future<void> showInterstitial(BuildContext context) async {
    interstitials++;
    atInterstitial?.call();
    if (failInterstitial) throw StateError('Offline');
  }

  @override
  void dispose() {}
}

Future<GameStore> newStore({
  List<Avatar> saved = const [],
  List<int> completed = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'pocket_pals_v1': jsonEncode({
      'avatars': saved.map((a) => a.toJson()).toList(),
      'completed': completed,
      'sound': false,
    }),
  });
  return GameStore(await SharedPreferences.getInstance());
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

  test('First challenge free, five require their own persisted unlock; old stars remain', () async {
    final store = await newStore(completed: [1]);
    expect(store.unlockedChallenges, {0});
    expect(store.stars, 1);
    expect(store.canPlayChallenge(1), false);
    expect(
      await store.complete(1),
      false,
    ); // Old completion cannot bypass access.
    expect(await store.complete(2), false);
    expect(await store.unlockChallenge(-1), false);
    expect(await store.unlockChallenge(6), false);
    for (var i = 1; i < challenges.length; i++) {
      expect(await store.unlockChallenge(i), true);
      expect(await store.unlockChallenge(i), true);
    }
    final restored = GameStore(store.prefs);
    expect(restored.unlockedChallenges, {0, 1, 2, 3, 4, 5});
    expect(restored.stars, 1); // Unlocking is separate from finishing.
    expect(restored.unlockedCharacters, {0, 1});
    expect(await restored.complete(2), true);
    expect(GameStore(store.prefs).stars, 2);
  });

  testWidgets(
    'Free mission opens directly; cancelled/failed ads keep others locked, earned unlock opens and persists',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await newStore();
      final ads = ControlledAds();
      await tester.pumpWidget(PocketPals(store: store, ads: ads));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Challenges'));
      await tester.pumpAndSettle();
      expect(find.text('Watch ad to unlock'), findsNWidgets(5));
      await tapVisible(tester, find.text('Let’s try it'));
      expect(ads.rewards, 0);
      expect(find.text('Garden gathering'), findsWidgets);
      await tester.tap(find.text('Challenges'));
      await tester.pumpAndSettle();
      final beach = find.descendant(
        of: find.byKey(const ValueKey('challenge-1')),
        matching: find.byType(OutlinedButton),
      );
      await tapVisible(tester, beach);
      expect(find.text('Unlock Beach besties'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(ads.rewards, 0);
      await tapVisible(tester, beach);
      await tester.tap(find.byKey(const ValueKey('watch-rewarded-ad')));
      await tester.pumpAndSettle();
      expect(store.canPlayChallenge(1), false);
      ads.outcome = RewardOutcome.unavailable;
      await tapVisible(tester, beach);
      await tester.tap(find.byKey(const ValueKey('watch-rewarded-ad')));
      await tester.pumpAndSettle();
      expect(store.canPlayChallenge(1), false);
      ads.outcome = RewardOutcome.earned;
      await tapVisible(tester, beach);
      await tester.tap(find.byKey(const ValueKey('watch-rewarded-ad')));
      await tester.pumpAndSettle();
      expect(store.canPlayChallenge(1), true);
      expect(GameStore(store.prefs).canPlayChallenge(1), true);
      expect(store.stars, 0);
      expect(ads.interstitials, 0);
      expect(find.text('Beach besties'), findsWidgets);
      await tester.tap(find.text('Challenges'));
      await tester.pumpAndSettle();
      await tapVisible(tester, beach);
      expect(
        ads.rewards,
        3,
      ); // Reopening an earned challenge needs no further reward ad.
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Two free pals, ten locked; earned unlocks persist without changing stars',
    () async {
      final store = await newStore(saved: [characterPreset(8)]);
      expect(store.unlockedCharacters, {0, 1});
      expect(store.saved.single.character, 8); // Old artwork is preserved.
      expect(store.canUseCharacter(8), false);
      expect(await store.save(characterPreset(8)), false);
      expect(await store.unlockCharacter(-1), false);
      expect(await store.unlockCharacter(12), false);
      for (var i = 2; i < names.length; i++) {
        expect(await store.unlockCharacter(i), true);
      }
      final restored = GameStore(store.prefs);
      expect(restored.unlockedCharacters.length, 12);
      expect(restored.stars, 0);
      expect(await restored.save(characterPreset(8)), true);
    },
  );

  testWidgets(
    'Cancel, failed ad and earned reward gate the same home character',
    (tester) async {
      final store = await newStore();
      final ads = ControlledAds();
      await tester.pumpWidget(PocketPals(store: store, ads: ads));
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('character-2'));
      await tapVisible(tester, card);
      expect(find.text('Unlock Cleo'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(ads.rewards, 0);
      await tapVisible(tester, card);
      await tester.tap(find.byKey(const ValueKey('watch-rewarded-ad')));
      await tester.pumpAndSettle();
      expect(store.canUseCharacter(2), false);
      ads.outcome = RewardOutcome.unavailable;
      await tapVisible(tester, card);
      await tester.tap(find.byKey(const ValueKey('watch-rewarded-ad')));
      await tester.pumpAndSettle();
      expect(store.canUseCharacter(2), false);
      ads.outcome = RewardOutcome.earned;
      await tapVisible(tester, card);
      await tester.tap(find.byKey(const ValueKey('watch-rewarded-ad')));
      await tester.pumpAndSettle();
      expect(store.canUseCharacter(2), true);
      expect(GameStore(store.prefs).canUseCharacter(2), true);
      expect(find.text('Save pal'), findsOneWidget);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tapVisible(tester, card);
      expect(ads.rewards, 3); // Returning to an unlocked pal is ad-free.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Studio picker and saved-gallery edits cannot bypass character locks',
    (tester) async {
      final store = await newStore(
        saved: [characterPreset(8).copyWith(name: 'Saved Zara')],
      );
      final ads = ControlledAds();
      await tester.pumpWidget(PocketPals(store: store, ads: ads));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Let’s create'));
      await tester.tap(find.byTooltip('Choose another character'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Cleo').last);
      expect(find.text('Unlock Cleo'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(store.canUseCharacter(2), false);
      await tester.tap(find.text('My pals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Style'));
      await tester.pumpAndSettle();
      expect(find.text('Unlock Zara'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(store.saved.single.name, 'Saved Zara');
      expect(store.canUseCharacter(8), false);
    },
  );

  testWidgets(
    'Mission ads run after saved success, including replays, and failure keeps progress',
    (tester) async {
      tester.view.physicalSize = const Size(1194, 834);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await newStore();
      final ads = ControlledAds()..failInterstitial = true;
      ads.atInterstitial = () => expect(GameStore(store.prefs).stars, 1);
      await tester.pumpWidget(PocketPals(store: store, ads: ads));
      await tester.pumpAndSettle();
      expect(ads.interstitials, 0);
      await tester.tap(find.text('Challenges'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Let’s try it').first);
      await tapVisible(tester, find.text('Follow the 3 clues'));
      expect(ads.interstitials, 0);
      for (final e in challenges[0].requirements.entries) {
        await tapVisible(
          tester,
          find.widgetWithText(ActionChip, categories[e.key]![e.value]),
        );
        await tapVisible(
          tester,
          find.byKey(ValueKey('option-${e.key}-${e.value}')),
        );
      }
      await tapVisible(tester, find.text('Start mini-game ✨'));
      expect(store.stars, 0);
      expect(ads.interstitials, 0);
      await tester.tap(find.byKey(const ValueKey('exit-adventure')));
      await tester.pumpAndSettle();
      expect(store.stars, 0);
      expect(ads.interstitials, 0);
      await tapVisible(tester, find.text('Start mini-game ✨'));
      await completeGardenAdventure(tester);
      expect(store.stars, 1);
      expect(ads.interstitials, 0); // Celebration comes before the break.
      await tester.tap(find.text('Keep styling'));
      await tester.pumpAndSettle();
      expect(ads.interstitials, 1);
      expect(store.stars, 1);
      await tapVisible(tester, find.text('Start mini-game ✨'));
      await completeGardenAdventure(tester);
      expect(store.adventurePlays[0], 2);
      await tester.tap(find.text('More challenges'));
      await tester.pumpAndSettle();
      expect(ads.interstitials, 2);
      expect(store.stars, 1);
      expect(find.text('A tiny adventure in every outfit.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
