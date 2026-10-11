// Capture the real Flutter iPad layouts for the marketing compositions.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_pals/main.dart';
import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/services/ads/ad_contract.dart';
import 'package:pocket_pals/services/game_store.dart';
import 'package:pocket_pals/widgets/lovely_theme.dart';
import 'package:pocket_pals/widgets/splash_screen.dart';

void main() {
  testWidgets('Capture nine real iPad screens', (tester) async {
    final sdk =
        Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
    await tester.runAsync(() async {
      for (final (family, files) in [
        (
          'Roboto',
          ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'],
        ),
        ('MaterialIcons', ['MaterialIcons-Regular.otf']),
      ]) {
        final loader = FontLoader(family);
        for (final file in files) {
          loader.addFont(
            Future.value(
              ByteData.sublistView(
                File('$sdk/bin/cache/artifacts/material_fonts/$file')
                    .readAsBytesSync(),
              ),
            ),
          );
        }
        await loader.load();
      }
      final emoji = FontLoader('CaptureEmoji');
      emoji.addFont(
        Future.value(
          ByteData.sublistView(
            File('/System/Library/Fonts/Apple Color Emoji.ttc')
                .readAsBytesSync(),
          ),
        ),
      );
      await emoji.load();
    });
    // Widget tests substitute Ahem for styles without an explicit font.
    // Supply the normal text and emoji fonts in this capture harness only.
    final originalTheme = lovelyTheme();
    TextStyle captureStyle(TextStyle? style) =>
        (style ?? const TextStyle()).copyWith(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['CaptureEmoji'],
        );
    final captureTheme = originalTheme.copyWith(
      textTheme: originalTheme.textTheme.apply(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['CaptureEmoji'],
      ),
      primaryTextTheme: originalTheme.primaryTextTheme.apply(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['CaptureEmoji'],
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: originalTheme.filledButtonTheme.style!.copyWith(
          textStyle: WidgetStatePropertyAll(
            captureStyle(
              originalTheme.filledButtonTheme.style!.textStyle?.resolve({}),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: originalTheme.outlinedButtonTheme.style!.copyWith(
          textStyle: WidgetStatePropertyAll(
            captureStyle(originalTheme.textTheme.labelLarge),
          ),
        ),
      ),
      chipTheme: originalTheme.chipTheme.copyWith(
        labelStyle: captureStyle(originalTheme.chipTheme.labelStyle),
      ),
      navigationBarTheme: originalTheme.navigationBarTheme.copyWith(
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => captureStyle(
            originalTheme.navigationBarTheme.labelTextStyle?.resolve(states),
          ),
        ),
      ),
    );
    Widget app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: captureTheme,
      builder: (context, child) => DefaultTextStyle(
        style: captureStyle(const TextStyle(fontSize: 14)),
        child: child!,
      ),
      home: home,
    );
    tester.view.physicalSize = const Size(1032, 1376);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });
    const captureKey = ValueKey('ipad-capture');
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(captureKey),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('output/screenshots-ipad-2064x2752/assets/$name.png')
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      RepaintBoundary(key: captureKey, child: app(const SplashScreen())),
    );
    await capture('01-welcome');
    final ivy = characterPreset(10).select('Tops', 3).select('Bags', 2);
    final zara = characterPreset(8).select('Tops', 1).copyWith(color: 1);
    // This widget-test capture harness lives beside its exported screenshots.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'pocket_pals_v1': jsonEncode({
        'avatars': [ivy.toJson(), zara.toJson(), characterPreset(1).toJson()],
        'completed': [],
        'sound': false,
        'reducedMotion': true,
        'unlockedCharacters': [8, 10],
      }),
    });
    final store = GameStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: app(
          GameShell(store: store, ads: const DisabledAds('Screenshot capture')),
        ),
      ),
    );
    await capture('02-meet-your-pals');
    await tap(find.text('My pals'));
    await tap(find.text('Style').first);
    expect(find.byKey(const ValueKey('ipad-studio')), findsOneWidget);
    await capture('03-dress-up-studio');
    await tap(find.text('Challenges'));
    await capture('04-story-adventures');
    await tap(find.text('Let’s try it').first);
    await capture('05-style-your-adventure');
    for (final entry in challenges[0].requirements.entries) {
      await tap(
        find.widgetWithText(ActionChip, categories[entry.key]![entry.value]),
      );
      await tap(find.byKey(ValueKey('option-${entry.key}-${entry.value}')));
    }
    await tap(find.text('Start mini-game ✨'));
    await tap(find.byKey(const ValueKey('begin-adventure')));
    await capture('06-bloom-hunt');
    for (var i = 0; i < 5; i++) {
      await tap(find.text('Flower').at(i));
    }
    await tap(find.byKey(const ValueKey('adventure-finale')));
    await capture('07-celebrate-friendship');
    await tap(find.byKey(const ValueKey('collect-adventure-stamp')));
    await capture('08-rewards-and-gifts');
    await tap(find.text('Keep styling'));
    await tap(find.text('My pals'));
    await capture('09-my-pals');
    await tester.pumpWidget(const SizedBox());
  });
}
