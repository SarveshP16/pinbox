import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../application/reveal_controller.dart';
import '../application/vault_controller.dart';
import '../domain/vault_entry.dart';
import 'copy_secret.dart';
import 'widgets/bank_info_section.dart';
import 'widgets/delete_entry_dialog.dart';
import 'widgets/detail_info_card.dart';
import 'widgets/detail_top_bar.dart';
import 'widgets/entry_header_card.dart';
import 'widgets/secret_actions.dart';
import 'widgets/secret_display.dart';

/// Screen 3: one entry, with its secret revealed on demand.
class PinDetailScreen extends ConsumerWidget {
  const PinDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(vaultProvider).value ?? const <VaultEntry>[];
    final entry = entries.where((e) => e.id == entryId).firstOrNull;
    // Briefly true while a just-deleted entry's page animates away.
    if (entry == null) return const Scaffold();

    final reveal = ref.watch(revealProvider);
    final revealed = reveal.isRevealed(entry.id);

    final infoRows = <InfoRow>[
      if (entry.type.isCard && entry.cardLast4.isNotEmpty)
        InfoRow(label: 'Card ending', value: entry.cardLast4),
      if (entry.notes.isNotEmpty) InfoRow(label: 'Notes', value: entry.notes),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DetailTopBar(
              onEdit: () => context.push(AppRoutes.edit(entry.id)),
              onDelete: () => _delete(context, ref, entry),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EntryHeaderCard(entry: entry),
                    const SizedBox(height: 23),
                    if (entry.type.isBankInfo)
                      BankInfoSection(
                        entry: entry,
                        revealed: revealed,
                        secondsLeft: reveal.secondsLeft,
                      )
                    else
                      SecretDisplay(
                        entry: entry,
                        revealed: revealed,
                        secondsLeft: reveal.secondsLeft,
                      ),
                    const SizedBox(height: 14),
                    SecretActions(
                      entry: entry,
                      revealed: revealed,
                      onCopy: () => copyEntrySecret(context, ref, entry),
                      onToggleReveal: () {
                        final controller = ref.read(revealProvider.notifier);
                        revealed
                            ? controller.hide()
                            : controller.reveal(entry.id);
                      },
                    ),
                    if (infoRows.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      DetailInfoCard(rows: infoRows),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    VaultEntry entry,
  ) async {
    if (!await confirmDeleteEntry(context, entry)) return;
    ref.read(revealProvider.notifier).hide();
    await ref.read(vaultProvider.notifier).remove(entry.id);
    if (!context.mounted) return;
    showAppSnackBar(context, '${entry.bank} · ${entry.type.label} deleted');
    context.pop();
  }
}
