import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:share_plus/share_plus.dart';

import 'app_brand.dart';
import 'models/avatar.dart';
import 'services/game_store.dart';
import 'services/avatar_export.dart';
import 'widgets/avatar_art.dart';
import 'widgets/picture_preview.dart';
import 'services/ads/ad_service.dart';
import 'models/adventure.dart';
import 'widgets/adventure_play.dart';
import 'widgets/lovely_theme.dart';
import 'widgets/settings_page.dart';
import 'widgets/game_startup.dart';
import 'widgets/ios_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    GameStartup(
      gameBuilder: (store, ads) => PocketPals(store: store, ads: ads),
    ),
  );
}

class PocketPals extends StatelessWidget {
  final GameStore store;
  final GameAds? ads;
  const PocketPals({super.key, required this.store, this.ads});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: appName,
    debugShowCheckedModeBanner: false,
    scrollBehavior: const MaterialScrollBehavior().copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
      },
      scrollbars: false,
    ),
    theme: lovelyTheme(),
    builder: (context, child) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              MediaQuery.disableAnimationsOf(context) || store.reducedMotion,
        ),
        child: child!,
      ),
    ),
    home: GameShell(store: store, ads: ads),
  );
}

const categoryIcons = <String, IconData>{
  'Hair': Icons.face_retouching_natural_rounded,
  'Face': Icons.sentiment_satisfied_alt_rounded,
  'Eyes': Icons.remove_red_eye_outlined,
  'Mouth': Icons.sentiment_very_satisfied_rounded,
  'Tops': Icons.checkroom_rounded,
  'Dresses': Icons.dry_cleaning_rounded,
  'Bottoms': Icons.accessibility_new_rounded,
  'Shoes': Icons.ice_skating_rounded,
  'Hats': Icons.pets_rounded,
  'Glasses': Icons.visibility_rounded,
  'Earrings': Icons.auto_awesome_rounded,
  'Bags': Icons.shopping_bag_outlined,
  'Scene': Icons.landscape_rounded,
  'Pose': Icons.waving_hand_rounded,
};

class GameShell extends StatefulWidget {
  final GameStore store;
  final GameAds? ads;
  const GameShell({super.key, required this.store, this.ads});
  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> with WidgetsBindingObserver {
  final studioScroll = ScrollController();
  final optionsScroll = ScrollController();
  int page = 0;
  Avatar avatar = characterPreset(0);
  String category = 'Hair';
  bool categoriesExpanded = false;
  int? editingIndex, challengeIndex;
  bool busy = false;
  AudioPlayer? audio;
  late final GameAds ads;
  DateTime? backgroundedAt;
  GameStore get store => widget.store;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ads = widget.ads ?? createGameAds();
    unawaited(ads.prepare());
    store.addListener(refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (store.error != null) toast(store.error!);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final leftAt = backgroundedAt;
      backgroundedAt = null;
      // Keep editing, mini-games, Settings and other routes uninterrupted.
      if (leftAt != null &&
          DateTime.now().difference(leftAt) >= const Duration(seconds: 30) &&
          page == 0 &&
          !busy &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        unawaited(showReturnAd());
      }
    }
  }

  Future<void> showReturnAd() async {
    setState(() => busy = true);
    try {
      await ads.showAppOpen(context);
    } catch (_) {
      // Offline or failed ads are skipped.
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void refresh() {
    if (!store.sound && audio != null) {
      unawaited(audio!.stop().catchError((Object _) {}));
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    store.removeListener(refresh);
    ads.dispose();
    studioScroll.dispose();
    optionsScroll.dispose();
    if (audio != null) unawaited(audio!.dispose());
    super.dispose();
  }

  Future<void> sound([bool success = false]) async {
    if (!store.sound) return;
    try {
      await (audio ??= AudioPlayer()).play(
        AssetSource(success ? 'sounds/success.wav' : 'sounds/pop.wav'),
        volume: .35,
      );
    } catch (_) {
      /* A missing audio device must never interrupt play. */
    }
  }

  Future<void> adventureSound(int index) async {
    if (!store.sound) return;
    const effects = ['bloom', 'sparkle', 'pop', 'cheer', 'sparkle', 'purr'];
    try {
      await (audio ??= AudioPlayer()).play(
        AssetSource('sounds/${effects[index]}.wav'),
        volume: .28,
      );
    } catch (_) {
      // Play continues when audio is unavailable.
    }
  }

  void toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void go(int index) {
    if (busy) return;
    setState(() => page = index);
    unawaited(sound());
  }

  Future<void> showSettings() async {
    if (busy) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(store: store, onShowGuide: showGuide),
      ),
    );
  }

  Future<void> showGuide() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('A little guide to $appBrand'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Pick your pal',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Luna and Milo are free. The other 10 friends each unlock permanently after one rewarded ad. Choose a locked friend, then choose Watch ad. Closing early does not unlock them. In the studio, the people button lets you pick another character.',
            ),
            SizedBox(height: 16),
            Text(
              '2. Make a look',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Tap Show categories to choose hair, eyes, mouth, expressions, clothing and accessories. The list folds away after you choose a category. Dresses replace your top and bottoms; choosing a top or bottoms switches back to separates. Scroll down to find colors. Expressions set a matching natural mouth. Choosing an eye style opens a dreamy expression. Remove sunglasses to see your eyes. Tap your pal to wave! Characters blink, sway, and bounce when you change their look. Motion pauses when your device requests reduced motion.',
            ),
            SizedBox(height: 16),
            Text(
              '3. Play a challenge',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Garden gathering is free. Each of the other five adventures unlocks permanently after one rewarded ad. First follow the three outfit clues. Choose a story path and help its friend. Little steps, Growing explorer and Star adventurer levels unlock as you finish each level. Then play the themed mini-game: find flowers, match ocean pairs, make snacks, copy dance moves, cross a treasure trail or care for a kitten. Choose a keepsake at the finale and collect your adventure stamp. Boards and sequences change on replay. There is no timer or lost progress for a wrong choice. A star and stamp are saved before the completion ad break. A surprise task can earn a bonus sparkle; you can also skip it. Each new story-and-level combination earns a friendship heart. Replays keep your latest keepsake without awarding duplicate stars.',
            ),
            SizedBox(height: 16),
            Text(
              '4. Unlock surprises',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Each different challenge earns one star. Two stars unlock the space helmet, four unlock the crown, and six unlock the magic wand. Finishing each adventure also earns a special wearable gift. Find all six in your gift box on the Challenges page and tap Wear it. You can replay to explore both story paths and all three levels.',
            ),
            SizedBox(height: 16),
            Text(
              '5. Keep your favorites',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Save pal keeps your named look in My pals. Style edits that saved look; Save pal updates it. Picture makes an image of your character and scene.',
            ),
            SizedBox(height: 16),
            Text(
              '6. Try something new',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Surprise me makes a random outfit using your unlocked items. None removes an accessory. The speaker button turns sounds on or off.',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Let’s play'),
        ),
      ],
    ),
  );

  Future<bool> ensureCharacter(int index) async {
    if (store.canUseCharacter(index)) return true;
    final earned = await ensureRewardUnlock(
      label: names[index],
      kind: 'character',
      artwork: SizedBox(
        height: 160,
        width: 120,
        child: AvatarArt(avatar: characterPreset(index), animate: false),
      ),
      onEarned: () => store.unlockCharacter(index),
    );
    return earned && store.canUseCharacter(index);
  }

  Future<bool> ensureChallenge(int index) async {
    if (store.canPlayChallenge(index)) return true;
    final challenge = challenges[index];
    final earned = await ensureRewardUnlock(
      label: challenge.title,
      kind: 'challenge',
      artwork: Padding(
        padding: const EdgeInsets.all(20),
        child: Icon(challenge.icon, size: 80, color: challenge.color),
      ),
      onEarned: () => store.unlockChallenge(index),
    );
    return earned && store.canPlayChallenge(index);
  }

  Future<void> startChallenge(int index) async {
    if (busy || !await ensureChallenge(index) || !mounted) return;
    setState(() {
      challengeIndex = index;
      page = 1;
      category = challenges[index].requirements.keys.first;
    });
    unawaited(sound());
  }

  Future<bool> ensureRewardUnlock({
    required String label,
    required String kind,
    required Widget artwork,
    required Future<bool> Function() onEarned,
  }) async {
    if (busy) return false;
    setState(() => busy = true);
    try {
      final watch = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unlock $label'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                artwork,
                const SizedBox(height: 14),
                Text(
                  'Watch one rewarded ad to unlock $label permanently on this device.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'You can close the ad early. The $kind stays locked until the reward is earned.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton.icon(
              key: const ValueKey('watch-rewarded-ad'),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.ondemand_video, size: 18),
              label: const Text('Watch ad'),
            ),
          ],
        ),
      );
      if (watch != true || !mounted) return false;
      toast('Loading rewarded ad…');
      final outcome = await ads.showRewarded(
        context,
        rewardLabel: label,
        onEarned: onEarned,
      );
      if (!mounted) return false;
      switch (outcome) {
        case RewardOutcome.earned:
          toast('$label is unlocked!');
          unawaited(sound(true));
          return true;
        case RewardOutcome.cancelled:
          toast('Ad closed. $label is still locked.');
        case RewardOutcome.unavailable:
          toast(ads.unavailableMessage);
        case RewardOutcome.saveFailed:
          toast(
            store.error ?? 'The unlock could not be saved. Please try again.',
          );
      }
      return false;
    } catch (_) {
      toast(ads.unavailableMessage);
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create(int index) async {
    if (busy || !await ensureCharacter(index) || !mounted) return;
    setState(() {
      avatar = characterPreset(index);
      editingIndex = null;
      challengeIndex = null;
      page = 1;
      category = 'Hair';
    });
    unawaited(sound());
  }

  void select(String key, int value) {
    if (isLocked(key, value, store.stars, store.adventureRewards)) {
      final reward = adventureRewardForItem(key, value);
      if (reward != null) {
        toast(
          'Finish ${challenges[reward].title} to earn ${adventureOutfitRewards[reward].label}.',
        );
        return;
      }
      final needed = key == 'Bags'
          ? 6
          : value == 5
          ? 2
          : 4;
      toast('Complete $needed different challenges to unlock this surprise!');
      return;
    }
    setState(() => avatar = avatar.select(key, value));
    unawaited(sound());
  }

  void wearAdventureGift(int index) {
    if (busy || !store.adventureRewards.contains(index)) return;
    final gift = adventureOutfitRewards[index];
    setState(() {
      if (!store.canUseCharacter(avatar.character)) {
        avatar = characterPreset(0);
        editingIndex = null;
      }
      avatar = avatar.select(gift.category, gift.item);
      category = gift.category;
      challengeIndex = null;
      page = 1;
    });
    unawaited(sound(true));
  }

  Future<void> saveAvatar() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => PalNameDialog(initialName: avatar.name),
    );
    if (name == null || !mounted) return;
    setState(() => busy = true);
    final updated = avatar.copyWith(name: name);
    final ok = await store.save(updated, index: editingIndex);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (ok) {
        avatar = updated;
        editingIndex ??= store.saved.length - 1;
      }
    });
    toast(ok ? '$name is saved in My pals!' : store.error!);
    if (ok) unawaited(sound(true));
  }

  Future<void> exportAvatar(BuildContext buttonContext) async {
    final snapshot = avatar;
    setState(() => busy = true);
    try {
      final data = await renderAvatarPng(snapshot);
      if (!mounted) return;
      setState(() => busy = false);
      await showDialog<void>(
        context: context,
        builder: (context) => PicturePreview(
          name: snapshot.name,
          bytes: data,
          onSave: (originContext) async {
            try {
              if (!originContext.mounted) return;
              final box = originContext.findRenderObject()! as RenderBox;
              final result = await SharePlus.instance.share(
                ShareParams(
                  files: [XFile.fromData(data, mimeType: 'image/png')],
                  fileNameOverrides: ['pocket-pal.png'],
                  title: '${snapshot.name} · $appName',
                  sharePositionOrigin:
                      box.localToGlobal(Offset.zero) & box.size,
                ),
              );
              if (result.status == ShareResultStatus.success) {
                toast('Your pal is ready to share!');
              }
            } catch (_) {
              toast('Could not save the picture. Please try again.');
            }
          },
        ),
      );
    } catch (_) {
      toast('Could not create the picture. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> finishChallenge() async {
    if (busy || challengeIndex == null) return;
    final index = challengeIndex!;
    if (!store.canPlayChallenge(index)) {
      toast('Unlock this challenge before playing it.');
      return;
    }
    if (!challenges[index].matches(avatar)) {
      toast('Follow the three style clues to finish this challenge.');
      return;
    }
    final wasDone = store.completed.contains(index);
    setState(() => busy = true);
    final result = await showDialog<AdventureResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdventurePlay(
        index: index,
        avatar: avatar,
        initialLevel: 0,
        availableLevel: (store.adventureLevels[index] ?? 0).clamp(0, 2),
        rewardEarned: store.adventureRewards.contains(index),
        onGoodChoice: () => unawaited(adventureSound(index)),
      ),
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => busy = false);
      return;
    }
    final hadReward = store.adventureRewards.contains(index);
    final ok = await store.complete(
      index,
      keepsake: result.keepsake,
      level: result.level,
      route: result.route,
      bonusCompleted: result.bonusCompleted,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => busy = false);
      toast(store.error!);
      return;
    }
    unawaited(sound(true));
    final destination = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You did it! ✨'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                color: const Color(0xFFF1B84B),
                size: 76,
              ),
              const SizedBox(height: 16),
              Text(
                'Adventure stamp: ${result.keepsake}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: purple,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                wasDone
                    ? 'Another wonderful look! You already earned this challenge’s star.'
                    : 'A new star for your collection! You have ${store.stars} of 6 stars.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${hadReward ? 'Your lovely gift' : 'New outfit gift'}: ${adventureOutfitRewards[index].label}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: purple,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${store.friendHearts[index] ?? 0}/6 friendship hearts · ${store.adventureLevels[index] ?? 0}/3 levels complete',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              if (result.bonusCompleted)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'A bonus sparkle for your collection! ✨',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!wasDone && [2, 4, 6].contains(store.stars))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Surprise unlocked: ${store.stars == 2
                        ? 'Space helmet'
                        : store.stars == 4
                        ? 'Royal crown'
                        : 'Magic wand'}!',
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'An ad break may follow. Your progress is saved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 2),
            child: const Text('More challenges'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text('Keep styling'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 3),
            icon: const Icon(Icons.checkroom_rounded),
            label: const Text('Wear my gift'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    try {
      if (destination != null) await ads.showInterstitial(context);
    } catch (_) {
      // Mission completion is independent of ad availability.
    } finally {
      if (mounted) {
        setState(() => busy = false);
        if (destination == 3) {
          wearAdventureGift(index);
        } else if (destination != null) {
          go(destination);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = IosLayout.of(context);
    return Scaffold(
      body: LovelyBackdrop(
        child: SafeArea(
          child: Column(
            key: ValueKey(layout.isIPad ? 'ipad-layout' : 'iphone-layout'),
            children: [
              header(layout.isIPad),
              Expanded(
                child: switch (page) {
                  0 => home(),
                  1 => editor(),
                  2 => challengePage(),
                  _ => gallery(),
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: pearl,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: NavigationBar(
              key: const ValueKey('touch-navigation'),
              backgroundColor: pearl,
              selectedIndex: page,
              height: 72,
              indicatorColor: const Color(0xFFF2DCE5),
              onDestinationSelected: go,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.cottage_outlined),
                  selectedIcon: Icon(Icons.cottage_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Studio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events),
                  label: 'Challenges',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'My pals',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget header(bool iPad) => Padding(
    padding: EdgeInsets.symmetric(horizontal: iPad ? 24 : 14, vertical: 12),
    child: Row(
      children: [
        const LovelyEmblem(size: 29),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            label: appName,
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      appBrand,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: iPad ? 22 : 18,
                        letterSpacing: -.5,
                      ),
                    ),
                    const Text(appSubtitle, style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFAEDCD),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 19,
                color: Color(0xFF987039),
              ),
              const SizedBox(width: 4),
              Text(
                '${store.stars}/6',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Settings',
          key: const ValueKey('open-settings'),
          onPressed: busy ? null : showSettings,
          icon: const Icon(Icons.settings_outlined, size: 22),
        ),
        IconButton(
          tooltip: store.sound ? 'Mute sounds' : 'Enable sounds',
          onPressed: () => store.toggleSound(),
          icon: Icon(
            store.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 22,
          ),
        ),
      ],
    ),
  );

  Widget home() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1056),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    IosLayout.of(context).isIPad && constraints.maxWidth > 660;
                final text = Padding(
                  padding: EdgeInsets.all(wide ? 32 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Pill(
                        'A LITTLE WORLD OF WONDER',
                        color: Color(0xFFF4E3BC),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'A little sparkle.\nA world of you.',
                        style: TextStyle(
                          fontSize: wide ? 43 : 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.8,
                          height: 1.06,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Dress up, make friends, and follow a little magic.\nYour loveliest adventures start here.',
                        style: TextStyle(fontSize: 14, height: 1.7),
                      ),
                      const SizedBox(height: 23),
                      FilledButton.icon(
                        onPressed: () => create(0),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Let’s create'),
                      ),
                    ],
                  ),
                );
                final art = SizedBox(
                  height: wide ? 330 : 210,
                  child: LayoutBuilder(
                    builder: (context, size) => Stack(
                      children: [
                        Positioned(
                          left: size.maxWidth * .04,
                          top: wide ? 64 : 16,
                          width: size.maxWidth * .35,
                          height: wide ? 258 : 180,
                          child: Transform.rotate(
                            angle: -.12,
                            child: AvatarArt(
                              avatar: characterPreset(2).select('Bags', 5),
                              scene: false,
                            ),
                          ),
                        ),
                        Positioned(
                          left: size.maxWidth * .34,
                          top: wide ? 14 : -9,
                          width: size.maxWidth * .38,
                          height: wide ? 298 : 215,
                          child: AvatarArt(
                            avatar: characterPreset(0)
                                .copyWith(color: 1)
                                .select('Dresses', 4)
                                .select('Hats', 7)
                                .select('Pose', 1),
                            scene: false,
                          ),
                        ),
                        Positioned(
                          left: size.maxWidth * .66,
                          top: wide ? 68 : 21,
                          width: size.maxWidth * .32,
                          height: wide ? 253 : 176,
                          child: Transform.rotate(
                            angle: .12,
                            child: AvatarArt(
                              avatar: characterPreset(8),
                              scene: false,
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 22,
                          top: 12,
                          child: Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFD5A456),
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF9DDE7),
                        Color(0xFFFFF5EA),
                        Color(0xFFF6E7F1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE4C4AF)),
                    boxShadow: [
                      BoxShadow(
                        color: purple.withValues(alpha: .06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(child: text),
                            Expanded(child: art),
                          ],
                        )
                      : Column(children: [text, art]),
                );
              },
            ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                const Pill('12 original pals', icon: Icons.face_rounded),
                const Pill(
                  'Lovely little outfits',
                  icon: Icons.checkroom_rounded,
                ),
                Pill(
                  '6 story adventures',
                  icon: Icons.emoji_events_outlined,
                  onTap: () => go(2),
                ),
              ],
            ),
            const SizedBox(height: 30),
            titleRow(
              'Meet your new friends',
              'Luna & Milo are free. Unlock 10 more with rewarded ads.',
            ),
            const SizedBox(height: 8),
            Text(
              '${store.unlockedCharacters.length} / 12 characters unlocked',
              style: const TextStyle(
                color: purple,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final layout = IosLayout.of(context);
                final columns = layout.cardColumns(
                  layout.characterColumns,
                  constraints.maxWidth,
                );
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: .73,
                  ),
                  itemBuilder: (context, i) => characterCard(i),
                );
              },
            ),
            const SizedBox(height: 26),
            Material(
              color: const Color(0xFFF6E4E9),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () => go(2),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: purple,
                        size: 35,
                      ),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Little adventures. Lovely surprises.',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Collect stars to unlock a helmet, crown and magic wand.',
                              style: TextStyle(fontSize: 12, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: purple),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget titleRow(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF806373), fontSize: 13),
      ),
    ],
  );

  Widget characterCard(int i) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      key: ValueKey('character-$i'),
      onTap: busy ? null : () => create(i),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.expand(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AvatarArt(avatar: characterPreset(i)),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            store.canUseCharacter(i)
                                ? Icons.check_circle_outline
                                : Icons.lock_rounded,
                            color: purple,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              names[i],
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              personalities[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF806373), fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              store.canUseCharacter(i)
                  ? (i < 2 ? 'Free to play' : 'Unlocked')
                  : 'Watch ad to unlock',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: purple,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    ),
  );

  Widget editor() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = IosLayout.of(context).sideBySideStudio(constraints);
      final stage = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: titleRow(
                    avatar.name,
                    challengeIndex == null
                        ? 'A little change. A whole new you.'
                        : challenges[challengeIndex!].title,
                  ),
                ),
                IconButton(
                  tooltip: 'Choose another character',
                  onPressed: busy ? null : chooseCharacter,
                  icon: const Icon(Icons.people_alt_outlined),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AspectRatio(
                  aspectRatio: .75,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: RepaintBoundary(
                      child: AvatarArt(avatar: avatar, interactive: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!MediaQuery.disableAnimationsOf(context))
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Tap your pal to wave',
                style: TextStyle(fontSize: 11, color: Color(0xFF806373)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () {
                          setState(
                            () => avatar = randomize(
                              avatar,
                              store.stars,
                              null,
                              store.adventureRewards,
                            ),
                          );
                          unawaited(sound());
                        },
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: const Text('Surprise me'),
                ),
                Builder(
                  builder: (buttonContext) => OutlinedButton.icon(
                    onPressed: busy ? null : () => exportAvatar(buttonContext),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Picture'),
                  ),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : saveAvatar,
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  label: const Text('Save pal'),
                ),
              ],
            ),
          ),
        ],
      );
      if (wide) {
        return Padding(
          key: const ValueKey('ipad-studio'),
          padding: const EdgeInsets.fromLTRB(12, 0, 24, 20),
          child: Row(
            children: [
              Expanded(flex: 5, child: stage),
              const SizedBox(width: 16),
              Expanded(flex: 6, child: customizationPanel()),
            ],
          ),
        );
      }
      return Scrollbar(
        key: const ValueKey('iphone-studio'),
        controller: studioScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          key: const ValueKey('studio-scroll'),
          controller: studioScroll,
          primary: false,
          child: Column(
            children: [
              SizedBox(
                height: (constraints.maxHeight * .65).clamp(350.0, 440.0),
                child: stage,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: customizationPanel(scrollable: false),
              ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> chooseCharacter() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: GridView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisExtent: 185,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, i) => InkWell(
            onTap: () => Navigator.pop(context, i),
            child: Column(
              children: [
                Expanded(child: AvatarArt(avatar: characterPreset(i))),
                Text(names[i]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      store.canUseCharacter(i)
                          ? Icons.check_circle_outline
                          : Icons.lock_rounded,
                      size: 13,
                      color: purple,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        store.canUseCharacter(i) ? 'Ready to play' : 'Watch ad',
                        style: const TextStyle(fontSize: 10, color: purple),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (index != null && mounted && await ensureCharacter(index) && mounted) {
      setState(() {
        avatar = characterPreset(index);
        editingIndex = null;
      });
    }
  }

  Widget customizationPanel({bool scrollable = true}) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (challengeIndex != null) challengeClues(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: TextButton(
            key: const ValueKey('categories-toggle'),
            onPressed: () =>
                setState(() => categoriesExpanded = !categoriesExpanded),
            child: Row(
              children: [
                Icon(categoryIcons[category], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  categoriesExpanded ? 'Hide categories' : 'Show categories',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(
                  categoriesExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
          ),
        ),
        if (categoriesExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in categories.keys)
                  ChoiceChip(
                    key: ValueKey('category-$key'),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcons[key], size: 17),
                        const SizedBox(width: 5),
                        Text(key),
                      ],
                    ),
                    selected: category == key,
                    showCheckmark: false,
                    selectedColor: const Color(0xFFF7E3E9),
                    side: BorderSide(
                      color: category == key ? purple : const Color(0xFFF1DDE4),
                    ),
                    onSelected: (_) => setState(() {
                      category = key;
                      categoriesExpanded = false;
                    }),
                  ),
              ],
            ),
          ),
        const Divider(height: 1, color: Color(0xFFF1DDE4)),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose ${category.toLowerCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    '${categories[category]!.length} options',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF806373),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (category == 'Eyes' && avatar.item('Glasses') == 2) ...[
                const Text(
                  'Sunglasses are hiding your eyes.',
                  style: TextStyle(fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: () => select('Glasses', 0),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('Take off sunglasses'),
                ),
              ],
              if (category == 'Eyes' &&
                  (avatar.item('Face') == 3 || avatar.item('Eyes') == 3)) ...[
                const Text(
                  'Closed eyes do not show eye color. Choose an open-eye style to see it.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
              LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories[category]!.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 410 ? 4 : 3,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                    childAspectRatio: .85,
                  ),
                  itemBuilder: (context, index) {
                    final selected = avatar.item(category) == index;
                    final locked = isLocked(
                      category,
                      index,
                      store.stars,
                      store.adventureRewards,
                    );
                    return Semantics(
                      selected: selected,
                      button: true,
                      label:
                          '${categories[category]![index]}${locked ? ', locked' : ''}',
                      child: Material(
                        color: selected
                            ? const Color(0xFFF8E5ED)
                            : const Color(0xFFFFFBFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: selected ? purple : const Color(0xFFEBD9DF),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('option-$category-$index'),
                          onTap: () => select(category, index),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: Opacity(
                                      opacity: locked ? .35 : 1,
                                      child: itemPreview(index),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      3,
                                      2,
                                      3,
                                      8,
                                    ),
                                    child: Text(
                                      categories[category]![index],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: selected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (locked)
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(
                                    Icons.lock_rounded,
                                    size: 17,
                                    color: purple,
                                  ),
                                ),
                              if (selected)
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 17,
                                    color: purple,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              if (category == 'Hair') ...[
                const Text(
                  'Hair color',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 10),
                colorPicker(
                  hairColors,
                  avatar.hairColor,
                  (i) => setState(() => avatar = avatar.copyWith(hairColor: i)),
                ),
                const SizedBox(height: 20),
              ],
              if (category == 'Eyes') ...[
                const Text(
                  'Eye color',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 10),
                colorPicker(
                  palette,
                  avatar.eyeColor,
                  (i) => setState(() => avatar = avatar.copyWith(eyeColor: i)),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'Outfit color',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 10),
              colorPicker(
                palette,
                avatar.color,
                (i) => setState(() => avatar = avatar.copyWith(color: i)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Skin tone',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 10),
              colorPicker(
                skinColors,
                avatar.skin,
                (i) => setState(() => avatar = avatar.copyWith(skin: i)),
              ),
            ],
          ),
        ),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1DDE4)),
      ),
      child: scrollable
          ? Scrollbar(
              controller: optionsScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                key: const ValueKey('options-scroll'),
                controller: optionsScroll,
                primary: false,
                child: content,
              ),
            )
          : content,
    );
  }

  Widget itemPreview(int index) {
    var preview = avatar.select(category, index);
    if (category == 'Eyes' || category == 'Face') {
      preview = preview.select('Glasses', 0);
    }
    if (category == 'Scene' || category == 'Pose') {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: AspectRatio(
            aspectRatio: .75,
            child: AvatarArt(avatar: preview, animate: false),
          ),
        ),
      );
    }
    if (['Hats', 'Glasses', 'Earrings', 'Bags', 'Dresses'].contains(category) &&
        index == 0) {
      return const Center(
        child: Icon(Icons.block_rounded, color: Color(0xFFB3A8C4), size: 28),
      );
    }
    final head = [
      'Hair',
      'Face',
      'Eyes',
      'Mouth',
      'Hats',
      'Glasses',
      'Earrings',
    ].contains(category);
    return LayoutBuilder(
      builder: (context, constraints) {
        final region = head
            ? const Rect.fromLTWH(25, 15, 190, 190)
            : category == 'Shoes'
            ? const Rect.fromLTWH(76, 260, 83, 40)
            : category == 'Bottoms'
            ? const Rect.fromLTWH(72, 223, 93, 55)
            : category == 'Dresses'
            ? const Rect.fromLTWH(70, 187, 102, 86)
            : category == 'Bags'
            ? const Rect.fromLTWH(68, 181, 149, 91)
            : const Rect.fromLTWH(70, 187, 102, 57);
        final scale =
            math.min(
              constraints.maxWidth / region.width,
              constraints.maxHeight / region.height,
            ) *
            .90;
        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                top:
                    (constraints.maxHeight - region.height * scale) / 2 -
                    region.top * scale,
                left:
                    (constraints.maxWidth - region.width * scale) / 2 -
                    region.left * scale,
                width: 240 * scale,
                height: 320 * scale,
                child: AvatarArt(avatar: preview, scene: false, animate: false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget colorPicker(
    List<Color> colors,
    int selected,
    ValueChanged<int> onChange,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (int i = 0; i < colors.length; i++)
        Semantics(
          label: 'Color ${i + 1}',
          selected: i == selected,
          button: true,
          child: InkWell(
            onTap: () {
              onChange(i);
              unawaited(sound());
            },
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 43,
              height: 43,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: i == selected ? purple : const Color(0xFFEBD9DF),
                  width: i == selected ? 2 : 1,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                ),
                child: i == selected
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: colors[i].computeLuminance() > .5
                            ? ink
                            : Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        ),
    ],
  );

  Widget challengeClues() {
    final challenge = challenges[challengeIndex!];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF0DE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFF987039),
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Leave challenge',
                onPressed: () => setState(() => challengeIndex = null),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          Text(
            adventures[challengeIndex!].story,
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '1 · Style your pal   →   2 · ${adventures[challengeIndex!].gameTitle}   →   3 · Celebrate',
            style: const TextStyle(
              fontSize: 10,
              color: purple,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 5,
            children: [
              for (final entry in challenge.requirements.entries)
                ActionChip(
                  avatar: Icon(
                    avatar.item(entry.key) == entry.value
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                    color: avatar.item(entry.key) == entry.value
                        ? const Color(0xFF529582)
                        : ink,
                  ),
                  label: Text(
                    categories[entry.key]![entry.value],
                    style: const TextStyle(fontSize: 10),
                  ),
                  onPressed: () => setState(() => category = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : finishChallenge,
              child: Text(
                challenge.matches(avatar)
                    ? 'Start mini-game ✨'
                    : 'Follow the 3 clues',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget challengePage() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleRow(
              'A tiny adventure in every outfit.',
              'Style, play, celebrate! First adventure free; unlock 5 more with rewarded ads.',
            ),
            const SizedBox(height: 24),
            adventureStampBook(),
            const SizedBox(height: 24),
            adventureGiftBox(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFF7E3E9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Your surprise collection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${store.stars} / 6 stars',
                        style: const TextStyle(
                          color: purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: LinearProgressIndicator(
                      value: store.stars / 6,
                      minHeight: 8,
                      color: purple,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 15,
                    runSpacing: 10,
                    children: [
                      Pill('${store.stars >= 2 ? '✓' : '2★'} Space helmet'),
                      Pill('${store.stars >= 4 ? '✓' : '4★'} Royal crown'),
                      Pill('${store.stars >= 6 ? '✓' : '6★'} Magic wand'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = IosLayout.of(context).adventureColumns;
                final width =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (var i = 0; i < challenges.length; i++)
                      SizedBox(width: width, child: adventureCard(i)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );

  Widget adventureCard(int i) {
    final challenge = challenges[i];
    final done = store.completed.contains(i);
    final unlocked = store.canPlayChallenge(i);
    return Container(
      key: ValueKey('challenge-$i'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBD9DF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: challenge.color.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(challenge.icon, color: challenge.color, size: 27),
              ),
              const Spacer(),
              if (done)
                const Icon(Icons.stars_rounded, color: Color(0xFF987039)),
              if (!unlocked)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.lock_rounded, color: purple, size: 23),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            challenge.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 7),
          Text(
            adventures[i].story,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF806373),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.sports_esports_rounded,
                color: challenge.color,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  adventures[i].gameTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            '2 story paths · 3 gentle levels',
            style: TextStyle(color: Color(0xFF806373), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Pill(
                '${store.adventureLevels[i] ?? 0}/3 levels',
                icon: Icons.auto_awesome_rounded,
                color: cream,
              ),
              Pill(
                '${store.friendHearts[i] ?? 0}/6 hearts',
                icon: Icons.favorite_rounded,
                color: cream,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lovely gift: ${adventureOutfitRewards[i].label}',
            style: const TextStyle(
              color: purple,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            unlocked
                ? (i == 0 ? 'Free challenge' : 'Unlocked')
                : 'One rewarded ad · permanent unlock',
            style: const TextStyle(
              color: purple,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : () => startChallenge(i),
              child: Text(
                !unlocked
                    ? 'Watch ad to unlock'
                    : done
                    ? 'Play again'
                    : 'Let’s try it',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget adventureStampBook() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0D1),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Color(0xFF987039)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Your adventure stamp book',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${store.adventureKeepsakes.length}/6',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'A little memory from every adventure. Explore both stories, grow your friendships, and collect surprise sparkles.',
          style: TextStyle(fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < challenges.length; i++)
              Tooltip(
                message:
                    store.adventureKeepsakes[i] ??
                    '${challenges[i].title}: stamp waiting',
                child: Chip(
                  avatar: Icon(
                    store.adventureKeepsakes.containsKey(i)
                        ? challenges[i].icon
                        : Icons.auto_awesome_outlined,
                    color: store.adventureKeepsakes.containsKey(i)
                        ? challenges[i].color
                        : const Color(0xFF9C91A6),
                    size: 18,
                  ),
                  label: Text(
                    store.adventureKeepsakes[i] ?? challenges[i].title,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Pill(
              '${store.friendHearts.values.fold<int>(0, (sum, value) => sum + value)} friendship hearts',
              icon: Icons.favorite_rounded,
            ),
            Pill(
              '${store.bonusStars} bonus sparkles',
              icon: Icons.auto_awesome_rounded,
            ),
          ],
        ),
      ],
    ),
  );

  Widget adventureGiftBox() => Container(
    decoration: BoxDecoration(
      color: pearl,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: softGold.withValues(alpha: .45)),
    ),
    child: ExpansionTile(
      key: const ValueKey('adventure-gift-box'),
      leading: const Icon(Icons.redeem_rounded, color: purple),
      title: const Text(
        'Your lovely gift box',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      subtitle: Text(
        '${store.adventureRewards.length}/6 outfits earned by playing',
        style: const TextStyle(fontSize: 12),
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 760
                ? 3
                : constraints.maxWidth > 460
                ? 2
                : 1;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < adventureOutfitRewards.length; i++)
                  SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: roseLine),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 66,
                            height: 92,
                            child: AvatarArt(
                              avatar: characterPreset(0)
                                  .select(
                                    adventureOutfitRewards[i].category,
                                    adventureOutfitRewards[i].item,
                                  )
                                  .select('Pose', 1),
                              scene: false,
                              animate: false,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adventureOutfitRewards[i].label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  challenges[i].title,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF806373),
                                  ),
                                ),
                                TextButton.icon(
                                  key: ValueKey('wear-gift-$i'),
                                  onPressed: busy
                                      ? null
                                      : () => store.adventureRewards.contains(i)
                                            ? wearAdventureGift(i)
                                            : startChallenge(i),
                                  icon: Icon(
                                    store.adventureRewards.contains(i)
                                        ? Icons.checkroom_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    store.adventureRewards.contains(i)
                                        ? 'Wear it'
                                        : 'Play for gift',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget gallery() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1056),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleRow(
              'Your little circle of friends.',
              '${store.saved.length} saved pals · All the looks you love, in one place.',
            ),
            const SizedBox(height: 24),
            if (store.saved.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(38),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7E3E9),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.favorite_rounded, color: purple, size: 52),
                    const SizedBox(height: 20),
                    const Text(
                      'Your first pal is waiting to meet you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Create a look and tap Save pal to keep it here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => create(0),
                      child: const Text('Create my first pal'),
                    ),
                  ],
                ),
              ),
            if (store.saved.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: store.saved.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: IosLayout.of(context).cardColumns(
                      IosLayout.of(context).galleryColumns,
                      constraints.maxWidth,
                    ),
                    childAspectRatio: .64,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, i) {
                    final pal = store.saved[i];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: SizedBox.expand(
                                child: AvatarArt(avatar: pal),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            pal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: busy
                                    ? null
                                    : () async {
                                        if (!await ensureCharacter(
                                              pal.character,
                                            ) ||
                                            !mounted) {
                                          return;
                                        }
                                        setState(() {
                                          avatar = pal;
                                          editingIndex = i;
                                          challengeIndex = null;
                                          page = 1;
                                        });
                                      },
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Style'),
                              ),
                              IconButton(
                                tooltip: 'Delete ${pal.name}',
                                onPressed: busy ? null : () => deletePal(i),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
                                  color: Color(0xFFAD8C98),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> deletePal(int index) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${store.saved[index].name}?'),
        content: const Text(
          'This saved look will be removed from your gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep pal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    final ok = await store.delete(index);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (ok && editingIndex != null) {
        if (editingIndex == index) {
          editingIndex = null;
        } else if (editingIndex! > index) {
          editingIndex = editingIndex! - 1;
        }
      }
    });
    if (!ok) {
      toast(store.error!);
    }
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;
  const Pill(
    this.text, {
    super.key,
    this.color = Colors.white,
    this.icon,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: purple),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PalNameDialog extends StatefulWidget {
  final String initialName;
  const PalNameDialog({super.key, required this.initialName});
  @override
  State<PalNameDialog> createState() => _PalNameDialogState();
}

class _PalNameDialogState extends State<PalNameDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialName,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    if (controller.text.trim().isNotEmpty) {
      Navigator.pop(context, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Give your pal a name'),
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLength: 24,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Name'),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Keep playing'),
      ),
      FilledButton(
        onPressed: controller.text.trim().isEmpty ? null : submit,
        child: const Text('Save pal'),
      ),
    ],
  );
}
