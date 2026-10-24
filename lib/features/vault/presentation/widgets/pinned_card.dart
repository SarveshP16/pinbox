import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import 'group_card.dart';

/// The Pinned section above the bank cards. Styled like a bank card, with a pin
/// in place of the bank's initials; its rows name their bank, since they've left
/// that bank's card.
class PinnedCard extends StatelessWidget {
  const PinnedCard({super.key, required this.count, required this.rows});

  final int count;

  /// One widget per pinned entry, already built.
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return GroupCard(
      avatar: Icon(LucideIcons.pin, size: 16, color: context.colors.primary),
      title: 'Pinned',
      countLabel: '$count pinned',
      rows: rows,
    );
  }
}
