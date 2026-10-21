import 'entry_type.dart';

/// Form rules for an entry. Each returns an error message, or null when valid.
abstract final class EntryValidation {
  static const minPinLength = 4;
  static const maxPinLength = 12;
  static const minAccountLength = 5;
  static const maxAccountLength = 20;

  static String? bank(String value) =>
      value.trim().isEmpty ? 'Enter a bank name' : null;

  /// Optional, but if given it must be exactly four digits.
  static String? cardLast4(String value) {
    if (value.isEmpty) return null;
    return RegExp(r'^\d{4}$').hasMatch(value) ? null : 'Enter exactly 4 digits';
  }

  /// The PIN, password, or (for Bank Info) account number.
  static String? secret(EntryType type, String value) {
    if (type.isBankInfo) return accountNumber(value);
    if (!type.isNumeric) return value.isEmpty ? 'Enter a password' : null;
    if (value.length < minPinLength || value.length > maxPinLength) {
      return 'A PIN is $minPinLength–$maxPinLength digits';
    }
    return null;
  }

  static String? accountName(String value) =>
      value.trim().isEmpty ? 'Enter the account name' : null;

  static String? accountNumber(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Enter the account number';
    if (value.length < minAccountLength || value.length > maxAccountLength) {
      return 'An account number is $minAccountLength–$maxAccountLength digits';
    }
    return null;
  }

  /// A BSB is 6 digits (often written 123-456); an IFSC is 11 characters
  /// (e.g. SBIN0001234). Anything from 6 to 11 letters/digits is accepted so other
  /// formats aren't blocked, ignoring spaces and hyphens.
  static String? routingCode(String value) {
    final stripped = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (stripped.isEmpty) return 'Enter the BSB or IFSC code';
    if (!RegExp(r'^[A-Z0-9]{6,11}$').hasMatch(stripped)) {
      return 'A BSB has 6 digits; an IFSC has 11 characters';
    }
    return null;
  }

  /// How a routing code is stored and shown: trimmed and upper-cased, hyphen kept
  /// ("123-456", "SBIN0001234").
  static String tidyRoutingCode(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
}
