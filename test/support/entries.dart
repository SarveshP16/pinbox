import 'package:pinbox/features/vault/domain/entry_type.dart';
import 'package:pinbox/features/vault/domain/vault_entry.dart';

VaultEntry entry({
  String id = 'a',
  String bank = 'Harbour Bank',
  EntryType type = EntryType.debitCard,
  String secret = '4829',
  String last4 = '',
  String nickname = '',
  String notes = '',
  DateTime? created,
  DateTime? updated,
}) {
  final at = created ?? DateTime.utc(2026, 1, 1);
  return VaultEntry(
    id: id,
    bank: bank,
    type: type,
    secret: secret,
    cardLast4: last4,
    nickname: nickname,
    notes: notes,
    createdAt: at,
    updatedAt: updated ?? at,
  );
}
