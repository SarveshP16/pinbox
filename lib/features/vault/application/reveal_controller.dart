import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lock/application/lock_controller.dart';
import '../../settings/application/settings_controller.dart';

/// Which entry (if any) currently has its secret on screen, and for how long more.
class RevealState {
  const RevealState({this.entryId, this.secondsLeft = 0});
  final String? entryId;
  final int secondsLeft;

  bool isRevealed(String id) => entryId == id;
}

final revealProvider = NotifierProvider<RevealController, RevealState>(
  RevealController.new,
);

/// Only one secret is ever visible at a time, and it hides itself after the
/// configured delay, when the app locks, and when the app leaves the foreground.
class RevealController extends Notifier<RevealState> {
  Timer? _timer;

  @override
  RevealState build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(lockProvider, (_, status) {
      if (status != LockStatus.unlocked) hide();
    });
    return const RevealState();
  }

  void reveal(String entryId) {
    _timer?.cancel();
    final seconds = ref.read(settingsProvider).hideAfterSeconds;
    state = RevealState(entryId: entryId, secondsLeft: seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = state.secondsLeft - 1;
      if (left <= 0) {
        hide();
      } else {
        state = RevealState(entryId: state.entryId, secondsLeft: left);
      }
    });
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    if (state.entryId != null) state = const RevealState();
  }
}
