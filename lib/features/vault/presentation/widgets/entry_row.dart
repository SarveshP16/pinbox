import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/vault_entry.dart';
import 'entry_icon_tile.dart';
import 'masked_dots.dart';

/// One saved secret inside a bank card. Tap the row to open it, tap the dots to
/// peek at the value for a few seconds, tap the copy icon to copy it.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.entry,
    required this.revealed,
    required this.secondsLeft,
    required this.onOpen,
    required this.onToggleReveal,
    required this.onCopy,
    this.showBank = false,
  });

  final VaultEntry entry;
  final bool revealed;
  final int secondsLeft;
  final VoidCallback onOpen;
  final VoidCallback onToggleReveal;
  final VoidCallback onCopy;

  /// Prefix the subtitle with the bank's name — for rows shown outside their
  /// bank's card, as in the Pinned section.
  final bool showBank;

  @override
  Widget build(BuildContext context) {
    // Outside its bank's card the bank name leads. A type's placeholder subtitle
    // ("Online banking") adds nothing next to it, so only real detail follows.
    final ownDetail = entry.subtitle != entry.type.defaultSubtitle;
    final base = !showBank
        ? entry.subtitle
        : ownDetail
        ? '${entry.bank} · ${entry.subtitle}'
        : entry.bank;
    final subtitle = revealed ? '$base · Hides in $secondsLeft s' : base;

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12.5, 10, 3, 10),
        child: Row(
          children: [
            EntryIconTile(type: entry.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(16, weight: 500, height: 1.2),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      13,
                      height: 1.2,
                      color: revealed
                          ? context.colors.primary
                          : context.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: revealed
                  ? 'Hide ${entry.type.secretNoun}'
                  : 'Reveal ${entry.type.secretNoun}',
              child: InkWell(
                onTap: onToggleReveal,
                borderRadius: BorderRadius.circular(10),
                // Fixed 40dp height: a tall revealed value must not stretch the row.
                child: SizedBox(
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: revealed
                            ? _RevealedSecret(
                                key: const ValueKey('shown'),
                                entry: entry,
                              )
                            : MaskedDots(
                                key: const ValueKey('hidden'),
                                count: entry.secret.length,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onCopy,
              tooltip: 'Copy ${entry.type.secretNoun}',
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
      ),
    );
  }
}

class _RevealedSecret extends StatelessWidget {
  const _RevealedSecret({super.key, required this.entry});
  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final numeric = entry.type.isNumeric;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: Text(
        entry.secret,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: numeric
            ? AppText.display(
                20,
                weight: 800,
                color: context.colors.primary,
                letterSpacing: 3,
              )
            : AppText.body(15, weight: 600, color: context.colors.primary),
      ),
    );
  }
}
