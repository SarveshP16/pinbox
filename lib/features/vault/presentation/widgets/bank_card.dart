import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/bank_grouping.dart';
import '../../domain/bank_initials.dart';
import 'group_card.dart';

/// One bank's card: initials avatar, name, "n saved", then its entry rows.
class BankCard extends StatelessWidget {
  const BankCard({super.key, required this.group, required this.rows});

  final BankGroup group;

  /// One widget per entry, already built (so the card needn't know about reveal state).
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return GroupCard(
      avatar: Text(
        bankInitials(group.name),
        style: AppText.display(11.5, weight: 800, letterSpacing: 0.3),
      ),
      title: group.name,
      countLabel: '${group.entries.length} saved',
      rows: rows,
    );
  }
}
