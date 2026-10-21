import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/crypto/packed_cipher.dart';
import '../../../core/theme/app_palette.dart';
import '../application/reveal_controller.dart';
import '../application/vault_controller.dart';
import '../domain/bank_grouping.dart';
import '../domain/vault_entry.dart';
import 'copy_secret.dart';
import 'widgets/add_pin_fab.dart';
import 'widgets/bank_card.dart';
import 'widgets/empty_vault.dart';
import 'widgets/entry_row.dart';
import 'widgets/my_pins_header.dart';
import 'widgets/pin_search_field.dart';

/// Screen 2: every saved secret, grouped by bank.
class MyPinsScreen extends ConsumerStatefulWidget {
  const MyPinsScreen({super.key});

  @override
  ConsumerState<MyPinsScreen> createState() => _MyPinsScreenState();
}

class _MyPinsScreenState extends ConsumerState<MyPinsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _summary(List<BankGroup> groups) {
    if (groups.isEmpty) return 'Nothing saved yet';
    final saved = groups.fold<int>(0, (sum, g) => sum + g.entries.length);
    return '${groups.length} ${groups.length == 1 ? 'bank' : 'banks'} · $saved saved';
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultProvider);
    final reveal = ref.watch(revealProvider);
    final allGroups = groupByBank(vault.value ?? const <VaultEntry>[]);
    final groups = searchGroups(allGroups, _query);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: MyPinsHeader(
                      summary: _summary(allGroups),
                      onSettings: () => context.push(AppRoutes.settings),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 17),
                  sliver: SliverToBoxAdapter(
                    child: PinSearchField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
                ..._body(vault, allGroups, groups, reveal),
                // Room so the last card can scroll clear of the floating button.
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
            Positioned(
              right: 24,
              bottom: MediaQuery.paddingOf(context).bottom + 32,
              child: AddPinFab(onPressed: () => context.push(AppRoutes.add)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    AsyncValue<List<VaultEntry>> vault,
    List<BankGroup> allGroups,
    List<BankGroup> groups,
    RevealState reveal,
  ) {
    if (vault.isLoading && !vault.hasValue) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
        ),
      ];
    }
    if (vault.hasError) {
      final message = vault.error is DecryptionFailure
          ? 'Your saved PINs couldn’t be decrypted on this device.'
          : 'Something went wrong opening your vault.';
      return [
        SliverToBoxAdapter(
          child: EmptyVault(title: 'Can’t open vault', message: message),
        ),
      ];
    }
    if (allGroups.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: EmptyVault(
            title: 'No PINs yet',
            message: 'Tap “Add PIN” to save your first card PIN or banking password.',
          ),
        ),
      ];
    }
    if (groups.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyVault(
            title: 'No matches',
            message: 'Nothing saved matches “${_query.trim()}”.',
            showBadge: false,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final group = groups[i];
            return BankCard(
              group: group,
              rows: [
                for (final entry in group.entries)
                  EntryRow(
                    key: ValueKey(entry.id),
                    entry: entry,
                    revealed: reveal.isRevealed(entry.id),
                    secondsLeft: reveal.secondsLeft,
                    onOpen: () => context.push(AppRoutes.detail(entry.id)),
                    onToggleReveal: () {
                      final controller = ref.read(revealProvider.notifier);
                      reveal.isRevealed(entry.id)
                          ? controller.hide()
                          : controller.reveal(entry.id);
                    },
                    onCopy: () => copyEntrySecret(context, ref, entry),
                  ),
              ],
            );
          },
        ),
      ),
    ];
  }
}
