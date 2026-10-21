import 'entry_type.dart';

/// One saved entry. Lives only inside the encrypted vault.
///
/// [secret] is the PIN or password — or, for [EntryType.bankInfo], the account
/// number, so the same reveal/copy/mask machinery applies to it.
class VaultEntry {
  const VaultEntry({
    required this.id,
    required this.bank,
    required this.type,
    required this.secret,
    required this.createdAt,
    required this.updatedAt,
    this.cardLast4 = '',
    this.nickname = '',
    this.notes = '',
    this.accountName = '',
    this.routingCode = '',
    this.cifNumber = '',
  });

  final String id;
  final String bank;
  final EntryType type;
  final String secret;
  final String cardLast4;
  final String nickname;
  final String notes;

  /// Bank Info only: the name on the account.
  final String accountName;

  /// Bank Info only: BSB (Australia) or IFSC (India) code.
  final String routingCode;

  /// Bank Info only: optional customer information file number.
  final String cifNumber;

  /// Second line of a list row: the card ending, else the nickname, else (for Bank
  /// Info) the account name, else a hint about what the entry is for.
  String get subtitle {
    if (type.isCard && cardLast4.isNotEmpty) return '•• $cardLast4';
    if (nickname.isNotEmpty) return nickname;
    if (type.isBankInfo && accountName.isNotEmpty) return accountName;
    return type.defaultSubtitle;
  }

  VaultEntry copyWith({
    String? bank,
    EntryType? type,
    String? secret,
    String? cardLast4,
    String? nickname,
    String? notes,
    String? accountName,
    String? routingCode,
    String? cifNumber,
    DateTime? updatedAt,
  }) => VaultEntry(
    id: id,
    bank: bank ?? this.bank,
    type: type ?? this.type,
    secret: secret ?? this.secret,
    cardLast4: cardLast4 ?? this.cardLast4,
    nickname: nickname ?? this.nickname,
    notes: notes ?? this.notes,
    accountName: accountName ?? this.accountName,
    routingCode: routingCode ?? this.routingCode,
    cifNumber: cifNumber ?? this.cifNumber,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'bank': bank,
    'type': type.name,
    'secret': secret,
    'cardLast4': cardLast4,
    'nickname': nickname,
    'notes': notes,
    'accountName': accountName,
    'routingCode': routingCode,
    'cifNumber': cifNumber,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  /// Tolerant of files written before the Bank Info fields existed: they simply
  /// come back empty.
  factory VaultEntry.fromJson(Map<String, Object?> json) => VaultEntry(
    id: json['id'] as String,
    bank: json['bank'] as String,
    type: EntryType.fromName(json['type'] as String?),
    secret: json['secret'] as String,
    cardLast4: (json['cardLast4'] as String?) ?? '',
    nickname: (json['nickname'] as String?) ?? '',
    notes: (json['notes'] as String?) ?? '',
    accountName: (json['accountName'] as String?) ?? '',
    routingCode: (json['routingCode'] as String?) ?? '',
    cifNumber: (json['cifNumber'] as String?) ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
