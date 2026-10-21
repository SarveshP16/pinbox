import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entry_type.dart';

/// Icon and tint pair for each entry type. The light values were sampled from the
/// design; the dark ones keep each type's hue on the dark surfaces.
extension EntryTypeStyle on EntryType {
  IconData get icon => switch (this) {
    EntryType.debitCard || EntryType.creditCard => LucideIcons.creditCard,
    EntryType.cardLockPin => LucideIcons.lockKeyhole,
    EntryType.loginPin => LucideIcons.smartphone,
    EntryType.phonePin => LucideIcons.phone,
    EntryType.password => LucideIcons.key,
    EntryType.bankInfo => LucideIcons.landmark,
  };

  /// Soft background of the icon tile and the detail card.
  Color tintOf(BuildContext context) => tintFor(Theme.of(context).brightness);

  /// Strong colour used for the icon and text drawn on [tintOf].
  Color inkOf(BuildContext context) => inkFor(Theme.of(context).brightness);

  /// Same as [tintOf] for an explicit brightness (no context needed).
  Color tintFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (this) {
      EntryType.debitCard =>
        dark ? const Color(0xFF16352C) : const Color(0xFFDCEBE5),
      EntryType.cardLockPin =>
        dark ? const Color(0xFF3A3216) : const Color(0xFFF3EBCF),
      EntryType.creditCard =>
        dark ? const Color(0xFF172A3F) : const Color(0xFFDDE6F0),
      EntryType.loginPin =>
        dark ? const Color(0xFF3B2A18) : const Color(0xFFF1E3D3),
      EntryType.phonePin =>
        dark ? const Color(0xFF26234A) : const Color(0xFFE6E3F3),
      EntryType.password =>
        dark ? const Color(0xFF3D1F1B) : const Color(0xFFEFDDDA),
      EntryType.bankInfo =>
        dark ? const Color(0xFF22292F) : const Color(0xFFE4E7EA),
    };
  }

  /// Same as [inkOf] for an explicit brightness (no context needed).
  Color inkFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (this) {
      EntryType.debitCard =>
        dark ? const Color(0xFF6FE0BC) : const Color(0xFF0E5A4B),
      EntryType.cardLockPin =>
        dark ? const Color(0xFFE6CB6A) : const Color(0xFF6B5410),
      EntryType.creditCard =>
        dark ? const Color(0xFF8FB6E8) : const Color(0xFF23405F),
      EntryType.loginPin =>
        dark ? const Color(0xFFE8B27A) : const Color(0xFF7A4318),
      EntryType.phonePin =>
        dark ? const Color(0xFFB3AEEF) : const Color(0xFF3B3672),
      EntryType.password =>
        dark ? const Color(0xFFF0A79C) : const Color(0xFF7A2C22),
      EntryType.bankInfo =>
        dark ? const Color(0xFFA9B8C4) : const Color(0xFF3A4652),
    };
  }
}
