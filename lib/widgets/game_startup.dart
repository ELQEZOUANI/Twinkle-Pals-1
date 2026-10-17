import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_brand.dart';
import '../services/ads/ad_service.dart';
import '../services/game_store.dart';
import 'lovely_theme.dart';
import 'splash_screen.dart';

class GameStartup extends StatefulWidget {
  final Widget Function(GameStore store, GameAds ads) gameBuilder;
  final Future<GameStore> Function()? loadStore;
  final GameAds? ads;
  const GameStartup({
    super.key,
    required this.gameBuilder,
    this.loadStore,
    this.ads,
  });

  @override
  State<GameStartup> createState() => _GameStartupState();
}

class _GameStartupState extends State<GameStartup> {
  late final GameAds ads = widget.ads ?? createGameAds();
  GameStore? store;
  BuildContext? splashContext;
  bool ready = false, failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    setState(() => failed = false);
    // A slow/no-fill ad request must not keep the child on the splash screen.
    final adPreparation = ads
        .prepareAppOpen()
        .timeout(const Duration(seconds: 3), onTimeout: () {})
        .catchError((Object _) {});
    final welcome = Future<void>.delayed(const Duration(milliseconds: 1400));
    try {
      final loaded = await (widget.loadStore?.call() ?? _loadStore());
      if (!mounted) return;
      setState(() => store = loaded);
      await Future.wait([welcome, adPreparation]);
      if (!mounted) return;
      final state = WidgetsBinding.instance.lifecycleState;
      if (state == null || state == AppLifecycleState.resumed) {
        try {
          await ads.showAppOpen(splashContext!);
        } catch (_) {
          // A failed presentation never prevents entering the game.
        }
      }
      if (mounted) setState(() => ready = true);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<GameStore> _loadStore() async =>
      GameStore(await SharedPreferences.getInstance());

  @override
  void dispose() {
    // GameShell takes ownership once startup hands the service to the game.
    if (!ready) ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ready) return widget.gameBuilder(store!, ads);
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: lovelyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              MediaQuery.disableAnimationsOf(context) ||
              (store?.reducedMotion ?? false),
        ),
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          splashContext = context;
          return SplashScreen(onRetry: failed ? _start : null);
        },
      ),
    );
  }
}
