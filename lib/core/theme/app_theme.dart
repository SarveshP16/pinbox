import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: brightness,
      ).copyWith(
        primary: p.primary,
        onPrimary: p.onPrimary,
        surface: p.surface,
        onSurface: p.ink,
        outline: p.border,
        error: p.danger,
      );

  return base.copyWith(
    colorScheme: scheme,
    extensions: [p],
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    // Text without an explicit colour inherits this, so it follows the theme.
    textTheme: base.textTheme.apply(
      bodyColor: p.ink,
      displayColor: p.ink,
      fontFamily: 'DMSans',
    ),
    splashFactory: InkRipple.splashFactory,
    splashColor: p.primary.withValues(alpha: 0.06),
    highlightColor: Colors.transparent,
    dividerColor: p.border,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.primary,
      selectionColor: p.primary.withValues(alpha: 0.25),
      selectionHandleColor: p.primary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onPrimary : p.thumbOff,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.primary : p.outline,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      textStyle: AppText.body(16, weight: 500, color: p.ink),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: AppText.display(20, color: p.ink),
      contentTextStyle: AppText.body(15.5, color: p.muted, height: 1.4),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      // Inverted so it stands out from either background.
      backgroundColor: p.ink,
      contentTextStyle: AppText.body(15, weight: 500, color: p.background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
