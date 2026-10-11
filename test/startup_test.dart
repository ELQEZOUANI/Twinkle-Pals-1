import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_pals/services/ads/ad_contract.dart';
import 'package:pocket_pals/services/game_store.dart';
import 'package:pocket_pals/widgets/avatar_art.dart';
import 'package:pocket_pals/widgets/game_startup.dart';
import 'package:pocket_pals/widgets/splash_screen.dart';

class StartupAds extends DisabledAds {
  StartupAds() : super('Offline');
  Future<void>? loading, dismissal;
  int opens = 0;
  bool fail = false;
  @override
  Future<void> prepareAppOpen() async => await loading;
  @override
  Future<void> showAppOpen(BuildContext context) async {
    opens++;
    if (fail) throw StateError('SDK presentation failed');
    await dismissal;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late GameStore store;
  setUp(() async {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    SharedPreferences.setMockInitialValues({});
    store = GameStore(await SharedPreferences.getInstance());
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

  Widget startup(StartupAds ads, {Future<GameStore> Function()? load}) =>
      GameStartup(
        ads: ads,
        loadStore: load ?? () async => store,
        gameBuilder: (_, _) => const MaterialApp(home: Text('Ready to play')),
      );

  testWidgets('Splash waits for storage and stays behind the startup ad', (
    tester,
  ) async {
    final storage = Completer<GameStore>();
    final dismissed = Completer<void>();
    final ads = StartupAds()..dismissal = dismissed.future;
    await tester.pumpWidget(startup(ads, load: () => storage.future));
    expect(find.byType(AvatarArt), findsNWidgets(3));
    expect(find.byType(FlowerLoadingBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(ads.opens, 0);
    storage.complete(store);
    await tester.pump();
    expect(ads.opens, 1);
    expect(find.text('Ready to play'), findsNothing);
    dismissed.complete();
    await tester.pumpAndSettle();
    expect(find.text('Ready to play'), findsOneWidget);
  });

  testWidgets(
    'Slow ad preparation has a three-second limit and no late popup',
    (tester) async {
      final loading = Completer<void>();
      final ads = StartupAds()..loading = loading.future;
      await tester.pumpWidget(startup(ads));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Ready to play'), findsOneWidget);
      expect(ads.opens, 1);
      loading.complete();
      await tester.pumpAndSettle();
      expect(ads.opens, 1);
    },
  );

  testWidgets('Failed presentation still enters the game', (tester) async {
    final ads = StartupAds()..fail = true;
    await tester.pumpWidget(startup(ads));
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    expect(find.text('Ready to play'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Storage failure offers retry without losing the welcome screen',
    (tester) async {
      var attempts = 0;
      final ads = StartupAds();
      await tester.pumpWidget(
        startup(
          ads,
          load: () async {
            if (attempts++ == 0) throw StateError('Storage unavailable');
            return store;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
      expect(ads.opens, 0);
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();
      expect(find.text('Ready to play'), findsOneWidget);
      expect(ads.opens, 1);
    },
  );

  testWidgets('Splash fits a small phone and landscape with motion disabled', (
    tester,
  ) async {
    for (final size in [const Size(320, 568), const Size(568, 320)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, false);
      expect(find.text('Twinkle Pals'), findsOneWidget);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
