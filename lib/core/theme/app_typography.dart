import 'package:flutter/painting.dart';

/// Two bundled variable fonts: Plus Jakarta Sans for headings/numerals and DM Sans
/// for body text. Weight is driven by the `wght` axis rather than [FontWeight] so
/// Flutter never fake-bolds the (single-file) variable font.
///
/// When [color] is omitted the text inherits the theme's text colour, so it follows
/// light/dark automatically.
abstract final class AppText {
  static const _display = 'PlusJakartaSans';
  static const _body = 'DMSans';

  static TextStyle display(
    double size, {
    double weight = 700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: _display,
    fontSize: size,
    fontVariations: [FontVariation('wght', weight)],
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle body(
    double size, {
    double weight = 400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: _body,
    fontSize: size,
    fontVariations: [FontVariation('wght', weight)],
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}
