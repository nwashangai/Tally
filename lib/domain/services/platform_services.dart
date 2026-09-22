/// Abstract port for monetization ads.
/// The core domain and inventory screens must never import ad SDK types directly.
abstract interface class AdService {
  /// Initializes the ad service with appropriate consent handling.
  Future<void> initialize();

  /// Returns true if ads may be shown in the current context.
  bool get canShowAds;
}

/// Abstract port for event analytics.
/// Must never receive sensitive inventory data or PII by default.
abstract interface class AnalyticsService {
  /// Tracks an app lifecycle or user behavior event.
  Future<void> track(
    String event, [
    Map<String, Object?> properties = const {},
  ]);
}

/// Null-safe no-op implementations used in development and testing.

/// No-op AdService — returns safely without any SDK initialization.
class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  Future<void> initialize() async {}

  @override
  bool get canShowAds => false;
}

/// No-op AnalyticsService — discards all events without transmission.
class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  Future<void> track(
    String event, [
    Map<String, Object?> properties = const {},
  ]) async {}
}
