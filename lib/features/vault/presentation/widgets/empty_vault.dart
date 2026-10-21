import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/lock_badge.dart';

/// Shown when nothing is saved yet, or when a search matches nothing.
class EmptyVault extends StatelessWidget {
  const EmptyVault({
    super.key,
    required this.title,
    required this.message,
    this.showBadge = true,
  });

  final String title;
  final String message;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 0),
      child: Column(
        children: [
          if (showBadge) ...[const LockBadge(), const SizedBox(height: 20)],
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.display(21, weight: 700, letterSpacing: -0.4),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.body(15.5, color: context.colors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
