import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pals/models/avatar.dart';

void main() {
  test('Adventure wardrobe rewards are earned independently of stars', () {
    expect(adventureOutfitRewards.length, challenges.length);
    for (int i = 0; i < adventureOutfitRewards.length; i++) {
      final reward = adventureOutfitRewards[i];
      expect(categories[reward.category]![reward.item], reward.label);
      expect(adventureRewardForItem(reward.category, reward.item), i);
      expect(isLocked(reward.category, reward.item, 6), isTrue);
      expect(isLocked(reward.category, reward.item, 0, {i}), isFalse);
      expect(isLocked(reward.category, reward.item, 6, {(i + 1) % 6}), isTrue);
    }
    expect(isLocked('Hats', 5, 1, {0, 1, 2, 3, 4, 5}), isTrue);
    expect(isLocked('Hats', 5, 2), isFalse);
    expect(isLocked('Hats', 6, 4), isFalse);
    expect(isLocked('Bags', 4, 6), isFalse);
  });

  test('Surprise outfits only select earned adventure rewards', () {
    final seen = <int>{};
    for (
      int adventure = 0;
      adventure < adventureOutfitRewards.length;
      adventure++
    ) {
      final earned = {adventure};
      for (int seed = 0; seed < 150; seed++) {
        final avatar = randomize(characterPreset(0), 6, Random(seed), earned);
        for (final item in avatar.items.entries) {
          final reward = adventureRewardForItem(item.key, item.value);
          if (reward != null) {
            expect(earned.contains(reward), isTrue);
            seen.add(reward);
          }
        }
      }
    }
    expect(seen, {0, 1, 2, 3, 4, 5});
  });

  test(
    'Existing wardrobe indexes and earned outfits survive serialization',
    () {
      expect(categories['Bags']!.take(5), [
        'None',
        'Satchel',
        'Bunny bag',
        'Backpack',
        'Magic wand',
      ]);
      expect(categories['Hats']![6], 'Royal crown');
      expect(categories['Dresses']![3], 'Cozy dress');
      expect(categories['Shoes']![3], 'High tops');
      for (final reward in adventureOutfitRewards) {
        final avatar = characterPreset(0).select(reward.category, reward.item);
        final restored = Avatar.fromJson(avatar.toJson());
        expect(restored.item(reward.category), reward.item);
        for (final item in avatar.items.entries) {
          expect(restored.item(item.key), item.value);
        }
      }
    },
  );
}
