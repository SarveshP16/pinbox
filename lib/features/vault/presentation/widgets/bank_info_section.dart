import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/vault_entry.dart';
import '../copy_secret.dart';
import 'detail_info_card.dart';
import 'reveal_countdown.dart';

/// The Bank Info counterpart of the PIN boxes: an "Account details" caption over a
/// card of copyable rows. The account number and CIF number stay dotted until the
/// entry is revealed (same 10 s auto-hide as PINs); name and BSB/IFSC are always shown.
class BankInfoSection extends ConsumerWidget {
  const BankInfoSection({
    super.key,
    required this.entry,
    required this.revealed,
    required this.secondsLeft,
  });

  final VaultEntry entry;
  final bool revealed;
  final int secondsLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void copy(String value, String label) =>
        copyValue(context, ref, value, label: label);

    final rows = [
      InfoRow(
        label: 'Account name',
        value: entry.accountName,
        onCopy: () => copy(entry.accountName, 'account name'),
      ),
      InfoRow(
        label: 'Account number',
        value: entry.secret,
        masked: true,
        onCopy: () => copy(entry.secret, 'account number'),
      ),
      InfoRow(
        label: 'BSB / IFSC',
        value: entry.routingCode,
        onCopy: () => copy(entry.routingCode, 'BSB / IFSC'),
      ),
      if (entry.cifNumber.isNotEmpty)
        InfoRow(
          label: 'CIF number',
          value: entry.cifNumber,
          masked: true,
          onCopy: () => copy(entry.cifNumber, 'CIF number'),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account details',
          style: AppText.body(14.5, weight: 500, color: context.colors.muted),
        ),
        const SizedBox(height: 8),
        DetailInfoCard(rows: rows, revealed: revealed),
        const SizedBox(height: 10),
        RevealCountdown(revealed: revealed, secondsLeft: secondsLeft),
      ],
    );
  }
}
