import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pals/models/adventure.dart';
import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/widgets/adventure_play.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'Story changes the activity; a kind bonus joins the collected result',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      AdventureResult? result;
      var sounds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<AdventureResult>(
                    context: context,
                    builder: (_) => AdventurePlay(
                      index: 0,
                      avatar: characterPreset(0),
                      initialLevel: 2,
                      availableLevel: 0,
                      onGoodChoice: () => sounds++,
                    ),
                  );
                },
                child: const Text('Play'),
              ),
            ),
          ),
        ),
      );
      await tap(tester, find.text('Play'));
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('difficulty-0')))
            .selected,
        true,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('difficulty-1')))
            .onSelected,
        isNull,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('difficulty-2')))
            .onSelected,
        isNull,
      );
      await tap(tester, find.byKey(const ValueKey('story-choice-1')));
      await tap(tester, find.byKey(const ValueKey('begin-adventure')));
      expect(find.text('Strawberry'), findsNWidgets(5));
      expect(find.text('Flower'), findsNothing);
      for (var i = 0; i < 3; i++) {
        await tap(tester, find.text('Strawberry').at(i));
      }
      expect(find.text('3 / 5'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('open-adventure-bonus')),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const ValueKey('open-adventure-bonus')));
      await tap(tester, find.widgetWithText(OutlinedButton, 'Leaf'));
      expect(find.text('3 / 5'), findsOneWidget);
      expect(
        find.text('A sweet idea! Take another look at the little wish.'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(OutlinedButton, 'Flower'));
      expect(find.text('✨ A little extra kindness!'), findsOneWidget);
      expect(result, isNull);
      for (var i = 3; i < 5; i++) {
        await tap(tester, find.text('Strawberry').at(i));
      }
      await tap(tester, find.byKey(const ValueKey('adventure-finale')));
      expect(find.text(adventureOutfitRewards[0].label), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('collect-adventure-stamp')));
      expect(result!.route, 1);
      expect(result!.level, 0);
      expect(result!.bonusCompleted, true);
      expect(sounds, 6);
    },
  );

  testWidgets(
    'An optional surprise can be skipped without blocking the stamp',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AdventurePlay(index: 0, avatar: characterPreset(0))),
      );
      await tap(tester, find.byKey(const ValueKey('begin-adventure')));
      for (var i = 0; i < 3; i++) {
        await tap(tester, find.text('Flower').at(i));
      }
      await tap(tester, find.byKey(const ValueKey('skip-adventure-bonus')));
      expect(find.byKey(const ValueKey('adventure-bonus')), findsNothing);
      for (var i = 3; i < 5; i++) {
        await tap(tester, find.text('Flower').at(i));
      }
      await tap(tester, find.byKey(const ValueKey('adventure-finale')));
      expect(
        find.byKey(const ValueKey('collect-adventure-stamp')),
        findsOneWidget,
      );
      expect(find.text('✨ Friendship sparkle earned'), findsNothing);
    },
  );

  testWidgets(
    'The largest alternate trail keeps every destination accessible on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: AdventurePlay(
            index: 4,
            avatar: characterPreset(0),
            availableLevel: 2,
            initialLevel: 2,
          ),
        ),
      );
      await tap(tester, find.byKey(const ValueKey('story-choice-1')));
      await tap(tester, find.byKey(const ValueKey('begin-adventure')));
      expect(find.byType(GridView), findsOneWidget);
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        6,
      );
      for (var i = 0; i < 36; i++) {
        expect(find.byKey(ValueKey('adventure-tile-$i')), findsOneWidget);
      }
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Bird nest',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('adventure-tile-35')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('adventure-tile-35'))).width,
        greaterThanOrEqualTo(44),
      );
    },
  );

  testWidgets(
    'Correct choices animate a finite cheer and reduced motion keeps the same feedback still',
    (tester) async {
      binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      await tester.pumpWidget(
        MaterialApp(home: AdventurePlay(index: 0, avatar: characterPreset(0))),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('begin-adventure')));
      await tester.tap(find.byKey(const ValueKey('begin-adventure')));
      await tester.pump();
      final scene = find.byKey(const ValueKey('adventure-reaction-scene'));
      final pal = find.byKey(const ValueKey('adventure-pal-reaction'));
      AnimationController controller() =>
          tester.widget<AnimatedBuilder>(scene).animation
              as AnimationController;
      double bounce() => tester.widget<Transform>(pal).transform.storage[13];
      await tester.ensureVisible(find.text('Flower').first);
      await tester.tap(find.text('Flower').first);
      await tester.pump();
      expect(controller().isAnimating, true);
      expect(
        find.text('A new bloom! Our garden is waking up.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(bounce(), lessThan(-1));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(controller().isAnimating, false);
      expect(bounce(), closeTo(0, .001));

      binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pump();
      await tester.ensureVisible(find.text('Flower').at(1));
      await tester.tap(find.text('Flower').at(1));
      await tester.pump();
      expect(controller().isAnimating, false);
      expect(bounce(), 0);
      expect(find.text('2 / 5'), findsOneWidget);
      expect(
        find.text('A new bloom! Our garden is waking up.'),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
