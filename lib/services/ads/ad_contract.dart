import 'package:flutter/material.dart';

enum RewardOutcome { earned, cancelled, unavailable, saveFailed }

abstract class GameAds {
  String get unavailableMessage;
  Future<void> prepare();
  Future<void> prepareAppOpen();
  Future<void> showAppOpen(BuildContext context);
  Future<RewardOutcome> showRewarded(
    BuildContext context, {
    required String rewardLabel,
    required Future<bool> Function() onEarned,
  });
  Future<void> showInterstitial(BuildContext context);
  void dispose();
}

class DisabledAds implements GameAds {
  const DisabledAds(this.unavailableMessage);
  @override
  final String unavailableMessage;
  @override
  Future<void> prepare() async {}
  @override
  Future<void> prepareAppOpen() async {}
  @override
  Future<void> showAppOpen(BuildContext context) async {}
  @override
  Future<RewardOutcome> showRewarded(
    BuildContext context, {
    required String rewardLabel,
    required Future<bool> Function() onEarned,
  }) async => RewardOutcome.unavailable;
  @override
  Future<void> showInterstitial(BuildContext context) async {}
  @override
  void dispose() {}
}
