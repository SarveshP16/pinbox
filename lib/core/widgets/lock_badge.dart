import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';

/// The 64 dp green rounded tile with a white padlock that tops the unlock/setup screens.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(LucideIcons.lock, size: 24, color: context.colors.onPrimary),
    );
  }
}
