import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entry_type.dart';
import 'entry_type_style.dart';

/// "What are you saving?" — a wrapping set of pill chips, one per [EntryType].
class EntryTypeChips extends StatelessWidget {
  const EntryTypeChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final EntryType selected;
  final ValueChanged<EntryType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in EntryType.values)
          _Chip(
            type: type,
            selected: type == selected,
            onTap: () => onSelected(type),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final EntryType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.colors.onPrimary : context.colors.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: type.label,
      child: Material(
        color: selected ? context.colors.primary : context.colors.sunken,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(17, 0, 16, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon, size: 17, color: fg),
                const SizedBox(width: 9),
                Text(
                  type.label,
                  style: AppText.body(14.5, weight: 600, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
