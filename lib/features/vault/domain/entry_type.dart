/// What a saved entry is for. Order matches the chip order on the Add screen.
/// Stored by [name], so reordering is safe but renaming a value is not.
enum EntryType {
  debitCard,
  cardLockPin,
  creditCard,
  loginPin,
  phonePin,
  password,
  bankInfo;

  static EntryType fromName(String? name) => EntryType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => EntryType.debitCard,
  );

  /// Chip / row title.
  String get label => switch (this) {
    debitCard => 'Debit card',
    cardLockPin => 'Card lock PIN',
    creditCard => 'Credit card',
    loginPin => 'Login PIN',
    phonePin => 'Phone PIN',
    password => 'Password',
    bankInfo => 'Bank Info',
  };

  /// Small caps tag in the top-right of the detail card.
  String get badge => switch (this) {
    debitCard => 'DEBIT',
    cardLockPin => 'CARD LOCK',
    creditCard => 'CREDIT',
    loginPin => 'LOGIN PIN',
    phonePin => 'PHONE PIN',
    password => 'PASSWORD',
    bankInfo => 'BANK INFO',
  };

  /// Row subtitle used when an entry has no card number or nickname of its own.
  String get defaultSubtitle => switch (this) {
    debitCard => 'Debit card',
    cardLockPin => 'Card lock',
    creditCard => 'Credit card',
    loginPin => 'Mobile app',
    phonePin => 'Phone banking',
    password => 'Online banking',
    bankInfo => 'Account details',
  };

  /// Types that belong to a physical card and can carry its last four digits.
  bool get isCard =>
      this == debitCard || this == cardLockPin || this == creditCard;

  bool get isBankInfo => this == bankInfo;

  /// PINs are digits only; a password is free text, and Bank Info's main value (the
  /// account number) has its own rules.
  bool get isNumeric => this != password && this != bankInfo;

  /// Heading above the secret on the detail screen.
  String get secretLabel => switch (this) {
    debitCard || creditCard => 'Card PIN',
    cardLockPin => 'Card lock PIN',
    loginPin || phonePin => 'PIN',
    password => 'Password',
    bankInfo => 'Account number',
  };

  /// Noun used in buttons and messages ("Copy PIN" / "Copy password").
  String get secretNoun => switch (this) {
    password => 'password',
    bankInfo => 'account number',
    _ => 'PIN',
  };

  /// What "Delete this ___?" refers to: the whole entry, not just its secret.
  String get entryNoun => isBankInfo ? 'bank info' : secretNoun;
}
