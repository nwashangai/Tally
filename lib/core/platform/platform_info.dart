import 'package:flutter/foundation.dart';

/// Abstract port for inspecting platform environment capabilities.
abstract interface class PlatformInfo {
  bool get isWeb;
  bool get isMobile;
  bool get isDesktop;
  String get platformName;
}

/// Production implementation utilizing Flutter foundation properties.
class AppPlatformInfo implements PlatformInfo {
  const AppPlatformInfo();

  @override
  bool get isWeb => kIsWeb;

  @override
  bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows);

  @override
  String get platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
