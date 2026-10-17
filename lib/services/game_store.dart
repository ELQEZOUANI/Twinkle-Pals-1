import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar.dart';

class GameStore extends ChangeNotifier {
  final SharedPreferences prefs;
  List<Avatar> saved = [];
  Set<int> completed = {};
  Set<int> unlockedCharacters = {0, 1};
  Set<int> unlockedChallenges = {0};
  Map<int, String> adventureKeepsakes = {};
  Map<int, int> adventurePlays = {};

  /// Number of levels completed in each adventure: 0..3.
  Map<int, int> adventureLevels = {};
  Set<int> adventureRewards = {};
  Map<int, int> adventureRoutes = {};
  Map<int, int> friendHearts = {};

  /// Route × level memories prevent replaying one task from farming hearts.
  Map<int, Set<int>> adventureMemories = {};

  /// Each route × level can award one optional bonus sparkle, up to 36 total.
  Set<int> adventureBonusStars = {};
  bool sound = true;
  bool reducedMotion = false;
  String? error;
  Future<void> _pending = Future.value();
  GameStore(this.prefs) {
    try {
      final raw = prefs.getString('pocket_pals_v1');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        saved = (data['avatars'] as List)
            .map((e) => Avatar.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        completed = (data['completed'] as List)
            .cast<int>()
            .where((i) => i >= 0 && i < challenges.length)
            .toSet();
        sound = data['sound'] as bool? ?? true;
        reducedMotion = data['reducedMotion'] as bool? ?? false;
        unlockedCharacters.addAll(
          ((data['unlockedCharacters'] as List?) ?? const [])
              .whereType<int>()
              .where((i) => i >= 2 && i < names.length),
        );
        unlockedChallenges.addAll(
          ((data['unlockedChallenges'] as List?) ?? const [])
              .whereType<int>()
              .where((i) => i >= 1 && i < challenges.length),
        );
        for (final entry
            in ((data['adventureKeepsakes'] as Map?) ?? {}).entries) {
          final index = int.tryParse(entry.key.toString());
          if (index != null &&
              index >= 0 &&
              index < challenges.length &&
              entry.value is String) {
            adventureKeepsakes[index] = (entry.value as String).substring(
              0,
              (entry.value as String).length.clamp(0, 80),
            );
          }
        }
        for (final entry in ((data['adventurePlays'] as Map?) ?? {}).entries) {
          final index = int.tryParse(entry.key.toString());
          if (index != null &&
              index >= 0 &&
              index < challenges.length &&
              entry.value is int &&
              (entry.value as int) > 0) {
            adventurePlays[index] = entry.value as int;
          }
        }
        void readCounts(String key, Map<int, int> target, int maximum) {
          for (final entry in ((data[key] as Map?) ?? {}).entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null &&
                index >= 0 &&
                index < challenges.length &&
                entry.value is int &&
                entry.value >= 0 &&
                entry.value <= maximum) {
              target[index] = entry.value as int;
            }
          }
        }

        readCounts('adventureLevels', adventureLevels, 3);
        readCounts('adventureRoutes', adventureRoutes, 1);
        adventureRewards.addAll(
          ((data['adventureRewards'] as List?) ?? const [])
              .whereType<int>()
              .where((i) => i >= 0 && i < challenges.length),
        );
        for (final entry
            in ((data['adventureMemories'] as Map?) ?? {}).entries) {
          final index = int.tryParse(entry.key.toString());
          if (index != null &&
              index >= 0 &&
              index < challenges.length &&
              entry.value is List) {
            adventureMemories[index] = (entry.value as List)
                .whereType<int>()
                .where((i) => i >= 0 && i < 6)
                .toSet();
          }
        }
        adventureBonusStars.addAll(
          ((data['adventureBonusStars'] as List?) ?? const [])
              .whereType<int>()
              .where((i) => i >= 0 && i < challenges.length * 6),
        );
        // Existing mini-game stamps represent a finished Easy adventure. Keep
        // those achievements when upgrading, including their new outfit gift.
        for (final index in adventureKeepsakes.keys) {
          adventureLevels.putIfAbsent(index, () => 1);
          adventureRewards.add(index);
          adventureMemories.putIfAbsent(index, () => {0});
          adventureRoutes.putIfAbsent(index, () => 0);
        }
        friendHearts = {
          for (final entry in adventureMemories.entries)
            entry.key: entry.value.length,
        };
      }
    } catch (_) {
      error =
          'Your saved data could not be read. You can still create new pals.';
    }
  }
  int get stars => completed.length;
  int get bonusStars => adventureBonusStars.length;
  bool canPlayAdventureLevel(int index, int level) =>
      canPlayChallenge(index) &&
      level >= 0 &&
      level <= 2 &&
      level <= (adventureLevels[index] ?? 0);
  bool canUseCharacter(int index) => unlockedCharacters.contains(index);
  bool canPlayChallenge(int index) => unlockedChallenges.contains(index);

  Future<bool> unlockChallenge(int index) async {
    if (index < 0 || index >= challenges.length) return false;
    if (canPlayChallenge(index)) return true;
    unlockedChallenges.add(index);
    final ok = await persist();
    if (!ok) unlockedChallenges.remove(index);
    notifyListeners();
    return ok;
  }

  /// Called only by an earned-reward callback, never by ad dismissal.
  Future<bool> unlockCharacter(int index) async {
    if (index < 0 || index >= names.length) return false;
    if (canUseCharacter(index)) return true;
    unlockedCharacters.add(index);
    final ok = await persist();
    if (!ok) unlockedCharacters.remove(index);
    notifyListeners();
    return ok;
  }

  Future<bool> persist() {
    final snapshot = jsonEncode({
      'avatars': saved.map((a) => a.toJson()).toList(),
      'completed': completed.toList(),
      'sound': sound,
      'reducedMotion': reducedMotion,
      'unlockedCharacters': unlockedCharacters.toList(),
      'unlockedChallenges': unlockedChallenges.toList(),
      'adventureKeepsakes': {
        for (final entry in adventureKeepsakes.entries)
          '${entry.key}': entry.value,
      },
      'adventureLevels': {
        for (final entry in adventureLevels.entries)
          '${entry.key}': entry.value,
      },
      'adventureRewards': adventureRewards.toList(),
      'adventureRoutes': {
        for (final entry in adventureRoutes.entries)
          '${entry.key}': entry.value,
      },
      'friendHearts': {
        for (final entry in friendHearts.entries) '${entry.key}': entry.value,
      },
      'adventureMemories': {
        for (final entry in adventureMemories.entries)
          '${entry.key}': entry.value.toList(),
      },
      'adventureBonusStars': adventureBonusStars.toList(),
      'adventurePlays': {
        for (final entry in adventurePlays.entries) '${entry.key}': entry.value,
      },
    });
    final result = _pending.then((_) async {
      try {
        if (!await prefs.setString('pocket_pals_v1', snapshot)) {
          throw StateError('Save failed');
        }
        error = null;
        return true;
      } catch (_) {
        // The legacy preferences API updates its cache before a platform write
        // succeeds. Refresh it so a reopened store cannot load a failed gift.
        try {
          await prefs.reload();
        } catch (_) {
          // The caller still rolls back live progress if storage is unavailable.
        }
        error = 'Saving failed. Please try again before closing the game.';
        return false;
      }
    });
    _pending = result.then((_) {});
    return result;
  }

  Future<bool> save(Avatar avatar, {int? index}) async {
    if (!canUseCharacter(avatar.character)) {
      error = 'Unlock this character before saving a new look.';
      return false;
    }
    final previousAvatar = index != null && index >= 0 && index < saved.length
        ? saved[index]
        : null;
    for (final selection in avatar.items.entries) {
      final reward = adventureRewardForItem(selection.key, selection.value);
      if (reward != null &&
          !adventureRewards.contains(reward) &&
          previousAvatar?.item(selection.key) != selection.value) {
        error = 'Finish the adventure to earn this special outfit gift.';
        return false;
      }
    }
    final previous = List<Avatar>.of(saved);
    if (index != null && index >= 0 && index < saved.length) {
      saved[index] = avatar;
    } else {
      saved.add(avatar);
    }
    final ok = await persist();
    if (!ok) saved = previous;
    notifyListeners();
    return ok;
  }

  Future<bool> delete(int index) async {
    final previous = List<Avatar>.of(saved);
    saved.removeAt(index);
    final ok = await persist();
    if (!ok) saved = previous;
    notifyListeners();
    return ok;
  }

  Future<bool> complete(
    int index, {
    String? keepsake,
    int level = 0,
    int route = 0,
    bool bonusCompleted = false,
  }) async {
    if (!canPlayChallenge(index)) {
      error = 'Unlock this challenge before playing it.';
      return false;
    }
    if (keepsake != null &&
        (!canPlayAdventureLevel(index, level) ||
            route < 0 ||
            route > 1 ||
            keepsake.trim().isEmpty)) {
      error = 'Finish the earlier adventure level first, then try again.';
      return false;
    }
    if (completed.contains(index) && keepsake == null) return true;
    final wasCompleted = completed.contains(index);
    final previousKeepsakes = Map<int, String>.of(adventureKeepsakes);
    final previousPlays = Map<int, int>.of(adventurePlays);
    final previousLevels = Map<int, int>.of(adventureLevels);
    final previousRewards = Set<int>.of(adventureRewards);
    final previousRoutes = Map<int, int>.of(adventureRoutes);
    final previousHearts = Map<int, int>.of(friendHearts);
    final previousMemories = {
      for (final entry in adventureMemories.entries)
        entry.key: Set<int>.of(entry.value),
    };
    final previousBonuses = Set<int>.of(adventureBonusStars);
    completed.add(index);
    if (keepsake != null) {
      adventureKeepsakes[index] = keepsake.substring(
        0,
        keepsake.length.clamp(0, 80),
      );
      adventurePlays[index] = (adventurePlays[index] ?? 0) + 1;
      if (level + 1 > (adventureLevels[index] ?? 0)) {
        adventureLevels[index] = level + 1;
      }
      adventureRewards.add(index);
      adventureRoutes[index] = route;
      final memory = route * 3 + level;
      adventureMemories.putIfAbsent(index, () => {}).add(memory);
      friendHearts[index] = adventureMemories[index]!.length;
      if (bonusCompleted) adventureBonusStars.add(index * 6 + memory);
    }
    final ok = await persist();
    if (!ok) {
      if (!wasCompleted) completed.remove(index);
      adventureKeepsakes = previousKeepsakes;
      adventurePlays = previousPlays;
      adventureLevels = previousLevels;
      adventureRewards = previousRewards;
      adventureRoutes = previousRoutes;
      friendHearts = previousHearts;
      adventureMemories = previousMemories;
      adventureBonusStars = previousBonuses;
    }
    notifyListeners();
    return ok;
  }

  Future<bool> setSound(bool value) async {
    if (sound == value) return true;
    final previous = sound;
    sound = value;
    notifyListeners();
    final ok = await persist();
    if (!ok) sound = previous;
    notifyListeners();
    return ok;
  }

  Future<void> toggleSound() async {
    await setSound(!sound);
  }

  Future<bool> setReducedMotion(bool value) async {
    if (reducedMotion == value) return true;
    final previous = reducedMotion;
    reducedMotion = value;
    notifyListeners();
    final ok = await persist();
    if (!ok) reducedMotion = previous;
    notifyListeners();
    return ok;
  }
}
