import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin wrapper over the Android-side helpers in `MainActivity.kt`. Every call
/// degrades gracefully where the native side doesn't exist (iOS, tests).
class NativeBridge {
  const NativeBridge();

  static const _channel = MethodChannel('com.pinbox.app/native');

  bool get _hasNative => !kIsWeb && Platform.isAndroid;

  /// Android's FLAG_SECURE: blocks screenshots/screen recording and blanks the
  /// app's thumbnail in the recents screen.
  Future<void> setSecure(bool secure) async {
    if (!_hasNative) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': secure});
    } on PlatformException {
      // Best effort: failing to toggle must never break the app.
    } on MissingPluginException {
      // No native handler (e.g. running under flutter_test).
    }
  }

  /// Copies [text], flagged so Android 13+ keeps it out of the clipboard preview.
  Future<void> copySensitive(String text) async {
    if (_hasNative) {
      try {
        await _channel.invokeMethod<void>('copySensitive', {'text': text});
        return;
      } on PlatformException {
        // fall through to the plain clipboard
      } on MissingPluginException {
        // fall through to the plain clipboard
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> clearClipboard() async {
    if (_hasNative) {
      try {
        await _channel.invokeMethod<void>('clearClipboard');
        return;
      } on PlatformException {
        // fall through
      } on MissingPluginException {
        // fall through
      }
    }
    await Clipboard.setData(const ClipboardData(text: ''));
  }
}
