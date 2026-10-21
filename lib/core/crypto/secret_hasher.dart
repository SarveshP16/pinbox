import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Salted PBKDF2-HMAC-SHA256 hashing for the master PIN and master password.
///
/// Stored as `pbkdf2$<iterations>$<salt b64>$<hash b64>` so the cost can be raised
/// later without invalidating hashes that were already saved.
class SecretHasher {
  SecretHasher({this.iterations = defaultIterations});

  /// OWASP's 2023 guidance for PBKDF2-HMAC-SHA256.
  static const defaultIterations = 600000;

  final int iterations;

  Future<String> hash(String secret) async {
    final salt = randomBytes(16);
    final digest = await _derive(secret, salt, iterations);
    return 'pbkdf2\$$iterations\$${base64.encode(salt)}\$${base64.encode(digest)}';
  }

  Future<bool> verify(String secret, String encoded) async {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds <= 0) return false;
    final salt = base64.decode(parts[2]);
    final expected = base64.decode(parts[3]);
    final actual = await _derive(secret, salt, rounds);
    return constantTimeEquals(actual, expected);
  }

  Future<List<int>> _derive(String secret, List<int> salt, int rounds) async {
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: rounds,
      bits: 256,
    ).deriveKeyFromPassword(password: secret, nonce: salt);
    return key.extractBytes();
  }
}

/// Cryptographically secure random bytes.
List<int> randomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

/// Compares without short-circuiting, so timing doesn't reveal how many leading
/// bytes matched.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
