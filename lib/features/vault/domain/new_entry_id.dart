import 'dart:convert';

import '../../../core/crypto/secret_hasher.dart';

/// A random, URL-safe id for a new entry.
String newEntryId() => base64Url.encode(randomBytes(12)).replaceAll('=', '');
