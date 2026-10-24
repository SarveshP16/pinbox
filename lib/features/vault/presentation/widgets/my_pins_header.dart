import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

/// "My PINs" title, the "3 banks · 6 saved" line, and round sort and settings
/// buttons.
class MyPinsHeader extends StatelessWidget {
  const MyPinsHeader({
    super.key,
    required this.summary,
    required this.onSort,
    required this.onSettings,
  });

  final String summary;
  final VoidCallback onSort;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My PINs',
                style: AppText.display(
                  34,
                  weight: 800,
                  letterSpacing: -1.1,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                style: AppText.body(14.5, color: context.colors.muted),
              ),
            ],
          ),
        ),
        _RoundButton(
          tooltip: 'Sort',
          icon: LucideIcons.arrowDownUp,
          onTap: onSort,
        ),
        const SizedBox(width: 10),
        _RoundButton(
          tooltip: 'Settings',
          icon: LucideIcons.slidersHorizontal,
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: CircleBorder(side: BorderSide(color: context.colors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 22, color: context.colors.ink),
          ),
        ),
      ),
    );
  }
}
