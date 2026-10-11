import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_pals/main.dart';

import 'adventure_helpers.dart';

import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/models/adventure.dart';
import 'package:pocket_pals/services/game_store.dart';
import 'package:pocket_pals/services/avatar_export.dart';
import 'package:pocket_pals/widgets/avatar_art.dart';

Future<GameStore> freshStore() async {
  SharedPreferences.setMockInitialValues({
    'pocket_pals_v1': jsonEncode({
      'avatars': [],
      'completed': [],
      'sound': false,
    }),
  });
  return GameStore(await SharedPreferences.getInstance());
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    // Flow tests use the same reduced-motion mode available on users' devices.
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

  testWidgets(
    'Characters idle, react to outfits, wave, and stop for reduced motion',
    (tester) async {
      binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      Widget character(Avatar avatar, {bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Center(
            child: SizedBox(
              width: 240,
              height: 320,
              child: AvatarArt(avatar: avatar, interactive: true),
            ),
          ),
        ),
      );
      AvatarPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(AvatarArt),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as AvatarPainter;
      final avatar = characterPreset(0);
      await tester.pumpWidget(character(avatar));
      await tester.pump(const Duration(milliseconds: 800));
      expect(painter().motion.enabled, isTrue);
      expect(painter().motion.time, greaterThan(0));
      await tester.tap(find.byType(AvatarArt));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(painter().motion.wave, isTrue);
      expect(painter().motion.energy, greaterThan(0));
      await tester.pumpWidget(character(avatar.select('Tops', 2)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(painter().motion.wave, isFalse);
      expect(painter().motion.jump, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(painter().motion.enabled, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(painter().motion.enabled, isTrue);
      await tester.pumpWidget(character(avatar, reduced: true));
      await tester.pumpAndSettle();
      expect(painter().motion.enabled, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(
        const AvatarMotion(time: 4.52, enabled: true).blink,
        closeTo(1, .001),
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('Picture export produces a full-resolution PNG', () async {
    final bytes = await renderAvatarPng(characterPreset(2));
    expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
    final header = ByteData.sublistView(bytes);
    expect(header.getUint32(16), 900);
    expect(header.getUint32(20), 1200);
  });
  test('Every item in every category creates distinct artwork', () async {
    final base = characterPreset(0);
    for (final entry in categories.entries) {
      final seen = <String, String>{};
      for (int i = 0; i < entry.value.length; i++) {
        final image = base64Encode(
          await renderAvatarPng(base.select(entry.key, i)),
        );
        expect(
          seen.containsKey(image),
          isFalse,
          reason:
              '${entry.key}: ${entry.value[i]} must look different from ${seen[image]}',
        );
        seen[image] = entry.value[i];
      }
    }
  });
  test(
    'Old avatars keep their eye color when loaded with new face controls',
    () {
      final old = characterPreset(4).toJson()..remove('eyeColor');
      final restored = Avatar.fromJson(old);
      expect(restored.eyeColor, restored.color);
      expect(restored.item('Eyes'), 0);
      expect(restored.item('Mouth'), 0);
      final updated = restored.copyWith(color: 1);
      expect(updated.eyeColor, restored.eyeColor);
    },
  );
  test('Twelve presets survive saving with all customization selections', () {
    expect(names.toSet().length, 12);
    for (int i = 0; i < 12; i++) {
      final avatar = randomize(characterPreset(i), 6, Random(i));
      expect(Avatar.fromJson(avatar.toJson()).toJson(), avatar.toJson());
    }
  });
  test('Locked accessories cannot appear in random outfits before unlock', () {
    for (int stars = 0; stars <= 6; stars++) {
      for (int seed = 0; seed < 100; seed++) {
        final avatar = randomize(characterPreset(0), stars, Random(seed));
        for (final e in avatar.items.entries) {
          expect(isLocked(e.key, e.value, stars), isFalse);
        }
      }
    }
  });
  test('All challenges are achievable without locked items', () {
    for (final challenge in challenges) {
      var avatar = characterPreset(0);
      expect(challenge.matches(avatar), isFalse);
      for (final e in challenge.requirements.entries) {
        expect(isLocked(e.key, e.value, 0), isFalse);
        avatar = avatar.select(e.key, e.value);
      }
      expect(challenge.matches(avatar), isTrue);
    }
  });
  test(
    'Stars are awarded once and gallery edits persist across restarts',
    () async {
      final store = await freshStore();
      await store.save(characterPreset(0));
      await store.save(characterPreset(1));
      await store.save(characterPreset(0).copyWith(name: 'My Luna'), index: 0);
      await store.complete(0);
      await store.complete(0);
      await store.unlockChallenge(1);
      await store.complete(1);
      final restored = GameStore(store.prefs);
      expect(restored.stars, 2);
      expect(restored.saved.length, 2);
      expect(restored.saved.first.name, 'My Luna');
      await restored.delete(0);
      expect(GameStore(store.prefs).saved.single.name, 'Milo');
    },
  );
  testWidgets('Create, customize, save, and reopen a pal on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await freshStore();
    await tester.pumpWidget(PocketPals(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let’s create'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('option-Hair-2')));
    await tester.tap(find.byKey(const ValueKey('option-Hair-2')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save pal'));
    await tester.tap(find.text('Save pal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Puff friend');
    await tester.tap(find.widgetWithText(FilledButton, 'Save pal').last);
    await tester.pumpAndSettle();
    expect(store.saved.single.name, 'Puff friend');
    expect(store.saved.single.item('Hair'), 2);
    await tester.tap(find.text('My pals'));
    await tester.pumpAndSettle();
    expect(find.text('Puff friend'), findsOneWidget);
    await tester.tap(find.text('Style'));
    await tester.pumpAndSettle();
    expect(find.text('Puff friend'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Challenge clues guide selection and award a persistent star', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await freshStore();
    await tester.pumpWidget(PocketPals(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Challenges'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Let’s try it').first);
    await tester.tap(find.text('Let’s try it').first);
    await tester.pumpAndSettle();
    for (final e in challenges[0].requirements.entries) {
      await tester.ensureVisible(
        find.widgetWithText(ActionChip, categories[e.key]![e.value]),
      );
      await tester.tap(
        find.widgetWithText(ActionChip, categories[e.key]![e.value]),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(ValueKey('option-${e.key}-${e.value}')),
      );
      await tester.tap(find.byKey(ValueKey('option-${e.key}-${e.value}')));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Start mini-game ✨'));
    await tester.tap(find.text('Start mini-game ✨'));
    await tester.pumpAndSettle();
    expect(store.stars, 0);
    await completeGardenAdventure(tester);
    expect(store.stars, 1);
    expect(find.text('You did it! ✨'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Small phone layouts fit all screens and show reward locks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PocketPals(store: await freshStore()));
    await tester.pumpAndSettle();
    for (final title in ['Studio', 'Challenges', 'My pals', 'Home']) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: title);
    }
  });

  testWidgets('Phone challenge content scrolls with a wheel and mouse drag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(368, 774);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PocketPals(store: await freshStore()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Challenges'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Let’s try it').first);
    await tester.tap(find.text('Let’s try it').first);
    await tester.pumpAndSettle();
    final studio = find.byKey(const ValueKey('studio-scroll'));
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: studio, matching: find.byType(Scrollable)).first,
    );
    expect(scroll.position.maxScrollExtent, greaterThan(500));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        kind: PointerDeviceKind.mouse,
        position: const Offset(180, 300),
        scrollDelta: const Offset(0, 350),
      ),
    );
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
    final beforeDrag = scroll.position.pixels;
    await tester.dragFrom(
      const Offset(180, 620),
      const Offset(0, -200),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(beforeDrag));
    for (final key in ['Scene', 'Pose']) {
      final toggle = find.byKey(const ValueKey('categories-toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ValueKey('category-$key')));
      await tester.tap(find.byKey(ValueKey('category-$key')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ValueKey('option-$key-2')));
      await tester.tap(find.byKey(ValueKey('option-$key-2')));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Skin tone'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Skin tone')).bottom, lessThan(703));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Every customization category can be selected and saved on a phone',
    (tester) async {
      tester.view.physicalSize = const Size(368, 774);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await freshStore();
      for (int i = 0; i < challenges.length; i++) {
        await store.unlockChallenge(i);
        await store.complete(i, keepsake: adventures[i].keepsakes.first);
      }
      await tester.pumpWidget(PocketPals(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Studio'));
      await tester.pumpAndSettle();
      final expected = <String, int>{};
      for (final entry in categories.entries) {
        final toggle = find.byKey(const ValueKey('categories-toggle'));
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        final tab = find.byKey(ValueKey('category-${entry.key}'));
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('category-${entry.key}')), findsNothing);
        final i = entry.value.length - 1;
        final option = find.byKey(ValueKey('option-${entry.key}-$i'));
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pumpAndSettle();
        expected[entry.key] = i;
        if (entry.key == 'Face') {
          expected['Mouth'] = 0;
          if (expected['Eyes'] == 3) expected['Eyes'] = 0;
        }
        if (entry.key == 'Eyes' && expected['Face'] == 3) expected['Face'] = 0;
        if (entry.key == 'Tops' || entry.key == 'Bottoms') {
          expected['Dresses'] = 0;
        }
      }
      await tester.ensureVisible(find.text('Save pal'));
      await tester.tap(find.text('Save pal'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save pal').last);
      await tester.pumpAndSettle();
      for (final e in expected.entries) {
        expect(store.saved.single.item(e.key), e.value, reason: e.key);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
