import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

/// White rounded card with a header — a small square avatar, a title and a count
/// — then rows separated by hairlines. Shared by bank cards and the Pinned card.
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.avatar,
    required this.title,
    required this.countLabel,
    required this.rows,
  });

  /// Drawn inside the 32×32 tile at the start of the header.
  final Widget avatar;
  final String title;
  final String countLabel;

  /// One widget per entry, already built (so the card needn't know about reveal state).
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.5, 15.5, 16, 5.5),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.sunken,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: avatar,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(
                      17,
                      weight: 700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  countLabel,
                  style: AppText.body(13, color: context.colors.muted),
                ),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: context.colors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}
