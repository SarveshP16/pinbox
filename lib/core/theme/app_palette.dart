import 'package:flutter/material.dart';

/// Every colour the app draws with, in a light and a dark set. Read it with
/// `context.colors` so widgets follow the active theme.
///
/// Light values are sampled pixel-for-pixel from the design screenshots. The dark set
/// is derived from the app icon (near-black green with a mint accent).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.sunken,
    required this.primary,
    required this.primaryTint,
    required this.onPrimary,
    required this.ink,
    required this.muted,
    required this.outline,
    required this.danger,
    required this.dangerTint,
    required this.thumbOff,
  });

  /// Screen background.
  final Color background;

  /// Cards, inputs, keypad keys.
  final Color surface;
  final Color border;

  /// Avatars, inactive chips, secondary buttons.
  final Color sunken;

  /// Brand accent: buttons, links, revealed values.
  final Color primary;

  /// Soft tint of [primary] (focus ring, fingerprint key).
  final Color primaryTint;
  final Color onPrimary;

  /// Main text.
  final Color ink;

  /// Secondary text and icons.
  final Color muted;

  /// Empty PIN dots, switch track when off.
  final Color outline;
  final Color danger;
  final Color dangerTint;

  /// Switch thumb when the switch is off.
  final Color thumbOff;

  static const light = AppPalette(
    background: Color(0xFFF4F2ED),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE2DED5),
    sunken: Color(0xFFECE9E2),
    primary: Color(0xFF0E5A4B),
    primaryTint: Color(0xFFDCEBE5),
    onPrimary: Color(0xFFFFFFFF),
    ink: Color(0xFF15201B),
    muted: Color(0xFF58635D),
    outline: Color(0xFF8A8578),
    danger: Color(0xFF7A2C22),
    dangerTint: Color(0xFFEFDDDA),
    thumbOff: Color(0xFFFFFFFF),
  );

  static const dark = AppPalette(
    background: Color(0xFF0D1411),
    surface: Color(0xFF161F1A),
    border: Color(0xFF26322B),
    sunken: Color(0xFF1F2A24),
    primary: Color(0xFF6FE0BC),
    primaryTint: Color(0xFF1B3B31),
    onPrimary: Color(0xFF07231A),
    ink: Color(0xFFE9F0EC),
    muted: Color(0xFF9BAAA2),
    outline: Color(0xFF6E7C74),
    danger: Color(0xFFF0938A),
    dangerTint: Color(0xFF3C201C),
    thumbOff: Color(0xFFC5D0CA),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? sunken,
    Color? primary,
    Color? primaryTint,
    Color? onPrimary,
    Color? ink,
    Color? muted,
    Color? outline,
    Color? danger,
    Color? dangerTint,
    Color? thumbOff,
  }) => AppPalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    border: border ?? this.border,
    sunken: sunken ?? this.sunken,
    primary: primary ?? this.primary,
    primaryTint: primaryTint ?? this.primaryTint,
    onPrimary: onPrimary ?? this.onPrimary,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    outline: outline ?? this.outline,
    danger: danger ?? this.danger,
    dangerTint: dangerTint ?? this.dangerTint,
    thumbOff: thumbOff ?? this.thumbOff,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      border: mix(border, other.border),
      sunken: mix(sunken, other.sunken),
      primary: mix(primary, other.primary),
      primaryTint: mix(primaryTint, other.primaryTint),
      onPrimary: mix(onPrimary, other.onPrimary),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      outline: mix(outline, other.outline),
      danger: mix(danger, other.danger),
      dangerTint: mix(dangerTint, other.dangerTint),
      thumbOff: mix(thumbOff, other.thumbOff),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The palette for the active theme.
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
