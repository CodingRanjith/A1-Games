import 'package:flutter/widgets.dart';

/// Ads abstraction for future integration. No SDK in v1.
abstract class AdsService {
  Future<void> initialize();
  void showInterstitial();
  void showRewarded({VoidCallback? onReward});
  Widget banner();
}

class MockAdsService implements AdsService {
  @override
  Future<void> initialize() async {}

  @override
  void showInterstitial() {}

  @override
  void showRewarded({VoidCallback? onReward}) {}

  @override
  Widget banner() => const SizedBox.shrink();
}
