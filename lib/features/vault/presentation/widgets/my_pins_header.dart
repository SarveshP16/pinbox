import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

/// "My PINs" title, the "3 banks · 6 saved" line, and the round settings button.
class MyPinsHeader extends StatelessWidget {
  const MyPinsHeader({
    super.key,
    required this.summary,
    required this.onSettings,
  });

  final String summary;
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
        Material(
          color: context.colors.surface,
          shape: CircleBorder(side: BorderSide(color: context.colors.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSettings,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Tooltip(
                message: 'Settings',
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  size: 22,
                  color: context.colors.ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
