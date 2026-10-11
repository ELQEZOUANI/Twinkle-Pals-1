import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/adventure.dart';
import '../models/avatar.dart';
import 'avatar_art.dart';

const _rose = Color(0xFFB74377);
const _gold = Color(0xFFB28036);
const _pearl = Color(0xFFFFFCF8);
const _blush = Color(0xFFFBE7EF);

class AdventurePlay extends StatefulWidget {
  final int index;
  final Avatar avatar;
  final VoidCallback? onGoodChoice;
  final int initialLevel, availableLevel;
  final bool rewardEarned;
  const AdventurePlay({
    super.key,
    required this.index,
    required this.avatar,
    this.onGoodChoice,
    this.initialLevel = 0,
    this.availableLevel = 0,
    this.rewardEarned = false,
  });

  @override
  State<AdventurePlay> createState() => _AdventurePlayState();
}

class _AdventurePlayState extends State<AdventurePlay>
    with SingleTickerProviderStateMixin {
  late int level = widget.initialLevel.clamp(
    0,
    widget.availableLevel.clamp(0, 2),
  );
  int route = 0;
  AdventureRound? _round;
  AdventureRound get round => _round!;
  AdventureTheme get theme => adventures[widget.index];
  AdventureChoice get choice => theme.choices[route];
  final scroll = ScrollController();
  late final reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
    value: 1,
  );
  bool finale = false, bonusOpen = false, bonusSkipped = false;
  int keepsake = 0, reactions = 0;
  String bonusHint = '';
  bool get reducedMotion => MediaQuery.disableAnimationsOf(context);
  Duration get transition =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 260);
  static const levelNames = [
    'Little steps',
    'Growing explorer',
    'Star adventurer',
  ];

  @override
  void dispose() {
    scroll.dispose();
    reaction.dispose();
    super.dispose();
  }

  void _top() {
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void _cheer() {
    reactions++;
    if (!reducedMotion) reaction.forward(from: 0);
    widget.onGoodChoice?.call();
  }

  void choose(int index) {
    setState(() {
      if (round.choose(index)) _cheer();
    });
  }

  void _begin() {
    setState(
      () => _round = AdventureRound(widget.index, level: level, route: route),
    );
    _top();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: _pearl,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4F8), _pearl, Color(0xFFFFF5DF)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _blush,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      challenges[widget.index].icon,
                      color: _rose,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      challenges[widget.index].title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('exit-adventure'),
                    tooltip: 'Leave adventure',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _stage('1 · Style', true),
                  const SizedBox(width: 7),
                  _stage('2 · Play', _round != null),
                  const SizedBox(width: 7),
                  _stage('3 · Celebrate', finale),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 570),
                    child: finale
                        ? _finale()
                        : _round == null
                        ? _story()
                        : _game(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _stage(String text, bool done) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        color: done ? _blush : Colors.white.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: done ? const Color(0xFFE9B7CC) : const Color(0xFFF0E5DC),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: done ? _rose : const Color(0xFF8B7781),
        ),
      ),
    ),
  );

  Widget _eyebrow(String text, {IconData icon = Icons.auto_awesome_rounded}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: _gold),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      );

  Widget _heading(String title, String subtitle) => Column(
    children: [
      const SizedBox(height: 9),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 28,
          height: 1.1,
          letterSpacing: -.7,
          color: ink,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          height: 1.45,
          color: Color(0xFF75606F),
          fontSize: 13,
        ),
      ),
    ],
  );

  Widget _story() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _eyebrow('A LITTLE FRIENDSHIP ADVENTURE'),
      _heading(
        'A story made by you',
        'Pick a friend’s plan. Your choice changes what happens next!',
      ),
      const SizedBox(height: 20),
      for (var i = 0; i < theme.choices.length; i++) ...[
        _storyChoice(i),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 8),
      const Text(
        'How big is today’s adventure?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      const SizedBox(height: 6),
      const Text(
        'Play at your own pace. Finish a level to open the next.',
        style: TextStyle(fontSize: 12, color: Color(0xFF75606F), height: 1.4),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 3; i++)
            ChoiceChip(
              key: ValueKey('difficulty-$i'),
              avatar: Icon(
                i > widget.availableLevel
                    ? Icons.lock_outline_rounded
                    : Icons.favorite_rounded,
                size: 15,
                color: i == level ? _rose : _gold,
              ),
              label: Text(
                '${i + 1} · ${levelNames[i]}',
                style: const TextStyle(fontSize: 12),
              ),
              selected: level == i,
              selectedColor: _blush,
              onSelected: i <= widget.availableLevel
                  ? (_) => setState(() => level = i)
                  : null,
            ),
        ],
      ),
      const SizedBox(height: 20),
      _rewardPreview(compact: true),
      const SizedBox(height: 20),
      FilledButton.icon(
        key: const ValueKey('begin-adventure'),
        onPressed: _begin,
        icon: const Icon(Icons.favorite_rounded),
        label: Text('Let’s help ${choice.friendName}'),
      ),
    ],
  );

  Widget _storyChoice(int index) {
    final option = theme.choices[index];
    final selected = route == index;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: ValueKey('story-choice-$index'),
          onTap: () => setState(() => route = index),
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: transition,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? _rose : const Color(0xFFEEDDE5),
                width: selected ? 2 : 1,
              ),
              gradient: selected
                  ? const LinearGradient(
                      colors: [Colors.white, Color(0xFFFFF0F5)],
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 55,
                      height: 70,
                      child: AvatarArt(
                        avatar: characterPreset(option.friendCharacterIndex)
                            .select('Pose', 1),
                        scene: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WITH ${option.friendName.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _gold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            option.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected ? _rose : const Color(0xFFDCC5CE),
                      size: 23,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  option.description,
                  style: const TextStyle(
                    height: 1.45,
                    fontSize: 13,
                    color: Color(0xFF75606F),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  option.objective,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _rose,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _game() => Column(
    children: [
      _eyebrow('LEVEL ${level + 1} · ${levelNames[level].toUpperCase()}'),
      _heading(route == 0 ? theme.gameTitle : choice.title, round.hint),
      const SizedBox(height: 18),
      _friendScene(),
      const SizedBox(height: 14),
      _progress(),
      if (theme.kind == AdventureKind.sequence && !round.complete) ...[
        const SizedBox(height: 12),
        _nextStep(),
      ],
      const SizedBox(height: 18),
      _board(),
      const SizedBox(height: 14),
      Semantics(
        liveRegion: true,
        child: AnimatedSwitcher(
          duration: transition,
          child: Text(
            round.feedback.isEmpty ? 'Ready? Tap to play!' : round.feedback,
            key: ValueKey(round.feedback),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              height: 1.45,
              fontSize: 13,
              color: _rose,
            ),
          ),
        ),
      ),
      if (round.bonusAvailable && !bonusSkipped) ...[
        const SizedBox(height: 18),
        _bonus(),
      ],
      if (round.complete) ...[
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('adventure-finale'),
            onPressed: () {
              setState(() => finale = true);
              _top();
            },
            icon: const Icon(Icons.celebration_rounded),
            label: const Text('Plan my celebration'),
          ),
        ),
      ],
    ],
  );

  Widget _friendScene() => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: AnimatedBuilder(
      key: const ValueKey('adventure-reaction-scene'),
      animation: reaction,
      builder: (context, _) {
        final bounce = reducedMotion ? 0.0 : math.sin(reaction.value * math.pi);
        final words = round.complete
            ? '${choice.friendName}: “We did it together!”'
            : reactions > 0
            ? _reactionWords()
            : '${choice.friendName}: “I’m glad you’re here!”';
        return CustomPaint(
          painter: _FriendScenePainter(
            widget.index,
            round.progress / round.total,
            reducedMotion ? 1 : reaction.value,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .93),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    words,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ink,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Transform.translate(
                          key: const ValueKey('adventure-pal-reaction'),
                          offset: Offset(0, -bounce * 9),
                          child: SizedBox(
                            width: 90,
                            height: 121,
                            child: AvatarArt(
                              avatar: widget.avatar.select(
                                'Pose',
                                reactions == 0 ? 0 : reactions % 3,
                              ),
                              scene: false,
                              interactive: true,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Transform.scale(
                          scale: 1 + bounce * .24,
                          child: Text(
                            _sceneSymbol(),
                            style: const TextStyle(fontSize: 34),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Transform.translate(
                          offset: Offset(0, -bounce * 5),
                          child: SizedBox(
                            width: 82,
                            height: 110,
                            child: AvatarArt(
                              avatar: characterPreset(
                                choice.friendCharacterIndex,
                              ).select('Pose', reactions == 0 ? 0 : 1),
                              scene: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  String _sceneSymbol() => (route == 0
      ? ['🌷', '🐚', '🧁', '🌟', '💎', '🐱']
      : ['🍓', '🏰', '📖', '🎤', '🐦', '🐱'])[widget.index];
  String _reactionWords() => (route == 0
      ? [
          'A new bloom! Our garden is waking up.',
          'A lovely pair! Our ocean treasure grows.',
          'Mmm… our kitchen smells delicious!',
          'Bravo! Let’s dance together!',
          'You found the way! Adventure buddies!',
          'Purr, purr… one very happy kitten!',
        ]
      : [
          'Berry lovely! Our picnic bowls are filling up.',
          'A perfect pair! Our palace is coming together.',
          'So cozy! Our story nook feels like a hug.',
          'Sparkle on! Our show is almost ready.',
          'Tweet, tweet! The little bird is waiting.',
          'Purr, purr… spa time feels so lovely!',
        ])[widget.index];

  Widget _progress() => Row(
    children: [
      const Icon(Icons.favorite_rounded, color: _rose, size: 19),
      const SizedBox(width: 10),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: round.progress / round.total),
            duration: transition,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              color: _rose,
              minHeight: 9,
              backgroundColor: _blush,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        '${round.progress} / ${round.total}',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: _rose,
          fontSize: 13,
        ),
      ),
    ],
  );

  Widget _nextStep() {
    final token = round.tokens[round.order[round.step]];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBC4D4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tokenArt(token.label, token.icon, 26),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              'Next: ${token.label}',
              key: const ValueKey('next-adventure-step'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: _rose),
            ),
          ),
        ],
      ),
    );
  }

  Widget _board() {
    final trail = theme.kind == AdventureKind.trail;
    final sequence = theme.kind == AdventureKind.sequence;
    final count = trail
        ? round.columns * round.columns
        : sequence
        ? round.tokens.length
        : round.board.length;
    final columns = trail
        ? round.columns
        : sequence
        ? 2
        : 3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = trail
            ? columns > 4
                  ? 2.0
                  : 6.0
            : 10.0;
        final tileWidth =
            (constraints.maxWidth - (columns - 1) * gap) / columns;
        final minimumHeight = trail && columns > 4
            ? 52.0
            : (trail ? 62 : 58) +
                  MediaQuery.textScalerOf(context).scale(10) * 2.8;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: (sequence ? tileWidth / 1.6 : tileWidth).clamp(
              minimumHeight,
              2000,
            ),
          ),
          itemBuilder: (context, i) {
            if (trail) {
              final stone = round.trail.contains(i);
              final visited = round.visited.contains(i);
              final label = i == round.trail.first
                  ? 'Start'
                  : i == round.trail.last
                  ? round.tokens.first.label
                  : stone
                  ? 'Stone'
                  : 'Stream';
              return _tile(
                i,
                label,
                i == round.trail.first
                    ? Icons.flag_rounded
                    : i == round.trail.last
                    ? Icons.diamond_rounded
                    : Icons.water_rounded,
                selected: visited,
                enabled: stone && !visited && !round.complete,
                tileColor: stone
                    ? const Color(0xFFF5E8D7)
                    : const Color(0xFFE5F3F4),
                compact: columns > 4,
              );
            }
            final memory = theme.kind == AdventureKind.memory;
            final token = round.tokens[sequence ? i : round.board[i]];
            final selected = memory
                ? round.matched.contains(i)
                : round.found.contains(i);
            final revealed = !memory || selected || round.openCards.contains(i);
            return _tile(
              i,
              revealed ? token.label : 'Ocean card ${i + 1}',
              revealed ? token.icon : Icons.question_mark_rounded,
              selected: selected,
              enabled: !selected && !round.complete,
              concealed: !revealed,
            );
          },
        );
      },
    );
  }

  Widget _tile(
    int index,
    String label,
    IconData icon, {
    required bool selected,
    required bool enabled,
    Color? tileColor,
    bool compact = false,
    bool concealed = false,
  }) => Semantics(
    label: label,
    button: true,
    selected: selected,
    child: Material(
      color: selected ? const Color(0xFFF7DFEB) : tileColor ?? Colors.white,
      borderRadius: BorderRadius.circular(compact ? 12 : 19),
      child: InkWell(
        key: ValueKey('adventure-tile-$index'),
        onTap: enabled ? () => choose(index) : null,
        borderRadius: BorderRadius.circular(compact ? 12 : 19),
        child: AnimatedContainer(
          duration: transition,
          padding: EdgeInsets.all(compact ? 3 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 12 : 19),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD17B9E)
                  : const Color(0xFFECDDE4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: transition,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: selected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('matched'),
                        size: compact ? 22 : 30,
                        color: _rose,
                      )
                    : concealed
                    ? const Icon(
                        Icons.auto_awesome_rounded,
                        key: ValueKey('hidden'),
                        size: 30,
                        color: _gold,
                      )
                    : KeyedSubtree(
                        key: ValueKey(label),
                        child: _tokenArt(
                          label,
                          icon,
                          theme.kind == AdventureKind.trail
                              ? compact
                                    ? 21
                                    : 25
                              : 32,
                        ),
                      ),
              ),
              if (!compact) ...[
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _tokenArt(String label, IconData icon, double size) {
    final symbol = _symbol(label);
    return symbol == null
        ? Icon(icon, size: size, color: _rose)
        : Text(symbol, style: TextStyle(fontSize: size, height: 1.1));
  }

  String? _symbol(String label) => switch (label) {
    'Flower' || 'Rose' => '🌸',
    'Butterfly' => '🦋',
    'Leaf' => '🍃',
    'Sunshine' => '☀️',
    'Shell' => '🐚',
    'Sea star' => '⭐',
    'Little boat' => '⛵',
    'Pearl' => '🫧',
    'Coral' => '🪸',
    'Fish' => '🐠',
    'Dolphin' => '🐬',
    'Popcorn' => '🍿',
    'Cookie' => '🍪',
    'Hot chocolate' => '☕',
    'Cupcake' => '🧁',
    'Strawberry' => '🍓',
    'Sprinkles' => '✨',
    'Cream' => '🍦',
    'Berries' => '🫐',
    'Wave' => '👋',
    'Twirl' => '🌀',
    'Star pose' => '🌟',
    'Jump' => '⚡',
    'Clap' => '👏',
    'Heart pose' => '💗',
    'Bow' => '🎀',
    'Tiptoe' => '🩰',
    'Snack' => '🐟',
    'Water' => '💧',
    'Toy' => '🧶',
    'Cuddle' => '💗',
    'Brush' => '🪮',
    'Bed' => '🛏️',
    'Ribbon' => '🎀',
    'Treat' => '🐟',
    'Start' => '🏁',
    'Treasure' => '💎',
    'Stone' => '🪨',
    'Stream' => '🌊',
    'Seahorse' => '🪸',
    'Bucket' => '🪣',
    'Shovel' => '🪏',
    'Castle flag' => '🚩',
    'Beach ball' => '🏐',
    'Castle crown' => '👑',
    'Pillow' => '☁️',
    'Blanket' => '🧣',
    'Storybook' => '📖',
    'Teddy' => '🧸',
    'Lights' => '💡',
    'Microphone' => '🎤',
    'Confetti' => '🎊',
    'Bird nest' => '🪺',
    'Bubbles' => '🫧',
    'Soft towel' => '🧺',
    'Rainbow' => '🌈',
    'Heart' => '💗',
    'Gift' => '🎁',
    'Balloon' => '🎈',
    'Star' => '⭐',
    'Map' => '🗺️',
    'Watering can' => '💦',
    _ => null,
  };

  Widget _bonus() {
    final bonus = round.bonus;
    return Container(
      key: const ValueKey('adventure-bonus'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4D9), Color(0xFFFFE8F0)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFD9AD)),
      ),
      child: Column(
        children: [
          Text(
            bonus.completed
                ? '✨ A little extra kindness!'
                : '🦋 A surprise for you!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: ink,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 7),
          if (bonus.completed)
            const Text(
              'A friendship sparkle for your stamp. Thank you for helping!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.4),
            )
          else if (!bonusOpen) ...[
            const Text(
              'A tiny extra mission has arrived. Want to peek?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const ValueKey('open-adventure-bonus'),
              onPressed: () => setState(() => bonusOpen = true),
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text('Open surprise'),
            ),
          ] else ...[
            Text(
              bonus.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, color: _rose),
            ),
            const SizedBox(height: 8),
            Text(
              bonus.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < bonus.choices.length; i++)
                  OutlinedButton.icon(
                    key: ValueKey('bonus-choice-$i'),
                    onPressed: () => setState(() {
                      if (bonus.choose(i)) {
                        _cheer();
                        bonusHint = '';
                      } else {
                        bonusHint = 'A sweet idea! Take another look at the little wish.';
                      }
                    }),
                    icon: Icon(bonus.choices[i].icon, size: 17),
                    label: Text(
                      bonus.choices[i].label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (bonusHint.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    bonusHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _rose,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
          ],
          if (!bonus.completed)
            TextButton(
              key: const ValueKey('skip-adventure-bonus'),
              onPressed: () => setState(() => bonusSkipped = true),
              child: const Text(
                'Maybe next time',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _rewardPreview({bool compact = false}) {
    final reward = adventureOutfitRewards[widget.index];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEED8AF)),
      ),
      child: Row(
        children: [
          if (compact)
            const Icon(Icons.card_giftcard_rounded, color: _gold, size: 30)
          else
            SizedBox(
              width: 82,
              height: 112,
              child: AvatarArt(
                avatar: widget.avatar
                    .select(reward.category, reward.item)
                    .select('Pose', 1),
                scene: false,
              ),
            ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compact
                      ? widget.rewardEarned
                            ? 'YOUR FRIENDSHIP TREASURE'
                            : 'A GIFT TO EARN'
                      : 'YOUR WARDROBE TREASURE',
                  style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: .9,
                    fontWeight: FontWeight.w900,
                    color: _gold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  reward.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  compact
                      ? widget.rewardEarned
                            ? 'Already yours. Play for a new keepsake!'
                            : 'Finish your adventure to wear it in the studio.'
                      : widget.rewardEarned
                      ? 'Already in your studio. Keep making lovely memories!'
                      : 'Collect your stamp to add this to your studio.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF806B58),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _finale() => Column(
    children: [
      _eyebrow(
        'FRIENDSHIP LOOKS LOVELY ON YOU',
        icon: Icons.workspace_premium_rounded,
      ),
      _heading(
        'Make it your kind of party!',
        'Choose a keepsake for your adventure stamp book.',
      ),
      const SizedBox(height: 20),
      _friendScene(),
      const SizedBox(height: 16),
      Text(
        theme.keepsakes[keepsake],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 23,
          color: _rose,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        round.success,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, height: 1.45),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < theme.keepsakes.length; i++)
            ChoiceChip(
              label: Text(theme.keepsakes[i]),
              selected: keepsake == i,
              selectedColor: _blush,
              onSelected: (_) => setState(() => keepsake = i),
            ),
        ],
      ),
      const SizedBox(height: 20),
      _rewardPreview(),
      const SizedBox(height: 16),
      if (round.bonus.completed) ...[
        const Text(
          '✨ Friendship sparkle earned',
          style: TextStyle(fontWeight: FontWeight.w800, color: _gold),
        ),
        const SizedBox(height: 10),
      ],
      Text(
        level < 2
            ? level + 1 > widget.availableLevel
                  ? 'Level ${level + 2} opens when you collect your stamp.'
                  : 'Try another story or level on your next adventure.'
            : 'All three levels explored! Try the other story next time.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          height: 1.45,
          color: Color(0xFF75606F),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const ValueKey('collect-adventure-stamp'),
          onPressed: () => Navigator.pop(
            context,
            AdventureResult(
              theme.keepsakes[keepsake],
              level: level,
              route: route,
              bonusCompleted: round.bonus.completed,
            ),
          ),
          icon: const Icon(Icons.workspace_premium_rounded),
          label: const Text('Collect my adventure stamp'),
        ),
      ),
    ],
  );
}

/// A small illustrated setting that grows with the child's actions.
class _FriendScenePainter extends CustomPainter {
  final int theme;
  final double progress, reaction;
  _FriendScenePainter(this.theme, this.progress, this.reaction);

  @override
  void paint(Canvas canvas, Size size) {
    final backgrounds = [
      const Color(0xFFEAF0DE),
      const Color(0xFFE0F0F3),
      const Color(0xFFFCE6DE),
      const Color(0xFFEAE0F3),
      const Color(0xFFE5ECE1),
      const Color(0xFFFFE8ED),
    ];
    final ground = [
      const Color(0xFFD4E4BC),
      const Color(0xFFF5E8C9),
      const Color(0xFFF3D0BD),
      const Color(0xFFD5C4E6),
      const Color(0xFFCAE0CF),
      const Color(0xFFECD5DF),
    ];
    canvas.drawRect(Offset.zero & size, Paint()..color = backgrounds[theme]);
    final horizon = Path()
      ..moveTo(0, size.height * .78)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .65,
        size.width,
        size.height * .8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(horizon, Paint()..color = ground[theme]);
    // Pearl lights and delicate gold sparkle keep every setting part of one world.
    for (var i = 0; i < 7; i++) {
      final x = size.width * (i + .5) / 7;
      final y = 65 + math.sin(i * 1.9) * 12;
      canvas.drawCircle(
        Offset(x, y),
        3.2,
        Paint()..color = Colors.white.withValues(alpha: .7),
      );
    }
    final count = 2 + (progress * 5).round();
    for (var i = 0; i < count; i++) {
      final x = 16.0 + (size.width - 32) * i / 6;
      final y = size.height - 12 - (i % 2) * 7;
      final center = Offset(x, y);
      final p = Paint()
        ..color = i.isEven ? const Color(0xFFD888A8) : const Color(0xFFEBC36B);
      if (theme == 0) {
        canvas.drawLine(
          center,
          center.translate(0, -13),
          Paint()
            ..color = const Color(0xFF79945E)
            ..strokeWidth = 2,
        );
        for (var petal = 0; petal < 5; petal++) {
          final angle = petal * math.pi * 2 / 5;
          canvas.drawCircle(
            center.translate(math.cos(angle) * 4, -15 + math.sin(angle) * 4),
            3.4,
            p,
          );
        }
        canvas.drawCircle(
          center.translate(0, -15),
          2.5,
          Paint()..color = const Color(0xFFFFF2B8),
        );
      } else {
        _sparkle(canvas, center, 4.0 + (i % 3), p);
      }
    }
    if (reaction > 0 && reaction < 1) {
      final fade = (1 - reaction).clamp(0.0, 1.0);
      for (var i = 0; i < 9; i++) {
        final x = size.width * (i + .5) / 9;
        final y = size.height * .7 - reaction * (40 + (i % 3) * 16);
        _sparkle(
          canvas,
          Offset(x, y),
          3.0 + (i % 2) * 2,
          Paint()..color = (i.isEven ? _rose : _gold).withValues(alpha: fade),
        );
      }
    }
  }

  void _sparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final shape = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx + radius * .25,
        center.dy - radius * .25,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + radius * .25,
        center.dy + radius * .25,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius * .25,
        center.dy + radius * .25,
        center.dx - radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - radius * .25,
        center.dy - radius * .25,
        center.dx,
        center.dy - radius,
      )
      ..close();
    canvas.drawPath(shape, paint);
  }

  @override
  bool shouldRepaint(covariant _FriendScenePainter oldDelegate) =>
      oldDelegate.theme != theme ||
      oldDelegate.progress != progress ||
      oldDelegate.reaction != reaction;
}
