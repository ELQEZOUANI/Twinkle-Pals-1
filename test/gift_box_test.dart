import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_pals/main.dart';
import 'package:pocket_pals/models/adventure.dart';
import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/services/game_store.dart';

void main() {
  testWidgets(
    'An earned gift can be worn and saved from the gift box on a phone',
    (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'pocket_pals_v1': jsonEncode({
          'avatars': [],
          'completed': [],
          'sound': false,
        }),
      });
      final store = GameStore(await SharedPreferences.getInstance());
      await store.complete(0, keepsake: adventures[0].keepsakes.first);
      await tester.pumpWidget(PocketPals(store: store));
      await tester.pumpAndSettle();
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tap(find.text('Challenges'));
      await tap(find.text('Your lovely gift box'));
      expect(find.text('1/6 outfits earned by playing'), findsOneWidget);
      await tap(find.byKey(const ValueKey('wear-gift-0')));
      await tap(find.text('Save pal'));
      await tap(find.widgetWithText(FilledButton, 'Save pal').last);
      final gift = adventureOutfitRewards[0];
      expect(store.saved.single.item(gift.category), gift.item);
      expect(
        GameStore(store.prefs).saved.single.item(gift.category),
        gift.item,
      );
      expect(store.adventureRewards, {0});
      expect(store.stars, 1);
    },
  );
}
