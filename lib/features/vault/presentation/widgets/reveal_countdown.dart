import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

/// The "Hides in 8 s" line under a revealed value. Always occupies 24dp so the
/// buttons below don't jump when it appears.
class RevealCountdown extends StatelessWidget {
  const RevealCountdown({
    super.key,
    required this.revealed,
    required this.secondsLeft,
  });

  final bool revealed;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: revealed
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 18,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hides in $secondsLeft s',
                  style: AppText.body(14, color: context.colors.primary),
                ),
              ],
            )
          : null,
    );
  }
}
