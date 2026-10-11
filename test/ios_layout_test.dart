import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_pals/main.dart';
import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/services/ads/ad_contract.dart';
import 'package:pocket_pals/services/game_store.dart';
import 'package:pocket_pals/widgets/avatar_art.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

  for (final (name, size, tablet) in [
    ('small iPhone', const Size(320, 568), false),
    ('large iPhone portrait', const Size(430, 932), false),
    ('large iPhone landscape', const Size(932, 430), false),
    ('compact iPad portrait', const Size(744, 1133), true),
    ('compact iPad landscape', const Size(1133, 744), true),
    ('large iPad portrait', const Size(1024, 1366), true),
    ('large iPad landscape', const Size(1366, 1024), true),
    ('iPad narrow window', const Size(375, 1024), false),
  ]) {
    testWidgets(
      '$name: touch navigation, studio, rotation and collection stay usable',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(
          top: tablet ? 24 : 44,
          bottom: tablet ? 20 : 34,
        );
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        SharedPreferences.setMockInitialValues({
          'pocket_pals_v1': jsonEncode({'sound': false}),
        });
        final store = GameStore(await SharedPreferences.getInstance());
        await store.save(characterPreset(0));
        await tester.pumpWidget(
          PocketPals(store: store, ads: const DisabledAds('Offline')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey(tablet ? 'ipad-layout' : 'iphone-layout')),
          findsOneWidget,
        );
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Avatar studio'), findsNothing);
        final navigation = tester.getRect(
          find.byKey(const ValueKey('touch-navigation')),
        );
        expect(navigation.width, lessThanOrEqualTo(620));
        expect(
          tester.getRect(find.byKey(const ValueKey('open-settings'))).top,
          greaterThanOrEqualTo(tablet ? 24 : 44),
        );

        await tester.tap(find.text('Studio'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey(tablet ? 'ipad-studio' : 'iphone-studio')),
          findsOneWidget,
        );
        final hair = find.byKey(const ValueKey('option-Hair-2'));
        await tester.ensureVisible(hair);
        await tester.tap(hair);
        await tester.pumpAndSettle();
        final character = find.byWidgetPredicate(
          (widget) => widget is AvatarArt && widget.interactive,
        );
        expect(tester.widget<AvatarArt>(character).avatar.item('Hair'), 2);

        tester.view.physicalSize = Size(size.height, size.width);
        tester.view.padding = FakeViewPadding(
          top: tablet ? 24 : 0,
          bottom: tablet ? 20 : 21,
          left: tablet ? 0 : 44,
          right: tablet ? 0 : 44,
        );
        await tester.pumpAndSettle();
        expect(tester.widget<AvatarArt>(character).avatar.item('Hair'), 2);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Challenges'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Let’s try it').first);
        expect(find.text('Garden gathering'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('My pals'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Luna'), findsOneWidget);
        await tester.ensureVisible(find.text('Style'));
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
