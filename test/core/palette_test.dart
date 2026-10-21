import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinbox/core/theme/app_palette.dart';
import 'package:pinbox/features/vault/domain/entry_type.dart';
import 'package:pinbox/features/vault/presentation/widgets/entry_type_style.dart';

/// WCAG relative luminance and contrast ratio.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const aa = 4.5; // WCAG AA for normal text

  for (final (name, p) in [
    ('light', AppPalette.light),
    ('dark', AppPalette.dark),
  ]) {
    group('$name palette contrast', () {
      test(
        'main and secondary text are readable on background and surface',
        () {
          for (final bg in [p.background, p.surface, p.sunken]) {
            expect(
              contrast(p.ink, bg),
              greaterThanOrEqualTo(aa),
              reason: 'ink',
            );
            expect(
              contrast(p.muted, bg),
              greaterThanOrEqualTo(aa),
              reason: 'muted',
            );
          }
        },
      );

      test('the accent is readable as text and links', () {
        expect(contrast(p.primary, p.background), greaterThanOrEqualTo(aa));
        expect(contrast(p.primary, p.surface), greaterThanOrEqualTo(aa));
      });

      test('button labels are readable on the primary button', () {
        expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(aa));
      });

      test('error text is readable on the background and its tint', () {
        expect(contrast(p.danger, p.background), greaterThanOrEqualTo(aa));
        expect(contrast(p.danger, p.dangerTint), greaterThanOrEqualTo(aa));
      });

      test(
        'the accent is readable on its tint (fingerprint key, focus ring)',
        () {
          expect(contrast(p.primary, p.primaryTint), greaterThanOrEqualTo(aa));
        },
      );

      test(
        'empty PIN dots and switch tracks stand out from the background',
        () {
          // Non-text UI needs 3:1.
          expect(contrast(p.outline, p.background), greaterThanOrEqualTo(3));
        },
      );

      test('surfaces are distinguishable from the background', () {
        expect(p.surface, isNot(p.background));
        expect(p.border, isNot(p.surface));
      });
    });
  }

  group('entry type colours', () {
    for (final brightness in Brightness.values) {
      test('text on every type tint is readable (${brightness.name})', () {
        for (final type in EntryType.values) {
          final ratio = contrast(
            type.inkFor(brightness),
            type.tintFor(brightness),
          );
          expect(
            ratio,
            greaterThanOrEqualTo(aa),
            reason: '${type.name} in ${brightness.name}: $ratio',
          );
        }
      });
    }

    test('each type has its own tint, so rows are told apart at a glance', () {
      for (final brightness in Brightness.values) {
        final tints = EntryType.values
            .map((t) => t.tintFor(brightness))
            .toSet();
        expect(tints.length, EntryType.values.length);
      }
    });
  });

  test('palettes interpolate for the theme-switch animation', () {
    final mid = AppPalette.light.lerp(AppPalette.dark, 0.5);
    expect(
      mid.background,
      Color.lerp(AppPalette.light.background, AppPalette.dark.background, 0.5),
    );
    expect(
      AppPalette.light.lerp(AppPalette.dark, 0).background,
      AppPalette.light.background,
    );
    expect(
      AppPalette.light.lerp(AppPalette.dark, 1).background,
      AppPalette.dark.background,
    );
  });
}
