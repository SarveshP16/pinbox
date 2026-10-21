import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import 'masked_dots.dart';

/// One "label / value" row. A [masked] row shows dots instead of [value] until the
/// card is told it's revealed; [onCopy] adds a copy button on the right.
class InfoRow {
  const InfoRow({
    required this.label,
    required this.value,
    this.masked = false,
    this.onCopy,
  });

  final String label;
  final String value;
  final bool masked;
  final VoidCallback? onCopy;
}

/// White card of [InfoRow]s ("Card ending", "Notes", account details…).
class DetailInfoCard extends StatelessWidget {
  const DetailInfoCard({super.key, required this.rows, this.revealed = false});

  final List<InfoRow> rows;

  /// Whether [InfoRow.masked] rows show their real value.
  final bool revealed;

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
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: context.colors.border),
            _Row(row: rows[i], revealed: revealed),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.revealed});

  final InfoRow row;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final hidden = row.masked && !revealed;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, row.onCopy == null ? 20 : 8, 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: AppText.body(13, color: context.colors.muted),
                ),
                const SizedBox(height: 4),
                if (hidden)
                  // Same height as a line of text so revealing doesn't shift the card.
                  SizedBox(
                    height: 21,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: MaskedDots(
                        count: row.value.length,
                        size: 6,
                        gap: 4,
                        color: context.colors.ink,
                      ),
                    ),
                  )
                else
                  Text(row.value, style: AppText.body(16.5, height: 1.3)),
              ],
            ),
          ),
          if (row.onCopy != null)
            IconButton(
              onPressed: row.onCopy,
              tooltip: 'Copy ${row.label.toLowerCase()}',
              icon: Icon(
                LucideIcons.copy,
                size: 20,
                color: context.colors.primary,
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}
