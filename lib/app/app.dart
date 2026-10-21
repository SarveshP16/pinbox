import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/application/settings_controller.dart';
import 'app_shell.dart';
import 'router.dart';

class PinboxApp extends ConsumerWidget {
  const PinboxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Pinbox',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ref.watch(settingsProvider.select((s) => s.themeMode)),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          AppShell(child: child ?? const SizedBox.shrink()),
    );
  }
}
