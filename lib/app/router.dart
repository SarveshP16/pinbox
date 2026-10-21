import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_palette.dart';
import '../core/widgets/lock_badge.dart';
import '../features/lock/application/lock_controller.dart';
import '../features/lock/presentation/setup_screen.dart';
import '../features/lock/presentation/unlock_screen.dart';
import '../features/settings/presentation/change_pin_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/vault/presentation/add_edit_pin_screen.dart';
import '../features/vault/presentation/my_pins_screen.dart';
import '../features/vault/presentation/pin_detail_screen.dart';
import 'routes.dart';

/// Lock state drives navigation: whatever the user was doing, locking sends them to
/// the unlock screen and unlocking lands on the list. Because the whole stack is
/// replaced, nothing typed or revealed before locking survives it.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(lockProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final here = state.matchedLocation;
      switch (ref.read(lockProvider)) {
        case LockStatus.loading:
          return here == AppRoutes.splash ? null : AppRoutes.splash;
        case LockStatus.needsSetup:
          return here == AppRoutes.setup ? null : AppRoutes.setup;
        case LockStatus.locked:
          return here == AppRoutes.unlock ? null : AppRoutes.unlock;
        case LockStatus.unlocked:
          const gates = {AppRoutes.splash, AppRoutes.setup, AppRoutes.unlock};
          return gates.contains(here) ? AppRoutes.home : null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, s) => _fade(s, const _Splash()),
      ),
      GoRoute(
        path: AppRoutes.setup,
        pageBuilder: (_, s) => _fade(s, const SetupScreen()),
      ),
      GoRoute(
        path: AppRoutes.unlock,
        pageBuilder: (_, s) => _fade(s, const UnlockScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, s) => _fade(s, const MyPinsScreen()),
      ),
      GoRoute(path: AppRoutes.add, builder: (_, _) => const AddEditPinScreen()),
      GoRoute(
        path: '/pin/:id',
        builder: (_, s) => PinDetailScreen(entryId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) =>
                AddEditPinScreen(entryId: s.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'change-pin',
            builder: (_, _) => const ChangePinScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// Shown for the instant it takes to check whether a master PIN exists.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.background,
    body: Center(child: LockBadge()),
  );
}
