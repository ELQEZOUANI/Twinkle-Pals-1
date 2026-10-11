import 'dart:math';

import 'package:flutter/material.dart';

enum AdventureKind { hunt, memory, sequence, trail }

class AdventureToken {
  final String label;
  final IconData icon;
  const AdventureToken(this.label, this.icon);
}

const adventureLevelNames = ['Easy', 'Growing', 'Brave'];

class AdventureChoice {
  final String title, description, objective, friendName;
  final int friendCharacterIndex;
  final List<AdventureToken> tokens;
  const AdventureChoice({
    required this.title,
    required this.description,
    required this.objective,
    required this.friendName,
    required this.friendCharacterIndex,
    required this.tokens,
  });
}

class AdventureTheme {
  final String story, gameTitle, hint, success;
  final AdventureKind kind;
  final List<AdventureToken> tokens;
  final List<String> keepsakes;
  final List<AdventureChoice> choices;
  const AdventureTheme({
    required this.story,
    required this.gameTitle,
    required this.hint,
    required this.success,
    required this.kind,
    required this.tokens,
    required this.keepsakes,
    required this.choices,
  });
}

const adventures = [
  AdventureTheme(
    story: 'The picnic is almost ready! Dress for the garden, find flowers for your friends, then plan your own little party.',
    gameTitle: 'Bloom hunt',
    hint: 'Find all five flowers hiding among the garden treasures.',
    success: 'Five happy flowers! Your friends have a beautiful bouquet.',
    kind: AdventureKind.hunt,
    tokens: [
      AdventureToken('Flower', Icons.local_florist_rounded),
      AdventureToken('Butterfly', Icons.flutter_dash),
      AdventureToken('Leaf', Icons.eco_rounded),
      AdventureToken('Sunshine', Icons.wb_sunny_rounded),
    ],
    keepsakes: ['Rainbow picnic', 'Butterfly garden', 'Flower friendship'],
    choices: [
      AdventureChoice(
        title: 'A bouquet for Poppy',
        description: 'Poppy is hosting a garden picnic. Help her find flowers for every guest.',
        objective: 'Find the flowers for Poppy’s picnic bouquet.',
        friendName: 'Poppy',
        friendCharacterIndex: 4,
        tokens: [
          AdventureToken('Flower', Icons.local_florist_rounded),
          AdventureToken('Butterfly', Icons.flutter_dash),
          AdventureToken('Leaf', Icons.eco_rounded),
          AdventureToken('Sunshine', Icons.wb_sunny_rounded),
        ],
      ),
      AdventureChoice(
        title: 'Luna’s berry picnic',
        description: 'Luna has empty picnic bowls. Pick the strawberries hiding in the garden.',
        objective: 'Find the strawberries for Luna’s picnic bowls.',
        friendName: 'Luna',
        friendCharacterIndex: 0,
        tokens: [
          AdventureToken('Strawberry', Icons.favorite_rounded),
          AdventureToken('Butterfly', Icons.flutter_dash),
          AdventureToken('Leaf', Icons.eco_rounded),
          AdventureToken('Sunshine', Icons.wb_sunny_rounded),
        ],
      ),
    ],
  ),
  AdventureTheme(
    story: 'A message washed up on the shore! Put on your beach look, match the ocean treasures, then choose your seaside celebration.',
    gameTitle: 'Ocean pairs',
    hint: 'Turn over two cards at a time. Find three matching ocean pairs.',
    success: 'You matched every treasure from the ocean!',
    kind: AdventureKind.memory,
    tokens: [
      AdventureToken('Shell', Icons.water_rounded),
      AdventureToken('Sea star', Icons.star_rounded),
      AdventureToken('Little boat', Icons.sailing_rounded),
    ],
    keepsakes: ['Sandcastle club', 'Ocean treasure', 'Sunset besties'],
    choices: [
      AdventureChoice(
        title: 'Kai’s ocean collection',
        description: 'Kai found a box of ocean treasures. Help him match each treasure with its twin.',
        objective: 'Match the pairs for Kai’s ocean collection.',
        friendName: 'Kai',
        friendCharacterIndex: 5,
        tokens: [
          AdventureToken('Shell', Icons.water_rounded),
          AdventureToken('Sea star', Icons.star_rounded),
          AdventureToken('Little boat', Icons.sailing_rounded),
          AdventureToken('Seahorse', Icons.waves_rounded),
          AdventureToken('Pearl', Icons.circle),
        ],
      ),
      AdventureChoice(
        title: 'Sunny’s sandcastle',
        description: 'Sunny is building a beach palace. Find matching sets of tools and decorations.',
        objective: 'Match the sandcastle supplies for Sunny.',
        friendName: 'Sunny',
        friendCharacterIndex: 11,
        tokens: [
          AdventureToken('Bucket', Icons.beach_access_rounded),
          AdventureToken('Shovel', Icons.construction_rounded),
          AdventureToken('Castle flag', Icons.flag_rounded),
          AdventureToken('Beach ball', Icons.sports_volleyball_rounded),
          AdventureToken('Castle crown', Icons.workspace_premium_rounded),
        ],
      ),
    ],
  ),
  AdventureTheme(
    story: 'Your friends are coming for movie night. Get cozy, follow the surprise snack recipe, and pick tonight’s movie party.',
    gameTitle: 'Snack kitchen',
    hint: 'Follow the recipe one snack at a time. The next ingredient is shown below.',
    success: 'Snacks are ready! Movie night can begin.',
    kind: AdventureKind.sequence,
    tokens: [
      AdventureToken('Popcorn', Icons.local_movies_rounded),
      AdventureToken('Cookie', Icons.cookie_rounded),
      AdventureToken('Hot chocolate', Icons.local_cafe_rounded),
      AdventureToken('Cupcake', Icons.cake_rounded),
    ],
    keepsakes: ['Pajama cinema', 'Cookie clubhouse', 'Cozy cocoa night'],
    choices: [
      AdventureChoice(
        title: 'Remy’s movie snacks',
        description: 'Remy picked the movie. Follow the recipe to make a snack tray to share.',
        objective: 'Follow Remy’s snack recipe, one tasty step at a time.',
        friendName: 'Remy',
        friendCharacterIndex: 7,
        tokens: [
          AdventureToken('Popcorn', Icons.local_movies_rounded),
          AdventureToken('Cookie', Icons.cookie_rounded),
          AdventureToken('Hot chocolate', Icons.local_cafe_rounded),
          AdventureToken('Cupcake', Icons.cake_rounded),
        ],
      ),
      AdventureChoice(
        title: 'Ivy’s story nook',
        description: 'Ivy is planning a sleepover. Follow her picture plan to build the coziest reading nook.',
        objective: 'Follow Ivy’s plan to arrange her cozy story nook.',
        friendName: 'Ivy',
        friendCharacterIndex: 10,
        tokens: [
          AdventureToken('Pillow', Icons.cloud_rounded),
          AdventureToken('Blanket', Icons.grid_view_rounded),
          AdventureToken('Storybook', Icons.menu_book_rounded),
          AdventureToken('Teddy', Icons.pets_rounded),
        ],
      ),
    ],
  ),
  AdventureTheme(
    story: 'The spotlight is waiting for you! Create a stage outfit, learn a new dance remix, and choose your big show finale.',
    gameTitle: 'Dance remix',
    hint: 'Copy the moves in your dance remix. Take your time and make it your own!',
    success: 'What a performance! The crowd is cheering for you.',
    kind: AdventureKind.sequence,
    tokens: [
      AdventureToken('Wave', Icons.waving_hand_rounded),
      AdventureToken('Twirl', Icons.rotate_right_rounded),
      AdventureToken('Star pose', Icons.accessibility_new_rounded),
      AdventureToken('Jump', Icons.bolt_rounded),
    ],
    keepsakes: ['Rainbow pop star', 'Moonlight dancer', 'Sparkle spotlight'],
    choices: [
      AdventureChoice(
        title: 'Nova’s dance duet',
        description: 'Nova wants a dance partner. Learn her playful moves and perform together.',
        objective: 'Follow Nova’s dance moves to finish your duet.',
        friendName: 'Nova',
        friendCharacterIndex: 6,
        tokens: [
          AdventureToken('Wave', Icons.waving_hand_rounded),
          AdventureToken('Twirl', Icons.rotate_right_rounded),
          AdventureToken('Star pose', Icons.accessibility_new_rounded),
          AdventureToken('Jump', Icons.bolt_rounded),
        ],
      ),
      AdventureChoice(
        title: 'Zara’s stage surprise',
        description: 'Zara is ready to sing. Follow her stage plan to arrange a sparkling show.',
        objective: 'Set up Zara’s show by following her stage plan.',
        friendName: 'Zara',
        friendCharacterIndex: 8,
        tokens: [
          AdventureToken('Lights', Icons.lightbulb_rounded),
          AdventureToken('Ribbon', Icons.redeem_rounded),
          AdventureToken('Microphone', Icons.mic_rounded),
          AdventureToken('Confetti', Icons.celebration_rounded),
        ],
      ),
    ],
  ),
  AdventureTheme(
    story: 'There is a secret treasure across the stream. Pack an explorer outfit, follow the stepping stones, and name your discovery.',
    gameTitle: 'Treasure trail',
    hint: 'Start at the flag. Follow the connected stones, one step at a time, to the treasure.',
    success: 'You made it across the stream! A secret treasure is yours.',
    kind: AdventureKind.trail,
    tokens: [AdventureToken('Treasure', Icons.diamond_rounded)],
    keepsakes: ['Crystal discovery', 'Hidden rainbow', 'Secret star island'],
    choices: [
      AdventureChoice(
        title: 'Milo’s secret map',
        description: 'Milo found a map to a crystal chest. Cross the stream together to discover it.',
        objective: 'Follow the connected stones to Milo’s hidden treasure.',
        friendName: 'Milo',
        friendCharacterIndex: 1,
        tokens: [AdventureToken('Treasure', Icons.diamond_rounded)],
      ),
      AdventureChoice(
        title: 'Finn’s bird rescue',
        description: 'A little bird dropped its ribbon. Help Finn return it to the nest across the stream.',
        objective: 'Follow the connected stones to return the ribbon to the bird’s nest.',
        friendName: 'Finn',
        friendCharacterIndex: 9,
        tokens: [AdventureToken('Bird nest', Icons.flutter_dash)],
      ),
    ],
  ),
  AdventureTheme(
    story: 'A kitten needs help getting ready for a party. Dress up, follow its little wishes, then choose a purr-fect celebration.',
    gameTitle: 'Kitten care',
    hint: 'What does the kitten need next? Give it the thing shown in its wish bubble.',
    success: 'One happy kitten! It is ready to celebrate with you.',
    kind: AdventureKind.sequence,
    tokens: [
      AdventureToken('Snack', Icons.restaurant_rounded),
      AdventureToken('Water', Icons.water_drop_rounded),
      AdventureToken('Toy', Icons.sports_baseball_rounded),
      AdventureToken('Cuddle', Icons.favorite_rounded),
    ],
    keepsakes: ['Kitten birthday', 'Candy cloud cats', 'Purr-fect friends'],
    choices: [
      AdventureChoice(
        title: 'Cleo’s kitten party',
        description: 'Cleo’s kitten has a wish list. Help her feed it, play with it, and share a cuddle.',
        objective: 'Follow the kitten’s wishes with Cleo.',
        friendName: 'Cleo',
        friendCharacterIndex: 2,
        tokens: [
          AdventureToken('Snack', Icons.restaurant_rounded),
          AdventureToken('Water', Icons.water_drop_rounded),
          AdventureToken('Toy', Icons.sports_baseball_rounded),
          AdventureToken('Cuddle', Icons.favorite_rounded),
        ],
      ),
      AdventureChoice(
        title: 'Jasper’s kitten spa',
        description: 'Jasper wants to pamper a sleepy kitten. Follow its little grooming wishes.',
        objective: 'Follow the kitten’s spa wishes with Jasper.',
        friendName: 'Jasper',
        friendCharacterIndex: 3,
        tokens: [
          AdventureToken('Brush', Icons.brush_rounded),
          AdventureToken('Bubbles', Icons.bubble_chart_rounded),
          AdventureToken('Soft towel', Icons.dry_cleaning_rounded),
          AdventureToken('Bow', Icons.redeem_rounded),
        ],
      ),
    ],
  ),
];

/// Optional little favors appear during play. They never gate the main stamp.
class BonusRound {
  final String title, prompt, success;
  final List<AdventureToken> choices;
  final int correctIndex;
  bool completed = false;
  String feedback = '';

  BonusRound({
    required this.title,
    required this.prompt,
    required this.success,
    required this.choices,
    required this.correctIndex,
  });

  bool choose(int index) {
    if (completed || index < 0 || index >= choices.length) return false;
    if (index != correctIndex) {
      feedback = 'Have another look at the little wish. Take your time!';
      return false;
    }
    completed = true;
    feedback = success;
    return true;
  }
}

/// A new board for each play. Wrong choices offer a hint without losing progress.
class AdventureRound {
  final AdventureTheme theme;
  final int level, route;
  late final AdventureChoice choice;
  late final List<AdventureToken> tokens;
  late final List<int> board, order, trail;
  late final BonusRound bonus;
  final Set<int> found = {}, matched = {}, visited = {};
  final List<int> openCards = [];
  int step = 0;
  String feedback = '';

  AdventureRound(int index, {Random? random, int level = 0, int route = 0})
    : theme = adventures[index],
      level = level.clamp(0, 2),
      route = route.clamp(0, 1) {
    final r = random ?? Random();
    choice = theme.choices[this.route];
    tokens = choice.tokens;
    board = switch (theme.kind) {
      AdventureKind.hunt => [
        ...List.filled(5 + this.level * 2, 0),
        ...List.generate(4 + this.level * 2, (i) => 1 + i % 3),
      ]..shuffle(r),
      AdventureKind.memory => [
        for (var i = 0; i < 3 + this.level; i++) ...[i, i],
      ]..shuffle(r),
      AdventureKind.trail => List.generate(columns * columns, (i) => i),
      AdventureKind.sequence => List.generate(tokens.length, (i) => i),
    };
    order = List.generate(tokens.length, (i) => i)..shuffle(r);
    if (index == 3) order.add(order.first);
    order.addAll(
      List.generate(this.level * 2, (_) => r.nextInt(tokens.length)),
    );
    // Alternating turns produce a single unambiguous path. Its mirror is the
    // bird-rescue route; larger grids gently add more stepping stones.
    var row = columns - 1;
    var col = 0;
    trail = [row * columns + col];
    final upFirst = r.nextBool();
    while (row > 0 || col < columns - 1) {
      if (upFirst) {
        if (row > 0) trail.add(--row * columns + col);
        if (col < columns - 1) trail.add(row * columns + ++col);
      } else {
        if (col < columns - 1) trail.add(row * columns + ++col);
        if (row > 0) trail.add(--row * columns + col);
      }
    }
    if (this.route == 1) {
      for (var i = 0; i < trail.length; i++) {
        trail[i] =
            trail[i] ~/ columns * columns + columns - 1 - trail[i] % columns;
      }
    }
    visited.add(trail.first);
    bonus = _makeBonus(index, r);
  }

  int get columns => theme.kind == AdventureKind.trail ? 4 + level : 3;
  int get huntTarget => 0;
  String get hint => switch (theme.kind) {
    AdventureKind.hunt => '${choice.objective} Find $total in all.',
    AdventureKind.memory => '${choice.objective} There are $total pairs.',
    AdventureKind.sequence =>
      '${choice.objective} The next step is shown below.',
    AdventureKind.trail => '${choice.objective} Start at the flag.',
  };
  String get success => '${choice.friendName} says, “We did it together!”';
  bool get bonusAvailable => progress >= (total / 2).ceil();
  int get total => switch (theme.kind) {
    AdventureKind.hunt => 5 + level * 2,
    AdventureKind.memory => 3 + level,
    AdventureKind.sequence => order.length,
    AdventureKind.trail => trail.length - 1,
  };
  int get progress => switch (theme.kind) {
    AdventureKind.hunt => found.length,
    AdventureKind.memory => matched.length ~/ 2,
    AdventureKind.sequence => step,
    AdventureKind.trail => visited.length - 1,
  };
  bool get complete => progress == total;

  bool choose(int index) {
    if (complete) return false;
    bool good = false;
    switch (theme.kind) {
      case AdventureKind.hunt:
        if (index < 0 || index >= board.length || found.contains(index)) {
          return false;
        }
        good = board[index] == huntTarget;
        if (good) found.add(index);
        feedback = good
            ? '${choice.friendName} loves it! $progress of $total found.'
            : 'Look for the ${tokens[huntTarget].label.toLowerCase()} shapes. You can do it!';
      case AdventureKind.memory:
        if (index < 0 || index >= board.length || matched.contains(index)) {
          return false;
        }
        if (openCards.length == 2) openCards.clear();
        if (openCards.contains(index)) return false;
        openCards.add(index);
        if (openCards.length == 2) {
          good = board[openCards.first] == board[openCards.last];
          if (good) matched.addAll(openCards);
          feedback = good
              ? 'A matching pair! $progress of $total pairs found.'
              : 'Different treasures! Tap another card to try again.';
        } else {
          feedback =
              'Can you find the other ${tokens[board[index]].label.toLowerCase()}?';
        }
      case AdventureKind.sequence:
        if (index < 0 || index >= tokens.length) return false;
        good = index == order[step];
        if (good) step++;
        feedback = good
            ? 'Lovely! $progress of $total steps complete.'
            : 'Try ${tokens[order[step]].label.toLowerCase()} next. You can do it!';
      case AdventureKind.trail:
        if (index < 0 ||
            index >= columns * columns ||
            visited.contains(index)) {
          return false;
        }
        good = index == trail[visited.length];
        if (good) visited.add(index);
        feedback = good
            ? 'One step closer! $progress of $total stones crossed.'
            : 'Follow the next connected stone. Your pal is safe!';
    }
    if (complete) feedback = success;
    return good;
  }

  BonusRound _makeBonus(int index, Random random) {
    final wishes = [
      (
        'A butterfly visitor!',
        'A butterfly would like a flower. Find a flower for it.',
        AdventureToken('Flower', Icons.local_florist_rounded),
      ),
      (
        'A turtle delivery!',
        'A turtle brought a message. Find the shell-shaped envelope.',
        AdventureToken('Shell letter', Icons.mail_rounded),
      ),
      (
        'A tiny tea guest!',
        'A teddy joined the sleepover. Find a warm cup of cocoa for it.',
        AdventureToken('Cocoa', Icons.local_cafe_rounded),
      ),
      (
        'A secret encore!',
        'The crowd is asking for a heart. Send a heart to your cheering friends.',
        AdventureToken('Heart', Icons.favorite_rounded),
      ),
      (
        'A glowing chest!',
        'The little chest has a star-shaped lock. Find its star key.',
        AdventureToken('Star key', Icons.star_rounded),
      ),
      (
        'A kitten surprise!',
        'A shy kitten wants to play. Find a ball of yarn for it.',
        AdventureToken('Yarn', Icons.sports_baseball_rounded),
      ),
    ];
    final wish = wishes[index];
    final options = [
      wish.$3,
      const AdventureToken('Leaf', Icons.eco_rounded),
      const AdventureToken('Ribbon', Icons.redeem_rounded),
    ]..shuffle(random);
    return BonusRound(
      title: wish.$1,
      prompt: wish.$2,
      success:
          '${choice.friendName}: “That was so kind! Here is a bonus sparkle.”',
      choices: options,
      correctIndex: options.indexOf(wish.$3),
    );
  }
}

class AdventureResult {
  final String keepsake;
  final int level, route;
  final bool bonusCompleted;
  const AdventureResult(
    this.keepsake, {
    this.level = 0,
    this.route = 0,
    this.bonusCompleted = false,
  });
}
