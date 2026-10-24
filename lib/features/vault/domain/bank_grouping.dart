import 'vault_entry.dart';

/// All entries saved under one bank.
class BankGroup {
  const BankGroup({required this.name, required this.entries});
  final String name;
  final List<VaultEntry> entries;
}

/// Bank names are compared ignoring case and repeated whitespace, so typing
/// "harbour  bank" files under an existing "Harbour Bank".
String bankKey(String name) => normalizeBankName(name).toLowerCase();

String normalizeBankName(String name) =>
    name.trim().replaceAll(RegExp(r'\s+'), ' ');

/// The bank display name to save an entry under: reuses the spelling of an
/// existing bank when there is one, otherwise the cleaned-up input.
String resolveBankName(String input, Iterable<VaultEntry> existing) {
  final key = bankKey(input);
  for (final entry in existing) {
    if (bankKey(entry.bank) == key) return entry.bank;
  }
  return normalizeBankName(input);
}

/// Banks in the order they were first added; entries within a bank likewise.
List<BankGroup> groupByBank(Iterable<VaultEntry> entries) {
  final sorted = entries.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final byKey = <String, List<VaultEntry>>{};
  final names = <String, String>{};
  for (final entry in sorted) {
    final key = bankKey(entry.bank);
    names.putIfAbsent(key, () => entry.bank);
    (byKey[key] ??= []).add(entry);
  }
  return [
    for (final key in byKey.keys)
      BankGroup(name: names[key]!, entries: byKey[key]!),
  ];
}

/// Whether [entry]'s own fields match [query] — type, nickname, account name,
/// BSB/IFSC or card ending. [query] must already be trimmed and lower-cased.
/// Never matches on the secret itself.
bool entryMatchesQuery(VaultEntry entry, String query) =>
    entry.type.label.toLowerCase().contains(query) ||
    entry.nickname.toLowerCase().contains(query) ||
    entry.accountName.toLowerCase().contains(query) ||
    entry.routingCode.toLowerCase().contains(query) ||
    (entry.cardLast4.isNotEmpty && entry.cardLast4.contains(query));

/// Filters by bank name, entry type, nickname and card ending. Never matches on
/// the secret itself. A bank-name match keeps that bank's whole group.
List<BankGroup> searchGroups(List<BankGroup> groups, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return groups;
  final result = <BankGroup>[];
  for (final group in groups) {
    if (group.name.toLowerCase().contains(q)) {
      result.add(group);
      continue;
    }
    final hits = group.entries.where((e) => entryMatchesQuery(e, q)).toList();
    if (hits.isNotEmpty) result.add(BankGroup(name: group.name, entries: hits));
  }
  return result;
}
