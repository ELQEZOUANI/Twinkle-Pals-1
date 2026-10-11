import 'package:flutter/material.dart';

import '../app_brand.dart';
import '../models/avatar.dart';
import '../services/game_store.dart';
import '../services/app_actions.dart';
import '../services/tracking_permission.dart';
import 'app_action_dialog.dart';
import 'lovely_theme.dart';
import 'parent_gate.dart';
import 'privacy_legal_page.dart';

class SettingsPage extends StatefulWidget {
  final GameStore store;
  final VoidCallback onShowGuide;
  final AppActions? actions;
  final TrackingPermission? trackingPermission;
  const SettingsPage({
    super.key,
    required this.store,
    required this.onShowGuide,
    this.actions,
    this.trackingPermission,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool saving = false;
  bool opening = false;
  late final actions = widget.actions ?? AppActions();
  late final trackingPermission =
      widget.trackingPermission ?? IosTrackingPermission();
  TrackingPermissionStatus trackingStatus =
      TrackingPermissionStatus.notDetermined;
  GameStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    trackingPermission.status().then((status) {
      if (mounted) setState(() => trackingStatus = status);
    });
  }

  Future<void> requestTrackingPermission() async {
    if (opening) return;
    setState(() => opening = true);
    try {
      if (!await showParentGate(context) || !mounted) return;
      final continueRequest =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ad privacy choice'),
              content: const Text(
                'Apple will ask whether this device may be tracked across other companies’ apps and websites. This choice is optional. Ads remain child-directed and non-personalized either way.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  key: const ValueKey('tracking-continue'),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ) ??
          false;
      if (!continueRequest || !mounted) return;
      final status = await trackingPermission.request();
      if (!mounted) return;
      setState(() => trackingStatus = status);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_trackingResult(status))));
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  String _trackingResult(TrackingPermissionStatus status) => switch (status) {
    TrackingPermissionStatus.authorized =>
      'Permission saved. Ads remain child-directed and non-personalized.',
    TrackingPermissionStatus.denied => 'Tracking permission is off.',
    TrackingPermissionStatus.restricted =>
      'Tracking is restricted by this device’s settings.',
    TrackingPermissionStatus.notDetermined =>
      'No tracking choice has been made yet.',
    TrackingPermissionStatus.unavailable =>
      'Tracking permission is not available on this device.',
  };

  String get _trackingSubtitle => switch (trackingStatus) {
    TrackingPermissionStatus.authorized => 'Allowed by a parent or guardian.',
    TrackingPermissionStatus.denied => 'Off. Child-directed ads still work.',
    TrackingPermissionStatus.restricted => 'Restricted by the device.',
    TrackingPermissionStatus.unavailable => 'Not available on this device.',
    TrackingPermissionStatus.notDetermined =>
      'Optional Apple permission for ad measurement.',
  };

  Future<void> grownUpAction({required bool sharing}) async {
    if (opening) return;
    setState(() => opening = true);
    try {
      if (!await showParentGate(context) || !mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AppActionDialog(actions: actions, sharing: sharing),
      );
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> openPrivacy() async {
    if (opening) return;
    final url = AppLinks.publishedUrl(actions.links.privacyUrl);
    if (url == null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => PrivacyLegalPage(actions: actions)),
      );
      return;
    }
    setState(() => opening = true);
    try {
      if (!await showParentGate(context) || !mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AppActionDialog(
          actions: actions,
          title: 'Privacy & legal',
          description:
              'Read the $appName privacy policy and terms on our Blogger page.',
          destinations: {'Privacy & legal': url},
        ),
      );
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> update(Future<bool> Function() save) async {
    setState(() => saving = true);
    final ok = await save();
    if (!mounted) return;
    setState(() => saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            store.error ?? 'Could not save this setting. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: cream,
        foregroundColor: ink,
        centerTitle: false,
        leading: IconButton(
          key: const ValueKey('settings-back'),
          tooltip: 'Back to game',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LovelyBackdrop(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('settings-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [blush, Color(0xFFFFF4DE)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: roseLine),
                      ),
                      child: const Row(
                        children: [
                          LovelyEmblem(size: 46),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Make yourself comfy',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Little settings for your lovely world.',
                                  style: TextStyle(fontSize: 12, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _section('Play your way', Icons.favorite_outline_rounded, [
                      SwitchListTile.adaptive(
                        key: const ValueKey('settings-sound'),
                        value: store.sound,
                        onChanged: saving
                            ? null
                            : (value) => update(() => store.setSound(value)),
                        title: const Text(
                          'Sound effects',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Pops, cheers, and little purrs.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                        activeThumbColor: purple,
                        secondary: Icon(
                          store.sound
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: purple,
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: roseLine,
                      ),
                      SwitchListTile.adaptive(
                        key: const ValueKey('settings-motion'),
                        value: store.reducedMotion,
                        onChanged: saving
                            ? null
                            : (value) =>
                                  update(() => store.setReducedMotion(value)),
                        title: const Text(
                          'Reduced motion',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Keep pals and celebrations still. Your device’s motion preferences are also respected.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                        activeThumbColor: purple,
                        secondary: const Icon(
                          Icons.accessibility_new_rounded,
                          color: purple,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    _section(
                      'Your little collection',
                      Icons.auto_awesome_rounded,
                      [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                          child: Column(
                            children: [
                              _progress(
                                'Saved pals',
                                '${store.saved.length}',
                                Icons.favorite_rounded,
                              ),
                              _progress(
                                'Adventure stars',
                                '${store.stars}/6',
                                Icons.star_rounded,
                              ),
                              _progress(
                                'Friends unlocked',
                                '${store.unlockedCharacters.length}/12',
                                Icons.people_alt_rounded,
                              ),
                              _progress(
                                'Adventures unlocked',
                                '${store.unlockedChallenges.length}/6',
                                Icons.explore_rounded,
                              ),
                              _progress(
                                'Outfit gifts',
                                '${store.adventureRewards.length}/6',
                                Icons.redeem_rounded,
                              ),
                              _progress(
                                'Friendship hearts',
                                '${store.friendHearts.values.fold<int>(0, (sum, hearts) => sum + hearts)}/36',
                                Icons.favorite_border_rounded,
                              ),
                              _progress(
                                'Bonus sparkles',
                                '${store.bonusStars}/36',
                                Icons.auto_awesome_rounded,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _section('A little help', Icons.help_outline_rounded, [
                      ListTile(
                        key: const ValueKey('settings-guide'),
                        leading: const Icon(
                          Icons.menu_book_rounded,
                          color: purple,
                        ),
                        title: const Text(
                          'How to play',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Outfits, stories, surprises, and gifts.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: widget.onShowGuide,
                      ),
                    ]),
                    const SizedBox(height: 18),
                    _section('For grown-ups', Icons.family_restroom_rounded, [
                      ListTile(
                        key: const ValueKey('settings-share'),
                        leading: const Icon(
                          Icons.ios_share_rounded,
                          color: purple,
                        ),
                        title: const Text(
                          'Share the app',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Send a little invitation.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: opening
                            ? null
                            : () => grownUpAction(sharing: true),
                      ),
                      ListTile(
                        key: const ValueKey('settings-rate'),
                        leading: const Icon(
                          Icons.star_outline_rounded,
                          color: purple,
                        ),
                        title: const Text(
                          'Rate the app',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Leave an optional, honest review.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: opening
                            ? null
                            : () => grownUpAction(sharing: false),
                      ),
                      ListTile(
                        key: const ValueKey('settings-privacy'),
                        leading: const Icon(
                          Icons.shield_outlined,
                          color: purple,
                        ),
                        title: const Text(
                          'Privacy & legal',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Read our published policy and terms.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: opening ? null : openPrivacy,
                      ),
                      ListTile(
                        key: const ValueKey('settings-tracking'),
                        leading: const Icon(
                          Icons.privacy_tip_outlined,
                          color: purple,
                        ),
                        title: const Text(
                          'Ad privacy choice',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          _trackingSubtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: opening ? null : requestTrackingPermission,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    const Text(
                      appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: purple,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Your pals, settings, and rewards are saved on this device. No account needed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF806373),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Material(
        color: pearl,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: roseLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Row(
                children: [
                  Icon(icon, color: purple, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...children,
          ],
        ),
      );

  Widget _progress(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: softGold, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: purple,
          ),
        ),
      ],
    ),
  );
}
