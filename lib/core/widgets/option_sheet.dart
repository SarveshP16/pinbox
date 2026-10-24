import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// Bottom sheet listing [options]; resolves to the tapped value (or null if dismissed).
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<({String label, T value})> options,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppText.display(18, weight: 800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 12),
            for (final option in options)
              InkWell(
                onTap: () => Navigator.pop(context, option.value),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label,
                          style: AppText.body(
                            16,
                            weight: option.value == selected ? 700 : 500,
                            color: option.value == selected
                                ? context.colors.primary
                                : context.colors.ink,
                          ),
                        ),
                      ),
                      if (option.value == selected)
                        Icon(
                          LucideIcons.check,
                          size: 22,
                          color: context.colors.primary,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
