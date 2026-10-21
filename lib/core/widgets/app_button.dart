import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

enum AppButtonStyle { primary, tonal }

/// Full-width-capable rounded button: solid green, or a sunken grey "tonal" one.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.height = 56,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final primary = style == AppButtonStyle.primary;
    final fg = primary ? context.colors.onPrimary : context.colors.ink;
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary
              ? context.colors.primary
              : context.colors.sunken,
          foregroundColor: fg,
          disabledBackgroundColor: primary
              ? context.colors.primary.withValues(alpha: 0.4)
              : context.colors.sunken,
          disabledForegroundColor: fg.withValues(alpha: 0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 9),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(15.5, weight: 700, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
