import 'package:av_core/av_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The platform's launch screen (UI_DESIGN_SYSTEM §5): Android 12 and
/// later show a blank system splash before the app's own animation.
abstract interface class LaunchScreen {
  /// Whether the system splash still covers the app.
  Future<bool> systemSplashVisible();

  /// Keeps [appearance] for the next launches, so that the system splash
  /// matches the app rather than the device's setting.
  Future<void> rememberAppearance(Appearance appearance);
}

final class SystemLaunchScreen implements LaunchScreen {
  const SystemLaunchScreen();

  static const _channel = MethodChannel('dev.avalon/launch');

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> systemSplashVisible() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('isSystemSplashVisible') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> rememberAppearance(Appearance appearance) async {
    if (!_android) return;
    try {
      await _channel.invokeMethod<void>('setAppearance', appearance.name);
    } on PlatformException {
      // Only the next launch's first moment is affected.
    } on MissingPluginException {
      // Not in this engine (tests, the background entry).
    }
  }
}
