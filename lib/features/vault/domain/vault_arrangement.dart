import 'bank_grouping.dart';
import 'entry_sort.dart';
import 'vault_entry.dart';

/// What the list shows: pinned entries first, then every other entry grouped by
/// bank. A pinned entry appears only in [pinned], not in its bank group too.
class VaultSections {
  const VaultSections({required this.pinned, required this.groups});

  final List<VaultEntry> pinned;
  final List<BankGroup> groups;

  bool get isEmpty => pinned.isEmpty && groups.isEmpty;
}

/// Splits out pinned entries, groups the rest by bank, orders everything by
/// [sort], then applies [query] the same way search always has: a bank-name
/// match keeps that bank's whole group, and the secret itself is never matched.
/// Pinned entries match on their bank's name too, since they show it.
VaultSections arrangeVault(
  Iterable<VaultEntry> entries, {
  required EntrySort sort,
  String query = '',
}) {
  int byEntry(VaultEntry a, VaultEntry b) => compareEntries(a, b, sort);

  final pinned = entries.where((e) => e.pinned).toList()..sort(byEntry);
  final groups = [
    for (final group in groupByBank(entries.where((e) => !e.pinned)))
      BankGroup(name: group.name, entries: [...group.entries]..sort(byEntry)),
  ]..sort((a, b) => compareGroups(a, b, sort));

  final q = query.trim().toLowerCase();
  if (q.isEmpty) return VaultSections(pinned: pinned, groups: groups);
  return VaultSections(
    pinned: [
      for (final e in pinned)
        if (e.bank.toLowerCase().contains(q) || entryMatchesQuery(e, q)) e,
    ],
    groups: searchGroups(groups, q),
  );
}
