import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

class _TileFrame extends StatelessWidget {
  const _TileFrame({
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onTap,
    this.trailingPadding = 20,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final double trailingPadding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 71),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, trailingPadding, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.body(15.5, weight: 500)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppText.body(13.5, color: context.colors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Title (+ optional subtitle) with an on/off switch.
class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TileFrame(
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailingPadding: 10,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Title with an optional current value and a chevron; opens a picker or screen.
class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.title,
    required this.onTap,
    this.value,
  });

  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TileFrame(
      title: title,
      onTap: onTap,
      trailingPadding: 14.5,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) ...[
            Text(
              value!,
              style: AppText.body(14.5, color: context.colors.muted),
            ),
            const SizedBox(width: 8),
          ],
          Icon(LucideIcons.chevronRight, size: 22, color: context.colors.muted),
        ],
      ),
    );
  }
}

/// Title + subtitle with a trailing icon (download/upload) for one-shot actions.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TileFrame(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(icon, size: 24, color: context.colors.ink),
    );
  }
}
