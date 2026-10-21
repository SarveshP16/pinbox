import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// Back chevron + big title, the top bar of the Add PIN and Settings screens.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 0),
      child: Row(
        children: [
          BackChevron(onPressed: onBack),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(22, weight: 800, letterSpacing: -0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class BackChevron extends StatelessWidget {
  const BackChevron({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      tooltip: 'Back',
      icon: Icon(LucideIcons.chevronLeft, size: 26, color: context.colors.ink),
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    );
  }
}
