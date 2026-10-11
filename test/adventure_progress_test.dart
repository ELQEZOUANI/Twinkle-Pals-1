import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pals/models/adventure.dart';
import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/services/game_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

class ToggleSaveStore extends GameStore {
  bool failSaves = false;
  ToggleSaveStore(super.prefs);

  @override
  Future<bool> persist() => failSaves ? Future.value(false) : super.persist();
}

class FailingPreferencePlatform extends InMemorySharedPreferencesStore {
  bool failWrites = false;
  bool throwOnWrite = false;
  bool failReads = false;
  int reads = 0;
  FailingPreferencePlatform() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (throwOnWrite) throw StateError('Storage unavailable');
    return failWrites ? false : super.setValue(valueType, key, value);
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) {
    reads++;
    if (failReads) throw StateError('Storage unavailable');
    return super.getAllWithParameters(parameters);
  }
}

void solve(AdventureRound round) {
  switch (round.theme.kind) {
    case AdventureKind.hunt:
      for (var i = 0; i < round.board.length; i++) {
        if (round.board[i] == round.huntTarget) expect(round.choose(i), true);
      }
    case AdventureKind.memory:
      for (var token = 0; token < round.total; token++) {
        final pair = [
          for (var i = 0; i < round.board.length; i++)
            if (round.board[i] == token) i,
        ];
        expect(pair.length, 2);
        expect(round.choose(pair.first), false);
        expect(round.choose(pair.last), true);
      }
    case AdventureKind.sequence:
      for (final next in round.order) {
        final progress = round.progress;
        expect(round.choose((next + 1) % round.tokens.length), false);
        expect(round.progress, progress);
        expect(round.choose(next), true);
      }
    case AdventureKind.trail:
      expect(round.choose(round.trail.last), false);
      for (var i = 1; i < round.trail.length; i++) {
        final previous = round.trail[i - 1];
        final next = round.trail[i];
        expect(
          (previous ~/ round.columns - next ~/ round.columns).abs() +
              (previous % round.columns - next % round.columns).abs(),
          1,
        );
        expect(round.choose(next), true);
        expect(round.choose(next), false);
      }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Both story routes have different goals and every level is solvable',
    () {
      for (var index = 0; index < adventures.length; index++) {
        final choices = adventures[index].choices;
        expect(choices.length, 2);
        expect(choices[0].objective, isNot(choices[1].objective));
        expect(
          choices[0].tokens.first.label,
          isNot(choices[1].tokens.first.label),
        );
        for (var route = 0; route < 2; route++) {
          var lastTotal = 0;
          for (var level = 0; level < 3; level++) {
            for (var seed = 0; seed < 8; seed++) {
              final round = AdventureRound(
                index,
                level: level,
                route: route,
                random: Random(seed),
              );
              expect(
                round.choice.friendName,
                names[round.choice.friendCharacterIndex],
              );
              expect(round.total, greaterThan(lastTotal));
              expect(round.choose(-1), false);
              expect(round.choose(1000), false);
              expect(round.bonusAvailable, false);
              solve(round);
              expect(
                round.complete,
                true,
                reason: '$index/$route/$level/$seed',
              );
              expect(round.bonusAvailable, true);
              // An optional favor can be skipped without preventing completion.
              expect(round.bonus.completed, false);
              expect(round.choose(0), false);
            }
            lastTotal = AdventureRound(index, level: level, route: route).total;
          }
        }
      }
    },
  );

  test(
    'Optional surprises reward a kind choice without losing main progress',
    () {
      for (var index = 0; index < adventures.length; index++) {
        final round = AdventureRound(index, random: Random(20));
        solve(round);
        final progress = round.progress;
        final bonus = round.bonus;
        expect(bonus.choose(-1), false);
        expect(
          bonus.choose((bonus.correctIndex + 1) % bonus.choices.length),
          false,
        );
        expect(bonus.completed, false);
        expect(round.progress, progress);
        expect(bonus.choose(bonus.correctIndex), true);
        expect(bonus.completed, true);
        expect(bonus.choose(bonus.correctIndex), false);
        expect(round.progress, progress);
      }
    },
  );

  test(
    'Adventure difficulty, outfits, hearts, routes and bonus gifts persist',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = GameStore(await SharedPreferences.getInstance());
      expect(store.canPlayAdventureLevel(0, 0), true);
      expect(store.canPlayAdventureLevel(0, 1), false);
      expect(
        await store.complete(0, keepsake: 'Rainbow picnic', level: 1),
        false,
      );
      expect(await store.complete(1, keepsake: 'Ocean treasure'), false);
      expect(store.adventureRewards, isEmpty);
      for (var level = 0; level < 3; level++) {
        for (var route = 0; route < 2; route++) {
          expect(
            await store.complete(
              0,
              keepsake: 'Rainbow picnic',
              level: level,
              route: route,
              bonusCompleted: true,
            ),
            true,
          );
        }
      }
      // Replays retain the latest stamp and count plays, but finite rewards do
      // not multiply when the same route and level are played again.
      await store.complete(
        0,
        keepsake: 'Butterfly garden',
        level: 0,
        route: 1,
        bonusCompleted: true,
      );
      final restored = GameStore(store.prefs);
      expect(restored.stars, 1);
      expect(restored.adventureLevels, {0: 3});
      expect(restored.adventureRewards, {0});
      expect(restored.adventureRoutes, {0: 1});
      expect(restored.friendHearts, {0: 6});
      expect(restored.bonusStars, 6);
      expect(restored.adventurePlays, {0: 7});
      expect(restored.adventureKeepsakes, {0: 'Butterfly garden'});
      expect(restored.canPlayAdventureLevel(0, 2), true);
      expect(restored.canPlayAdventureLevel(0, 3), false);
      expect(restored.canPlayAdventureLevel(1, 0), false);
      expect(restored.canUseCharacter(4), false);
    },
  );

  test(
    'Earlier mini-game stamps migrate without changing stars or ad unlocks',
    () async {
      SharedPreferences.setMockInitialValues({
        'pocket_pals_v1': jsonEncode({
          'avatars': [characterPreset(0).toJson()],
          'completed': [0, 2],
          'unlockedCharacters': [0, 1, 7],
          'unlockedChallenges': [0, 2],
          'adventureKeepsakes': {'2': 'Pajama cinema'},
          'adventurePlays': {'2': 3},
        }),
      });
      final store = GameStore(await SharedPreferences.getInstance());
      expect(store.stars, 2);
      expect(store.saved.single.name, 'Luna');
      expect(store.unlockedCharacters, {0, 1, 7});
      expect(store.unlockedChallenges, {0, 2});
      expect(store.adventureLevels, {2: 1});
      expect(store.adventureRewards, {2});
      expect(store.friendHearts, {2: 1});
      expect(store.canPlayAdventureLevel(2, 1), true);
      expect(store.canPlayAdventureLevel(2, 2), false);
      expect(store.adventurePlays, {2: 3});
      expect(store.bonusStars, 0);
    },
  );

  test('Failed completion saves roll back every adventure reward and progress field', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ToggleSaveStore(await SharedPreferences.getInstance());
    store.failSaves = true;
    expect(
      await store.complete(0, keepsake: 'Rainbow picnic', bonusCompleted: true),
      false,
    );
    expect(store.stars, 0);
    expect(store.adventureLevels, isEmpty);
    expect(store.adventureRewards, isEmpty);
    expect(store.adventureRoutes, isEmpty);
    expect(store.friendHearts, isEmpty);
    expect(store.adventureMemories, isEmpty);
    expect(store.adventureBonusStars, isEmpty);
    expect(store.adventureKeepsakes, isEmpty);
    expect(store.adventurePlays, isEmpty);

    store.failSaves = false;
    await store.complete(0, keepsake: 'Rainbow picnic');
    store.failSaves = true;
    expect(
      await store.complete(
        0,
        keepsake: 'Flower friendship',
        level: 1,
        route: 1,
        bonusCompleted: true,
      ),
      false,
    );
    expect(store.stars, 1);
    expect(store.adventureLevels, {0: 1});
    expect(store.adventureRewards, {0});
    expect(store.adventureRoutes, {0: 0});
    expect(store.friendHearts, {0: 1});
    expect(store.adventureMemories, {
      0: {0},
    });
    expect(store.adventureBonusStars, isEmpty);
    expect(store.adventureKeepsakes, {0: 'Rainbow picnic'});
    expect(store.adventurePlays, {0: 1});
    expect(GameStore(store.prefs).adventureLevels, {0: 1});
  });

  test(
    'Failed platform writes reload the optimistic preferences cache',
    () async {
      SharedPreferences.resetStatic();
      final previousPlatform = SharedPreferencesStorePlatform.instance;
      final platform = FailingPreferencePlatform();
      SharedPreferencesStorePlatform.instance = platform;
      addTearDown(() {
        SharedPreferencesStorePlatform.instance = previousPlatform;
        SharedPreferences.resetStatic();
      });
      final prefs = await SharedPreferences.getInstance();
      final store = GameStore(prefs);
      await store.save(characterPreset(0));
      final before = prefs.getString('pocket_pals_v1');
      final reads = platform.reads;
      platform.failWrites = true;
      expect(
        await store.complete(
          0,
          keepsake: 'Rainbow picnic',
          bonusCompleted: true,
        ),
        false,
      );
      expect(platform.reads, greaterThan(reads));
      expect(prefs.getString('pocket_pals_v1'), before);
      expect(GameStore(prefs).adventureRewards, isEmpty);
      expect(GameStore(prefs).stars, 0);
      expect(GameStore(prefs).saved.single.name, 'Luna');

      platform.failWrites = false;
      await store.complete(0, keepsake: 'Rainbow picnic');
      final earned = prefs.getString('pocket_pals_v1');
      platform.throwOnWrite = true;
      expect(
        await store.complete(0, keepsake: 'Flower friendship', level: 1),
        false,
      );
      expect(prefs.getString('pocket_pals_v1'), earned);
      expect(GameStore(prefs).adventureLevels, {0: 1});
      expect(store.error, contains('Saving failed'));

      // Even a failing reload must not throw or retain new live progress.
      platform.failReads = true;
      expect(
        await store.complete(0, keepsake: 'Flower friendship', level: 1),
        false,
      );
      expect(store.adventureLevels, {0: 1});
      expect(store.adventurePlays, {0: 1});
    },
  );

  test(
    'New outfit gifts cannot bypass their earned reward at save time',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = GameStore(await SharedPreferences.getInstance());
      for (var i = 0; i < adventureOutfitRewards.length; i++) {
        final reward = adventureOutfitRewards[i];
        final pal = characterPreset(0).select(reward.category, reward.item);
        final before = store.saved.length;
        expect(await store.save(pal), false);
        expect(store.saved.length, before);
        expect(store.error, contains('earn'));
        await store.unlockChallenge(i);
        await store.complete(i, keepsake: adventures[i].keepsakes.first);
        expect(await store.save(pal), true);
        expect(store.saved.last.item(reward.category), reward.item);
      }
      expect(
        GameStore(store.prefs).saved.length,
        adventureOutfitRewards.length,
      );
    },
  );

  test(
    'Existing saved artwork is retained without granting unearned copies',
    () async {
      final existing = characterPreset(0).select('Bags', 5);
      SharedPreferences.setMockInitialValues({
        'pocket_pals_v1': jsonEncode({
          'avatars': [existing.toJson()],
          'completed': [],
        }),
      });
      final store = GameStore(await SharedPreferences.getInstance());
      expect(store.saved.single.item('Bags'), 5);
      expect(store.adventureRewards, isEmpty);
      expect(
        await store.save(existing.copyWith(name: 'Old favorite'), index: 0),
        true,
      );
      expect(store.saved.single.item('Bags'), 5);
      expect(await store.save(existing), false);
      expect(await store.save(existing.select('Bags', 0), index: 0), true);
      expect(await store.save(existing, index: 0), false);
      expect(GameStore(store.prefs).saved.single.item('Bags'), 0);
    },
  );
}
