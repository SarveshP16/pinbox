import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pinbox/app/app.dart';
import 'package:pinbox/core/crypto/packed_cipher.dart';
import 'package:pinbox/core/crypto/secret_hasher.dart';
import 'package:pinbox/core/providers.dart';
import 'package:pinbox/features/backup/data/snapshot_store.dart';
import 'package:pinbox/features/lock/data/credentials_store.dart';
import 'package:pinbox/features/vault/data/vault_repository.dart';
import 'package:pinbox/features/vault/domain/vault_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memory_secure_store.dart';

/// Snapshots held in a list instead of files. Real `dart:io` never completes
/// inside `testWidgets`' fake-async zone, so the real store would hang the test.
class InMemorySnapshotStore extends SnapshotStore {
  InMemorySnapshotStore() : super(directory: () async => Directory('unused'));

  /// Newest first, mirroring [SnapshotStore.list].
  final List<VaultSnapshot> held = [];

  @override
  Future<List<VaultSnapshot>> list() async => [...held];

  @override
  Future<void> capture(File vault) async {}

  @override
  Future<void> wipe() async => held.clear();
}

/// A vault that lives in a list instead of an encrypted file, so widget tests
/// don't touch disk (real file I/O stalls `pumpAndSettle`).
///
/// Like the real repository, each save first snapshots the previous state, so
/// the delete-then-restore flow can be driven through the UI.
class InMemoryVaultRepository extends VaultRepository {
  InMemoryVaultRepository(
    this.snapshotStore, [
    List<VaultEntry> seed = const [],
  ]) : stored = [...seed],
       super(keyStore: MemorySecureStore(), file: () async => File('unused'));

  final InMemorySnapshotStore snapshotStore;
  List<VaultEntry> stored;

  /// What each snapshot holds, keyed by its (never-written) file path. A snapshot
  /// missing from here reads as undecryptable, like one from a lost key.
  final Map<String, List<VaultEntry>> snapshotContents = {};
  var _taken = 0;

  @override
  Future<List<VaultEntry>> load() async => [...stored];

  @override
  Future<void> save(List<VaultEntry> entries, {bool snapshot = true}) async {
    if (snapshot && stored.isNotEmpty) {
      final file = File('snapshot-${_taken++}');
      snapshotContents[file.path] = [...stored];
      snapshotStore.held.insert(
        0,
        VaultSnapshot(file: file, takenAt: DateTime.now()),
      );
    }
    stored = [...entries];
  }

  @override
  Future<List<VaultEntry>> readSnapshot(VaultSnapshot snapshot) async {
    final contents = snapshotContents[snapshot.file.path];
    if (contents == null) throw const DecryptionFailure();
    return [...contents];
  }
}

/// No biometric hardware, so the unlock screen never auto-prompts.
class NoBiometrics extends LocalAuthentication {
  @override
  Future<bool> isDeviceSupported() async => false;

  @override
  Future<bool> get canCheckBiometrics async => false;
}

bool _fontsLoaded = false;

/// flutter_test draws every font as the fixed-width "Ahem" test font unless real ones
/// are registered, which makes layouts overflow that are fine on a device.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  for (final (family, path) in [
    ('DMSans', 'assets/fonts/DMSans.ttf'),
    ('PlusJakartaSans', 'assets/fonts/PlusJakartaSans.ttf'),
    // Icon fonts from packages aren't loaded by flutter_test either (icons would draw as boxes).
    ('packages/lucide_icons_flutter/Lucide', _lucidePath()),
  ]) {
    final bytes = File(path).readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    await loader.load();
  }
}

/// Locates lucide.ttf inside the pub cache via the package config.
String _lucidePath() {
  final config = File('.dart_tool/package_config.json').readAsStringSync();
  final root = RegExp(r'"name": "lucide_icons_flutter",\s*"rootUri": "([^"]+)"')
      .firstMatch(config)!
      .group(1)!;
  return '${Uri.parse(root).toFilePath()}/assets/lucide.ttf';
}

/// Stands in for the OS clipboard. Without a handler, `Clipboard.setData` awaits a
/// platform reply that never comes in flutter_test, so copy actions would hang.
class FakeClipboard {
  String? text;
}

class TestApp {
  TestApp(this.store, this.vault, this.clipboard);

  final MemorySecureStore store;
  final InMemoryVaultRepository vault;
  final FakeClipboard clipboard;

  InMemorySnapshotStore get snapshots => vault.snapshotStore;
}

const testPin = '123456';
const testPassword = 'hunter2hunter2';

/// Boots the real app against fakes on a phone-sized (390x844) screen.
/// With [withCredentials] a master PIN/password already exist, so the app starts locked.
Future<TestApp> pumpPinbox(
  WidgetTester tester, {
  bool withCredentials = true,
  List<VaultEntry> seed = const [],
  Map<String, Object> prefs = const {},
}) async {
  await loadAppFonts();
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  PackageInfo.setMockInitialValues(
    appName: 'Pinbox',
    packageName: 'com.pinbox.app',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );

  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final store = MemorySecureStore();
  final hasher = SecretHasher(iterations: 1000);
  if (withCredentials) {
    await CredentialsStore(
      store,
      hasher,
    ).save(pin: testPin, password: testPassword);
  }
  final snapshots = InMemorySnapshotStore();
  final vault = InMemoryVaultRepository(snapshots, seed);

  final clipboard = FakeClipboard();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.text = (call.arguments as Map)['text'] as String?;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        secureStoreProvider.overrideWithValue(store),
        secretHasherProvider.overrideWithValue(hasher),
        vaultRepositoryProvider.overrideWithValue(vault),
        // Without this the Automatic backups row would reach path_provider's
        // platform channel, which has no handler in flutter_test.
        snapshotStoreProvider.overrideWithValue(snapshots),
        localAuthProvider.overrideWithValue(NoBiometrics()),
      ],
      child: const PinboxApp(),
    ),
  );
  await settle(tester);
  return TestApp(store, vault, clipboard);
}

/// Types [digits] on the on-screen keypad.
Future<void> tapPin(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.text(d));
    await tester.pump(const Duration(milliseconds: 30));
  }
  await settle(tester);
}

/// Lets async work (hashing, go_router's redirect) and page transitions finish.
/// Not `pumpAndSettle`: the reveal countdown and lockout ticker are periodic timers
/// that would keep it spinning forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}
