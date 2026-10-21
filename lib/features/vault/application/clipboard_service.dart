import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../settings/application/settings_controller.dart';

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Copies a secret and wipes it from the clipboard after the configured delay.
///
/// Dart timers can be paused while the app is in the background, so the deadline is
/// also checked when the app returns to the foreground ([clearIfDue]).
class ClipboardService {
  ClipboardService(this._ref);

  final Ref _ref;
  Timer? _timer;
  DateTime? _deadline;

  Future<void> copy(String secret) async {
    final bridge = _ref.read(nativeBridgeProvider);
    await bridge.copySensitive(secret);

    _timer?.cancel();
    final seconds = _ref.read(settingsProvider).clearClipboardSeconds;
    if (seconds <= 0) {
      _deadline = null;
      return;
    }
    _deadline = DateTime.now().add(Duration(seconds: seconds));
    _timer = Timer(Duration(seconds: seconds), _clear);
  }

  void clearIfDue() {
    final deadline = _deadline;
    if (deadline != null && !deadline.isAfter(DateTime.now())) _clear();
  }

  void _clear() {
    _timer?.cancel();
    _timer = null;
    _deadline = null;
    _ref.read(nativeBridgeProvider).clearClipboard();
  }

  void dispose() => _timer?.cancel();
}
