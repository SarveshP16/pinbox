import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

/// The "Search banks or cards" pill under the My PINs title.
class PinSearchField extends StatelessWidget {
  const PinSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(LucideIcons.search, size: 22, color: context.colors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              cursorColor: context.colors.primary,
              style: AppText.body(15),
              decoration: InputDecoration(
                hintText: 'Search banks or cards',
                hintStyle: AppText.body(15, color: context.colors.muted),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.text.isEmpty
                ? const SizedBox(width: 16)
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: context.colors.muted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
