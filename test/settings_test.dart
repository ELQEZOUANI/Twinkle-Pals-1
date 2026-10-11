import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_pals/main.dart';
import 'package:pocket_pals/services/game_store.dart';
import 'package:pocket_pals/services/tracking_permission.dart';
import 'package:pocket_pals/widgets/avatar_art.dart';
import 'package:pocket_pals/widgets/settings_page.dart';

class FakeTrackingPermission implements TrackingPermission {
  FakeTrackingPermission(this.current);
  TrackingPermissionStatus current;
  int requests = 0;

  @override
  Future<TrackingPermissionStatus> status() async => current;

  @override
  Future<TrackingPermissionStatus> request() async {
    requests += 1;
    return current = TrackingPermissionStatus.authorized;
  }
}

class FailedSettingsStore extends GameStore {
  FailedSettingsStore(super.prefs);
  @override
  Future<bool> persist() async {
    error = 'Saving failed.';
    return false;
  }
}

Future<GameStore> settingsStore() async {
  SharedPreferences.setMockInitialValues({
    'pocket_pals_v1': jsonEncode({
      'avatars': [],
      'completed': [],
      'sound': true,
    }),
  });
  return GameStore(await SharedPreferences.getInstance());
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

  test(
    'Older saves use normal motion and preference changes persist together',
    () async {
      final store = await settingsStore();
      expect(store.reducedMotion, false);
      expect(await store.setReducedMotion(true), true);
      expect(await store.setSound(false), true);
      final restored = GameStore(store.prefs);
      expect(restored.sound, false);
      expect(restored.reducedMotion, true);
      expect(restored.unlockedCharacters, {0, 1});
      expect(restored.unlockedChallenges, {0});
    },
  );

  test('A failed setting save restores the previous choice', () async {
    final base = await settingsStore();
    final store = FailedSettingsStore(base.prefs);
    expect(await store.setSound(false), false);
    expect(await store.setReducedMotion(true), false);
    expect(store.sound, true);
    expect(store.reducedMotion, false);
    expect(GameStore(base.prefs).sound, true);
    expect(GameStore(base.prefs).reducedMotion, false);
  });

  for (final size in [const Size(320, 568), const Size(1194, 834)]) {
    testWidgets(
      'Settings save controls, open the guide and preserve a draft at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = await settingsStore();
        await tester.pumpWidget(PocketPals(store: store));
        await tester.pumpAndSettle();
        Future<void> tap(Finder target) async {
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        await tap(find.text('Let’s create'));
        await tap(find.byKey(const ValueKey('option-Hair-2')));
        await tap(find.byKey(const ValueKey('open-settings')));
        expect(find.text('Make yourself comfy'), findsOneWidget);
        await tap(find.byKey(const ValueKey('settings-sound')));
        await tap(find.byKey(const ValueKey('settings-motion')));
        expect(store.sound, false);
        expect(store.reducedMotion, true);
        expect(GameStore(store.prefs).reducedMotion, true);
        await tester.ensureVisible(find.text('Bonus sparkles'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tap(find.byKey(const ValueKey('settings-guide')));
        expect(find.text('A little guide to Twinkle Pals'), findsOneWidget);
        await tap(find.text('Let’s play'));
        expect(find.text('Settings'), findsWidgets);
        await tap(find.byKey(const ValueKey('settings-back')));
        expect(find.byTooltip('Enable sounds'), findsOneWidget);
        await tap(find.text('Save pal'));
        await tap(find.widgetWithText(FilledButton, 'Save pal').last);
        expect(store.saved.single.item('Hair'), 2);
      },
    );
  }

  testWidgets(
    'ATT request is protected by the grown-up gate and reports its result',
    (tester) async {
      final store = await settingsStore();
      final tracking = FakeTrackingPermission(
        TrackingPermissionStatus.notDetermined,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            store: store,
            onShowGuide: () {},
            trackingPermission: tracking,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final trackingTile = find.byKey(const ValueKey('settings-tracking'));
      await tester.ensureVisible(trackingTile);
      await tester.tap(trackingTile);
      await tester.pumpAndSettle();

      final question = tester.widget<Text>(
        find.byKey(const ValueKey('parent-question')),
      );
      final factors = RegExp(r'(\d+) × (\d+)').firstMatch(question.data!)!;
      final answer =
          int.parse(factors.group(1)!) * int.parse(factors.group(2)!);
      await tester.enterText(
        find.byKey(const ValueKey('parent-answer')),
        '$answer',
      );
      await tester.tap(find.byKey(const ValueKey('parent-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Ad privacy choice'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('tracking-continue')));
      await tester.pumpAndSettle();

      expect(tracking.requests, 1);
      expect(find.text('Allowed by a parent or guardian.'), findsOneWidget);
      expect(
        find.text(
          'Permission saved. Ads remain child-directed and non-personalized.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'App motion preference applies to characters and keeps device reduction effective',
    (tester) async {
      binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      final store = await settingsStore();
      await store.setReducedMotion(true);
      await tester.pumpWidget(PocketPals(store: store));
      await tester.pumpAndSettle();
      AvatarPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(AvatarArt).first,
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as AvatarPainter;
      expect(painter().motion.enabled, false);
      await store.setReducedMotion(false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(painter().motion.enabled, true);
      binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pumpAndSettle();
      expect(painter().motion.enabled, false);
      expect(store.reducedMotion, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
