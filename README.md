# Pinbox

A minimal, offline vault for bank card PINs, login PINs and banking passwords.
Flutter (Android + iOS). Nothing ever leaves the device — the release app doesn't
even request the INTERNET permission.

## Screens

Built to match the reference screenshots exactly: **Unlock**, **My PINs**, **PIN
detail**, **Add PIN**, **Settings**. Three screens the mockups don't cover are styled
to match: first-run setup, change master PIN, and the backup password dialog.

## How it stays safe

| Concern | Approach |
| --- | --- |
| Data at rest | Every entry lives in one AES-256-GCM encrypted file (`vault.bin`). The random 256-bit key is held in the Android Keystore / iOS Keychain, never beside the file. |
| Master PIN / password | Only salted PBKDF2-HMAC-SHA256 hashes (600k iterations) are stored. Wrong guesses are rate-limited (5 free, then 30 s doubling to 1 h) and the counter survives app restarts. |
| Backups | Encrypted under a password chosen at export time — *not* the 6-digit PIN, which is too small a space to protect a file that can be copied off the phone. |
| Screen capture | Android `FLAG_SECURE` (also blanks the recents thumbnail); iOS covers the UI in the app switcher. |
| Clipboard | Copies are flagged sensitive on Android 13+ and cleared after a delay (default 30 s). |
| Auto-lock | Re-locks after a configurable time in the background; locking replaces the whole navigation stack, so nothing typed or revealed survives it. |
| Shoulder-surfing | Revealed PINs hide themselves after 10 s, when the app locks, and when it leaves the foreground. |

**There is no recovery.** If both the master PIN and master password are forgotten, the
saved data cannot be opened. That's the point.

## Layout

```
lib/
  app/        router (lock state drives navigation), lifecycle shell
  core/       theme, shared widgets, crypto, platform bridges
  features/
    lock/     unlock, first-run setup, lockout policy
    vault/    entries, list, detail, add/edit
    settings/ settings + change master PIN
    backup/   encrypted export / restore
```

One feature, many small files: each widget or pure function lives in its own file.

## Running

```
flutter pub get
flutter run
flutter test
```

`flutter test test/preview_test.dart --update-goldens` renders each screen to
`test/preview/` at the mockups' 780×1688 size for side-by-side comparison.

## Fonts & icons

Plus Jakarta Sans and DM Sans are **bundled** (`assets/fonts/`), not fetched at runtime.
Icons are [Lucide](https://lucide.dev). The launcher icon set comes from the supplied
icon pack; store-listing artwork is in `branding/`.

## Known limitations

- iOS is written for but **unverified** — there is no Mac in this dev environment.
- Dart timers can pause while the app is backgrounded, so the clipboard wipe is also
  re-checked when the app returns to the foreground.
- `cryptography_flutter` (native-speed PBKDF2) still applies the old Kotlin Gradle
  Plugin; Flutter warns that future versions will refuse such plugins.
- Release builds are signed with the upload key in `android/app/pinbox-release.jks`,
  configured by `android/key.properties`. Both are gitignored — back them up
  somewhere safe; without them no future update can install over this one. If
  `key.properties` is missing, release builds fall back to the debug key.

## License

Pinbox is free software, licensed under the **GNU General Public License v3.0 or
later** — see [LICENSE](LICENSE). You may use, study, share and modify it; if you
distribute a modified version, it has to stay under the same license.

The bundled fonts are not covered by the GPL: both Plus Jakarta Sans and DM Sans
are under the SIL Open Font License 1.1, whose text sits beside them in
`assets/fonts/`. [Lucide](https://lucide.dev) icons are ISC-licensed.
