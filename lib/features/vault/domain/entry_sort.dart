import 'bank_grouping.dart';
import 'vault_entry.dart';

/// How the list orders bank groups, the entries inside each group, and the
/// Pinned section.
enum EntrySort {
  alphabetical('A–Z'),
  recentlyUsed('Recently used'),
  recentlyAdded('Recently added');

  const EntrySort(this.label);

  final String label;

  /// An unknown or missing stored value reads as the default, [alphabetical].
  static EntrySort fromName(String? name) =>
      EntrySort.values.asNameMap()[name] ?? EntrySort.alphabetical;
}

/// Orders two entries. Alphabetical goes by bank, then type, then the row's
/// subtitle, so it reads sensibly both inside one bank and across banks (the
/// Pinned section). Ties fall back to newest first, then id, so the order is
/// always stable.
int compareEntries(VaultEntry a, VaultEntry b, EntrySort sort) {
  final primary = switch (sort) {
    EntrySort.alphabetical => _alphabetical(a, b),
    EntrySort.recentlyUsed => _latestFirst(a.lastUsedAt, b.lastUsedAt),
    EntrySort.recentlyAdded => b.createdAt.compareTo(a.createdAt),
  };
  if (primary != 0) return primary;
  final added = b.createdAt.compareTo(a.createdAt);
  return added != 0 ? added : a.id.compareTo(b.id);
}

/// Orders two bank groups: by name, or by their most recently used / added
/// entry. Ties fall back to the name.
int compareGroups(BankGroup a, BankGroup b, EntrySort sort) {
  final primary = switch (sort) {
    EntrySort.alphabetical => 0,
    // Banks nobody has used yet keep "recently added" order among themselves.
    EntrySort.recentlyUsed => _firstNonZero([
      () => _latestFirst(_newestUse(a), _newestUse(b)),
      () => _latestFirst(_newestAdd(a), _newestAdd(b)),
    ]),
    EntrySort.recentlyAdded => _latestFirst(_newestAdd(a), _newestAdd(b)),
  };
  return primary != 0 ? primary : bankKey(a.name).compareTo(bankKey(b.name));
}

int _firstNonZero(List<int Function()> comparisons) {
  for (final compare in comparisons) {
    final c = compare();
    if (c != 0) return c;
  }
  return 0;
}

DateTime? _newestUse(BankGroup g) => _newest(g, (e) => e.lastUsedAt);
DateTime? _newestAdd(BankGroup g) => _newest(g, (e) => e.createdAt);

int _alphabetical(VaultEntry a, VaultEntry b) {
  for (final (x, y) in [
    (bankKey(a.bank), bankKey(b.bank)),
    (a.type.label.toLowerCase(), b.type.label.toLowerCase()),
    (a.subtitle.toLowerCase(), b.subtitle.toLowerCase()),
  ]) {
    final c = x.compareTo(y);
    if (c != 0) return c;
  }
  return 0;
}

/// Newer first; a missing time sorts after every present one.
int _latestFirst(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

DateTime? _newest(BankGroup g, DateTime? Function(VaultEntry) pick) {
  DateTime? best;
  for (final e in g.entries) {
    final t = pick(e);
    if (t != null && (best == null || t.isAfter(best))) best = t;
  }
  return best;
}
