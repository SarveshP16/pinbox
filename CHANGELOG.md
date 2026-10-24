# Changelog

All notable changes to Pinbox. Format: [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

### Added
- **Pinned entries.** The pin button on an entry's screen moves it into a Pinned
  section above the bank cards, where its row names its bank. Unpinning returns it
  to its bank.
- **Sort options.** A sort button on My PINs offers A–Z, Recently used and Recently
  added, and the choice is remembered. "Recently used" counts opening an entry or
  copying its secret, but not peeking at it on the list, so a row doesn't jump away
  under your finger.

### Changed
- The list is A–Z by default — banks by name, entries by type — instead of in the
  order they were first added.
- Pins and usage times are saved without taking an automatic backup, so they can't
  push real edits out of the ten that are kept. Both are included in exported
  backups, and a pin counts as an edit when a backup is merged back in.

## [1.0.0] - 2026-10-24

First public release, marked beta.

### Security
- **Unlock lockout could be skipped by changing the phone's clock.** Waits are now
  timed on Android's monotonic boot clock, which Settings can't change; the shown
  countdown follows it too. Rebooting mid-wait restarts the wait instead of ending
  it. iOS keeps the wall-clock behaviour, having no equivalent clock.
- **A wrong guess went uncounted if the app was killed while it was being checked.**
  Each guess is now recorded — and any wait it earns armed — before the slow hash
  runs, and a correct PIN clears it again.
- Simultaneous unlock checks could undercount failures; checks now run one at a time.
- Android 12+ copied app data to a new phone during device-to-device setup despite
  `allowBackup="false"`. Data-extraction rules now exclude everything from both cloud
  backup and device transfer.

### Added
- **Automatic backups.** Before every change, the encrypted vault is copied aside
  in app-private storage; the last 10 are kept. Settings → Backup → Automatic
  backups lists them by age and entry count and restores one after a confirmation.
  Snapshots use the same keystore key as the vault, so nothing is written in the
  clear and no second password is needed — but they cannot be read after an
  uninstall, so the password-protected export is still the off-device copy.
  Restoring is itself snapshotted, and wiping the vault wipes the snapshots too.
- Deleting an entry is now recoverable, and the confirmation says where to look
  instead of "This can't be undone".
- Settings → Support: a "Buy me a coffee on Ko-fi" row, and an app version line
  ("Pinbox 1.0.0 (Beta) · Build 1") read live from the platform via `package_info_plus`
  rather than hardcoded.
- Two new entry types: **Card lock PIN** (a card's freeze/unfreeze PIN, with the same
  optional card-ending field as Debit/Credit card) and **Bank Info** (account name,
  account number, BSB/IFSC, optional CIF number) — seven types in total.
- Bank Info's account number and CIF number are masked and reveal/hide exactly like a
  PIN; account name and BSB/IFSC are always shown. Each field has its own copy button.
- **Dark mode**, following the system by default with a Light/Dark override in a new
  Settings → Appearance section. Every screen, including each entry type's colour, was
  checked against WCAG AA contrast in both themes.
- Initial app, matching the five reference screens: Unlock, My PINs, PIN detail,
  Add PIN, Settings.
- Encrypted vault: AES-256-GCM file with the key held in the OS keystore; entries
  are grouped by bank (case- and spacing-insensitive, so "harbour  bank" files under
  "Harbour Bank").
- Five entry types: Debit card, Credit card, Login PIN, Phone PIN, Password, with
  optional card ending, nickname and notes. "Add a password too" saves a second,
  separate Password entry for the same bank.
- Master PIN (6 digits) plus a master password fallback, biometric unlock, and
  escalating lockout after repeated wrong guesses (persisted across restarts).
- First-run setup and Change master PIN flows, styled to match (not in the mockups).
- Timed reveal (PINs hide after 5–30 s, on lock, and on backgrounding), copy with
  automatic clipboard wipe, search across banks/types/nicknames/card endings (never
  the secrets themselves).
- Settings: biometric unlock, auto-lock, block screenshots, reveal timeout,
  clipboard timeout.
- Encrypted backup export and restore. Restore merges (newer edit wins per entry)
  rather than replacing.
- Launcher icons from the supplied pack (Android adaptive + themed, iOS set).

### Decisions worth knowing
- Backups are protected by a **password chosen at export time**, not the master PIN
  (the mockup's subtitle said "Protected by your master PIN"): a 6-digit PIN has only
  a million combinations, so a copied backup file could be cracked offline quickly.
  The Settings subtitle reads "Protected by a password you choose" accordingly.
- Bundled fonts rather than `google_fonts`, so the app needs no network permission.
- Locking replaces the navigation stack instead of overlaying the lock screen, so
  half-typed PINs and revealed secrets can't survive a lock.
- Entries saved before Bank Info existed load unaffected — the new fields default to
  empty rather than breaking older vault files or backups.
- The app is labelled **Beta** in Settings via one code flag (`kIsBetaRelease` in
  `lib/core/app_info.dart`), not a suffix on the actual store version — App Store
  Connect expects `CFBundleShortVersionString` to be plain dotted numbers, so the
  pubspec version stays `1.0.0+1` and the badge is purely a UI label, off with one
  line once Pinbox leaves beta.
- The app is ad-free by design; the Ko-fi row is the only monetisation surface, and
  it only opens an external link — no SDK, no tracking.
