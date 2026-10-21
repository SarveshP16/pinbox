import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/theme/app_palette.dart';
import '../core/widgets/lock_badge.dart';
import '../features/lock/application/lock_controller.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/vault/application/clipboard_service.dart';
import '../features/vault/application/reveal_controller.dart';

/// Wraps the whole app to react to the OS: auto-lock timing, hiding revealed PINs
/// when the app leaves the foreground, applying the screenshot block, and (on iOS,
/// which has no screenshot flag) covering the UI in the app switcher.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(
      settingsProvider.select((s) => s.blockScreenshots),
      (_, block) => ref.read(nativeBridgeProvider).setSecure(block),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(lockProvider.notifier);
    switch (state) {
      case AppLifecycleState.inactive:
        if (!kIsWeb &&
            Platform.isIOS &&
            ref.read(settingsProvider).blockScreenshots) {
          setState(() => _covered = true);
        }
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        ref.read(revealProvider.notifier).hide();
        lock.onBackgrounded();
      case AppLifecycleState.resumed:
        if (_covered) setState(() => _covered = false);
        lock.onForegrounded();
        ref.read(clipboardServiceProvider).clearIfDue();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Icons must contrast with the background behind them: light on dark, and vice versa.
    final iconBrightness = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        // iOS names this the other way round: it describes the bar, not the icons.
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: context.colors.background,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Stack(
        children: [
          widget.child,
          if (_covered)
            Positioned.fill(
              child: ColoredBox(
                color: context.colors.background,
                child: Center(child: LockBadge()),
              ),
            ),
        ],
      ),
    );
  }
}
