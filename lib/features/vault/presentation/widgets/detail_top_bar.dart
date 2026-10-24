import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/page_header.dart';

/// Back arrow on the left; pin toggle, edit pencil and a "more" menu (Delete) on
/// the right.
class DetailTopBar extends StatelessWidget {
  const DetailTopBar({
    super.key,
    required this.pinned,
    required this.onTogglePin,
    required this.onEdit,
    required this.onDelete,
  });

  final bool pinned;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          const BackChevron(),
          const Spacer(),
          IconButton(
            onPressed: onTogglePin,
            tooltip: pinned ? 'Unpin' : 'Pin to top',
            isSelected: pinned,
            icon: Icon(
              pinned ? LucideIcons.pinOff : LucideIcons.pin,
              size: 24,
              color: pinned ? context.colors.primary : context.colors.ink,
            ),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit',
            icon: Icon(LucideIcons.pencil, size: 24, color: context.colors.ink),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<_Action>(
            tooltip: 'More',
            icon: Icon(
              LucideIcons.ellipsisVertical,
              size: 24,
              color: context.colors.ink,
            ),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            offset: const Offset(0, 48),
            onSelected: (_) => onDelete(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _Action.delete,
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.trash2,
                      size: 20,
                      color: context.colors.danger,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete',
                      style: AppText.body(
                        16,
                        weight: 500,
                        color: context.colors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Action { delete }
