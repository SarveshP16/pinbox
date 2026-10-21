import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/vault_entry.dart';
import 'entry_icon_tile.dart';
import 'entry_type_style.dart';
import 'masked_dots.dart';

/// The big tinted card at the top of the detail screen: bank, type tag, a card-style
/// chip and masked number for cards, and the nickname.
class EntryHeaderCard extends StatelessWidget {
  const EntryHeaderCard({super.key, required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final type = entry.type;
    final ink = type.inkOf(context);

    return Container(
      height: 196,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: type.tintOf(context),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.bank,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(
                    18,
                    weight: 700,
                    color: ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  type.badge,
                  style: AppText.display(
                    11.5,
                    weight: 700,
                    color: ink,
                    letterSpacing: 1.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (type.isCard)
            Container(
              width: 40,
              height: 29,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ink, width: 1.2),
              ),
            )
          else
            EntryIconTile(type: type, size: 40),
          const Spacer(),
          if (type.isCard) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var group = 0; group < 3; group++) ...[
                  MaskedDots(count: 4, size: 6, gap: 3.5, color: ink),
                  const SizedBox(width: 11),
                ],
                Text(
                  entry.cardLast4.isEmpty ? '••••' : entry.cardLast4,
                  style: AppText.body(
                    21,
                    weight: 500,
                    color: ink,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (type.isBankInfo) ...[
            Text(
              entry.accountName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(
                18,
                weight: 700,
                color: ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
          ],
          Text(
            entry.nickname.isNotEmpty
                ? entry.nickname
                : (type.isBankInfo ? entry.routingCode : type.defaultSubtitle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(13.5, color: ink),
          ),
        ],
      ),
    );
  }
}
