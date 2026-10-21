import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/lock_badge.dart';

/// Badge + title + one-line message. The message turns red for errors.
class LockHeader extends StatelessWidget {
  const LockHeader({
    super.key,
    required this.title,
    required this.message,
    this.isError = false,
  });

  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LockBadge(),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.display(28.5, weight: 800, letterSpacing: -0.9),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              message,
              key: ValueKey(message),
              textAlign: TextAlign.center,
              style: AppText.body(
                15.3,
                color: isError ? context.colors.danger : context.colors.muted,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
