import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/vault_entry.dart';
import 'masked_dots.dart';
import 'reveal_countdown.dart';

/// "Card PIN" label, the secret as big digit boxes (or a password well), and the
/// "Hides in 8 s" line beneath it.
class SecretDisplay extends StatelessWidget {
  const SecretDisplay({
    super.key,
    required this.entry,
    required this.revealed,
    required this.secondsLeft,
  });

  final VaultEntry entry;
  final bool revealed;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.type.secretLabel,
          style: AppText.body(14.5, weight: 500, color: context.colors.muted),
        ),
        const SizedBox(height: 8),
        if (entry.type.isNumeric)
          _DigitBoxes(secret: entry.secret, revealed: revealed)
        else
          _PasswordWell(secret: entry.secret, revealed: revealed),
        const SizedBox(height: 10),
        RevealCountdown(revealed: revealed, secondsLeft: secondsLeft),
      ],
    );
  }
}

class _DigitBoxes extends StatelessWidget {
  const _DigitBoxes({required this.secret, required this.revealed});

  final String secret;
  final bool revealed;

  static const _gap = 12.0;
  static const _maxInline = 8;

  @override
  Widget build(BuildContext context) {
    final chars = secret.characters.toList();
    if (chars.length > _maxInline) {
      // Very long PINs wrap onto extra lines instead of shrinking into slivers.
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in chars)
            _Box(char: c, revealed: revealed, width: 38, height: 52, font: 24),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - _gap * (chars.length - 1)) / chars.length;
        final height = width * 0.93 > 71 ? 71.0 : width * 0.93;
        final font = width * 0.4 > 30 ? 30.0 : width * 0.4;
        return Row(
          children: [
            for (var i = 0; i < chars.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              _Box(
                char: chars[i],
                revealed: revealed,
                width: width,
                height: height,
                font: font,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.char,
    required this.revealed,
    required this.width,
    required this.height,
    required this.font,
  });

  final String char;
  final bool revealed;
  final double width;
  final double height;
  final double font;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: revealed
          ? Text(char, style: AppText.display(font, weight: 800))
          : Container(
              width: font * 0.3,
              height: font * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.ink,
              ),
            ),
    );
  }
}

class _PasswordWell extends StatelessWidget {
  const _PasswordWell({required this.secret, required this.revealed});

  final String secret;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 71),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: revealed
          ? Text(
              secret,
              style: AppText.body(
                20,
                weight: 600,
                letterSpacing: 0.6,
                height: 1.25,
              ),
            )
          : MaskedDots(count: secret.length, size: 8),
    );
  }
}
