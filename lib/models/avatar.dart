import 'dart:math';

import 'package:flutter/material.dart';

const ink = Color(0xFF503744);
const purple = Color(0xFF9F4267);
const cream = Color(0xFFFFF8F5);
const palette = <Color>[
  Color(0xFF9770E8),
  Color(0xFFF58CA8),
  Color(0xFF74BCAD),
  Color(0xFFF1B84B),
  Color(0xFF75A9E0),
  Color(0xFFDC795D),
  Color(0xFF44445D),
];
const skinColors = <Color>[
  Color(0xFFFBE0CB),
  Color(0xFFEFC2A0),
  Color(0xFFDFA47D),
  Color(0xFFBD815E),
  Color(0xFF925A43),
  Color(0xFF664235),
];
const hairColors = <Color>[
  Color(0xFF463448),
  Color(0xFF916044),
  Color(0xFFE4B963),
  Color(0xFFDF8BA9),
  Color(0xFF8F74C8),
  Color(0xFF539C94),
  Color(0xFFD8D5E8),
];

const categories = <String, List<String>>{
  'Hair': [
    'Bob',
    'Waves',
    'Puffs',
    'Pixie',
    'Buns',
    'Curls',
    'Ponytail',
    'Spikes',
  ],
  'Face': ['Happy', 'Wink', 'Excited', 'Dreamy'],
  'Eyes': ['Round', 'Almond', 'Sparkle', 'Sleepy'],
  'Mouth': ['Natural', 'Big smile', 'Little smile', 'Surprised'],
  'Tops': [
    'T-shirt',
    'Overalls',
    'Hoodie',
    'Striped',
    'Jacket',
    'Star tee',
    'Sweater',
  ],
  'Dresses': [
    'None',
    'Party dress',
    'Garden dress',
    'Cozy dress',
    'Stardust dress',
  ],
  'Bottoms': ['Shorts', 'Trousers', 'Skirt', 'Leggings'],
  'Shoes': ['Sneakers', 'Boots', 'Sandals', 'High tops', 'Explorer boots'],
  'Hats': [
    'None',
    'Beanie',
    'Cat ears',
    'Cap',
    'Flower crown',
    'Space helmet',
    'Royal crown',
    'Pearl bow',
  ],
  'Glasses': ['None', 'Round', 'Sunglasses', 'Heart frames'],
  'Earrings': ['None', 'Studs', 'Hoops', 'Stars'],
  'Bags': [
    'None',
    'Satchel',
    'Bunny bag',
    'Backpack',
    'Magic wand',
    'Flower wings',
    'Mermaid bag',
    'Kitten purse',
  ],
  'Scene': [
    'Peach studio',
    'Lavender dream',
    'Garden party',
    'Sunny beach',
    'Starry space',
    'Candy clouds',
  ],
  'Pose': ['Hello', 'Ta-da!', 'Happy dance'],
};

/// Append-only wardrobe rewards keep previously saved item indexes intact.
class OutfitReward {
  final String category, label;
  final int item;
  const OutfitReward(this.category, this.item, this.label);
}

const adventureOutfitRewards = [
  OutfitReward('Bags', 5, 'Flower wings'),
  OutfitReward('Bags', 6, 'Mermaid bag'),
  OutfitReward('Hats', 7, 'Pearl bow'),
  OutfitReward('Dresses', 4, 'Stardust dress'),
  OutfitReward('Shoes', 4, 'Explorer boots'),
  OutfitReward('Bags', 7, 'Kitten purse'),
];

int? adventureRewardForItem(String category, int index) {
  for (int i = 0; i < adventureOutfitRewards.length; i++) {
    final reward = adventureOutfitRewards[i];
    if (reward.category == category && reward.item == index) return i;
  }
  return null;
}

class Avatar {
  final String name;
  final int character, skin, hairColor, eyeColor, color;
  final Map<String, int> items;
  const Avatar({
    required this.name,
    this.character = 0,
    this.skin = 0,
    this.hairColor = 0,
    this.eyeColor = 0,
    this.color = 0,
    required this.items,
  });

  int item(String category) => items[category] ?? 0;
  Avatar copyWith({
    String? name,
    int? character,
    int? skin,
    int? hairColor,
    int? eyeColor,
    int? color,
    Map<String, int>? items,
  }) => Avatar(
    name: name ?? this.name,
    character: character ?? this.character,
    skin: skin ?? this.skin,
    hairColor: hairColor ?? this.hairColor,
    eyeColor: eyeColor ?? this.eyeColor,
    color: color ?? this.color,
    items: items ?? this.items,
  );
  Avatar select(String category, int index) {
    final selections = {...items, category: index};
    if (category == 'Tops' || category == 'Bottoms') selections['Dresses'] = 0;
    if (category == 'Face') {
      selections['Mouth'] = 0;
      if (item('Eyes') == 3) selections['Eyes'] = 0;
    }
    if (category == 'Eyes' && item('Face') == 3) selections['Face'] = 0;
    return copyWith(items: selections);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'character': character,
    'skin': skin,
    'hairColor': hairColor,
    'eyeColor': eyeColor,
    'color': color,
    'items': items,
  };
  factory Avatar.fromJson(Map<String, dynamic> json) {
    int bounded(String key, int length) =>
        ((json[key] as num?)?.toInt() ?? 0).clamp(0, length - 1);
    final raw = (json['items'] as Map?) ?? {};
    return Avatar(
      name: (json['name'] as String?) ?? 'My pal',
      character: bounded('character', 12),
      skin: bounded('skin', skinColors.length),
      hairColor: bounded('hairColor', hairColors.length),
      eyeColor: ((json['eyeColor'] ?? json['color']) as num? ?? 0)
          .toInt()
          .clamp(0, palette.length - 1),
      color: bounded('color', palette.length),
      items: {
        for (final entry in categories.entries)
          entry.key: ((raw[entry.key] as num?)?.toInt() ?? 0).clamp(
            0,
            entry.value.length - 1,
          ),
      },
    );
  }
}

const names = [
  'Luna',
  'Milo',
  'Cleo',
  'Jasper',
  'Poppy',
  'Kai',
  'Nova',
  'Remy',
  'Zara',
  'Finn',
  'Ivy',
  'Sunny',
];
const personalities = [
  'Dream chaser',
  'Little explorer',
  'Cat whisperer',
  'Skate park star',
  'Flower friend',
  'Ocean lover',
  'Space adventurer',
  'Music maker',
  'Creative spirit',
  'Happy camper',
  'Garden keeper',
  'Sunshine collector',
];
Avatar characterPreset(int i) => Avatar(
  name: names[i],
  character: i,
  skin: [1, 3, 0, 4, 2, 1, 5, 2, 4, 0, 3, 2][i],
  hairColor: [4, 0, 3, 1, 2, 0, 6, 1, 0, 2, 5, 1][i],
  color: i % 7,
  eyeColor: i % 7,
  items: {
    'Hair': [1, 3, 0, 5, 4, 7, 2, 6, 2, 3, 1, 5][i],
    'Tops': i % 7,
    'Bottoms': i % 4,
    'Shoes': i % 4,
    'Hats': [0, 3, 2, 0, 4, 0, 0, 1, 0, 3, 4, 1][i],
    'Glasses': i == 7 ? 1 : 0,
    'Earrings': i % 3,
    'Bags': i % 4,
    'Scene': i % 6,
    'Pose': 0,
    'Face': 0,
  },
);

class StyleChallenge {
  final String title, description;
  final IconData icon;
  final Color color;
  final Map<String, int> requirements;
  const StyleChallenge(
    this.title,
    this.description,
    this.icon,
    this.color,
    this.requirements,
  );
  bool matches(Avatar avatar) =>
      requirements.entries.every((e) => avatar.item(e.key) == e.value);
}

const challenges = [
  StyleChallenge(
    'Garden gathering',
    'Dress for a picnic with your flower friends.',
    Icons.local_florist_rounded,
    Color(0xFF83AE9B),
    {'Hats': 4, 'Bags': 2, 'Scene': 2},
  ),
  StyleChallenge(
    'Beach besties',
    'A sunny day calls for a cool seaside look.',
    Icons.wb_sunny_rounded,
    Color(0xFFD8B265),
    {'Glasses': 2, 'Shoes': 2, 'Scene': 3},
  ),
  StyleChallenge(
    'Cozy club',
    'Get comfy for a movie night with your pals.',
    Icons.local_cafe_rounded,
    Color(0xFFD19488),
    {'Tops': 2, 'Hats': 1, 'Scene': 1},
  ),
  StyleChallenge(
    'Superstar',
    'Shine bright and strike a superstar pose.',
    Icons.star_rounded,
    Color(0xFFA693C5),
    {'Tops': 5, 'Earrings': 3, 'Pose': 1},
  ),
  StyleChallenge(
    'Little explorer',
    'Pack a bag and head out on an adventure.',
    Icons.explore_rounded,
    Color(0xFF87ABA5),
    {'Bags': 3, 'Shoes': 1, 'Hats': 3},
  ),
  StyleChallenge(
    'Cat party',
    'Bring your cutest cat look to the candy clouds.',
    Icons.pets_rounded,
    Color(0xFFD991AC),
    {'Hats': 2, 'Glasses': 3, 'Scene': 5},
  ),
];

bool isLocked(
  String category,
  int index,
  int stars, [
  Set<int> adventureRewards = const {},
]) {
  final adventure = adventureRewardForItem(category, index);
  if (adventure != null) return !adventureRewards.contains(adventure);
  return (category == 'Hats' && index == 5 && stars < 2) ||
      (category == 'Hats' && index == 6 && stars < 4) ||
      (category == 'Bags' && index == 4 && stars < 6);
}

Avatar randomize(
  Avatar avatar,
  int stars, [
  Random? random,
  Set<int> adventureRewards = const {},
]) {
  final r = random ?? Random();
  final selections = <String, int>{};
  for (final entry in categories.entries) {
    final choices = List.generate(
      entry.value.length,
      (i) => i,
    ).where((i) => !isLocked(entry.key, i, stars, adventureRewards)).toList();
    selections[entry.key] = choices[r.nextInt(choices.length)];
  }
  return avatar.copyWith(
    items: selections,
    color: r.nextInt(palette.length),
    hairColor: r.nextInt(hairColors.length),
    eyeColor: r.nextInt(palette.length),
    skin: r.nextInt(skinColors.length),
  );
}
