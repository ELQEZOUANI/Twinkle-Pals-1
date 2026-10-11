import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_pals/models/adventure.dart';
import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/services/game_store.dart';
import 'package:pocket_pals/widgets/adventure_play.dart';

import 'adventure_helpers.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

  test(
    'Every randomized adventure is solvable, with no duplicate progress',
    () {
      for (var index = 0; index < adventures.length; index++) {
        final variants = <String>{};
        for (var seed = 0; seed < 25; seed++) {
          final round = AdventureRound(index, random: Random(seed));
          expect(round.choose(-1), false);
          expect(round.choose(99), false);
          expect(round.progress, 0);
          switch (round.theme.kind) {
            case AdventureKind.hunt:
              variants.add(round.board.join());
              expect(round.choose(round.board.indexOf(1)), false);
              for (var i = 0; i < round.board.length; i++) {
                if (round.board[i] == 0) {
                  expect(round.choose(i), true);
                  expect(round.choose(i), false);
                }
              }
            case AdventureKind.memory:
              variants.add(round.board.join());
              for (var token = 0; token < 3; token++) {
                final pair = List.generate(
                  6,
                  (i) => i,
                ).where((i) => round.board[i] == token).toList();
                expect(round.choose(pair.first), false);
                expect(round.choose(pair.first), false);
                expect(round.choose(pair.last), true);
                expect(round.choose(pair.last), false);
              }
            case AdventureKind.sequence:
              variants.add(round.order.join());
              for (final token in round.order) {
                final before = round.progress;
                expect(round.choose((token + 1) % 4), false);
                expect(round.progress, before);
                expect(round.choose(token), true);
              }
            case AdventureKind.trail:
              variants.add(round.trail.join());
              expect(round.choose(round.trail.last), false);
              for (var i = 1; i < round.trail.length; i++) {
                final previous = round.trail[i - 1];
                final next = round.trail[i];
                expect(
                  (previous ~/ 4 - next ~/ 4).abs() +
                      (previous % 4 - next % 4).abs(),
                  1,
                );
                expect(round.choose(next), true);
                expect(round.choose(next), false);
              }
          }
          expect(round.complete, true, reason: 'Adventure $index seed $seed');
          expect(round.progress, round.total);
          expect(round.choose(0), false);
        }
        expect(variants.length, greaterThan(1), reason: 'Replay $index varies');
      }
    },
  );

  test('Mismatched ocean cards remain visible until the next choice', () {
    final round = AdventureRound(1, random: Random(7));
    final other = round.board.indexWhere((i) => i != round.board[0]);
    round.choose(0);
    round.choose(other);
    expect(round.progress, 0);
    expect(round.openCards, [0, other]);
    round.choose(0);
    expect(round.openCards, [0]);
    final match = List.generate(
      6,
      (i) => i,
    ).firstWhere((i) => i != 0 && round.board[i] == round.board[0]);
    expect(round.choose(match), true);
    expect(round.progress, 1);
  });

  test(
    'Keepsakes and replay counts persist while old stars and pals survive',
    () async {
      SharedPreferences.setMockInitialValues({
        'pocket_pals_v1': jsonEncode({
          'avatars': [characterPreset(0).toJson()],
          'completed': [0, 2],
          'sound': false,
        }),
      });
      final store = GameStore(await SharedPreferences.getInstance());
      expect(store.stars, 2);
      expect(store.adventureKeepsakes, isEmpty);
      expect(await store.complete(1, keepsake: 'Ocean treasure'), false);
      expect(store.adventureKeepsakes, isEmpty);
      await store.complete(0, keepsake: 'Rainbow picnic');
      await store.complete(0, keepsake: 'Butterfly garden');
      final restored = GameStore(store.prefs);
      expect(restored.stars, 2);
      expect(restored.saved.single.name, 'Luna');
      expect(restored.adventureKeepsakes, {0: 'Butterfly garden'});
      expect(restored.adventurePlays, {0: 2});
    },
  );

  for (var index = 0; index < adventures.length; index++) {
    testWidgets(
      '${adventures[index].gameTitle} can be played and celebrated on a small phone',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        AdventureResult? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showDialog<AdventureResult>(
                      context: context,
                      builder: (_) => AdventurePlay(
                        index: index,
                        avatar: characterPreset(0),
                      ),
                    );
                  },
                  child: const Text('Play'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Play'));
        await tester.pumpAndSettle();
        Future<void> tap(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        if (index != 0) {
          await tap(find.byKey(const ValueKey('begin-adventure')));
        }
        Finder tile(int i) => find.byKey(ValueKey('adventure-tile-$i'));
        switch (adventures[index].kind) {
          case AdventureKind.hunt:
            await completeGardenAdventure(tester);
          case AdventureKind.memory:
            final cards = <String, List<int>>{};
            for (var i = 0; i < 6; i++) {
              await tap(tile(i));
              final texts = tester.widgetList<Text>(
                find.descendant(of: tile(i), matching: find.byType(Text)),
              );
              cards.putIfAbsent(texts.last.data!, () => []).add(i);
            }
            for (final pair in cards.values) {
              expect(pair.length, 2);
              await tap(tile(pair.first));
              await tap(tile(pair.last));
            }
          case AdventureKind.sequence:
            for (var i = 0; i < (index == 3 ? 5 : 4); i++) {
              final target = tester
                  .widget<Text>(
                    find.byKey(const ValueKey('next-adventure-step')),
                  )
                  .data!
                  .substring(6);
              await tap(find.text(target));
            }
          case AdventureKind.trail:
            final stones = <int>{3, 12};
            for (var i = 0; i < 16; i++) {
              if (find
                  .descendant(of: tile(i), matching: find.text('Stone'))
                  .evaluate()
                  .isNotEmpty) {
                stones.add(i);
              }
            }
            var current = 12;
            stones.remove(current);
            while (stones.isNotEmpty) {
              final next = stones.firstWhere(
                (i) =>
                    (i ~/ 4 - current ~/ 4).abs() +
                        (i % 4 - current % 4).abs() ==
                    1,
              );
              await tap(tile(next));
              stones.remove(next);
              current = next;
            }
        }
        if (index != 0) {
          expect(result, isNull); // Play is separate from collecting the stamp.
          await tap(find.byKey(const ValueKey('adventure-finale')));
          await tap(
            find.widgetWithText(ChoiceChip, adventures[index].keepsakes.last),
          );
          await tap(find.byKey(const ValueKey('collect-adventure-stamp')));
          expect(result!.keepsake, adventures[index].keepsakes.last);
        } else {
          expect(result!.keepsake, adventures[index].keepsakes.first);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
