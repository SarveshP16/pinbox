# Privacy Policy

**App:** Pinbox (`com.pinbox.app`)
**Last updated:** 24 October 2026

## The short version

Pinbox collects nothing, sends nothing, and has no servers. The release build of
the app does not request Android's `INTERNET` permission, so it is not
technically capable of transmitting your data anywhere.

## What data Pinbox stores

Only what you type into it: bank names, PINs, passwords, account numbers,
card-ending digits, nicknames and notes, plus your master PIN and master
password.

All of it is stored **on your device only**, inside a single AES-256-GCM
encrypted file in the app's private storage. The encryption key is held by the
Android Keystore. Your master PIN and master password are not stored at all —
only salted PBKDF2-HMAC-SHA256 hashes of them are kept, so they cannot be read
back out of the app.

Before each change, Pinbox keeps an **automatic backup**: a copy of that same
encrypted file from just before the change, held in the same private storage
and encrypted with the same key. The ten most recent are kept. They exist so a
deletion or a mistaken edit can be undone, and they are never sent anywhere.

Pinbox excludes all of its data from Android's cloud backup and from
device-to-device transfer when you set up a new phone, so none of it is copied
off the device by the operating system either.

## What Pinbox does not do

- No accounts, no sign-up, no sign-in to any service.
- No analytics, telemetry, crash reporting or advertising, and no third-party
  SDKs that perform any of those.
- No network requests of any kind. There is no server component.
- No access to your contacts, location, photos, messages, call log or files
  beyond the backup file you explicitly choose to write or read.

## Permissions and why

| Permission | Why |
| --- | --- |
| `USE_BIOMETRIC` | Optional fingerprint/face unlock, performed entirely by Android. Pinbox never receives your biometric data — only a yes/no result. |

## Backups

If you choose to export a backup, Pinbox writes an encrypted file that is
protected by a password you pick at export time. Where that file then goes is
entirely up to you. Once you move it off the device — to a cloud drive, a chat
app, a USB stick — it is covered by that service's privacy policy, not this one.
Anyone who has both the file and its password can read its contents, so store it
accordingly.

## Clipboard

When you copy a PIN or password, it goes to the Android clipboard so you can
paste it. Pinbox marks these copies as sensitive on Android 13 and later, which
keeps them out of clipboard history and preview popups, and it clears the
clipboard automatically after a delay you can configure. While a value sits on
the clipboard, other apps with clipboard access may be able to read it — this is
how Android works, not something Pinbox can prevent.

## Data sharing and selling

None. There is no data to share, because none of it leaves your device, and
there is no third party involved in any part of the app.

## Data deletion

Uninstalling Pinbox deletes the encrypted vault, its automatic backups and its
keystore entry. You can also delete individual entries in the app at any time;
a deleted entry remains inside the automatic backups until ten further changes
have pushed it out, or until you uninstall. Because nothing is stored
off-device, there is nothing to request deletion of from anyone else.

There is no recovery mechanism. If you forget both your master PIN and master
password, the data cannot be decrypted by you, by the developer, or by anyone
else.

## Children

Pinbox is not directed at children and collects no data from anyone.

## Changes

Any change to this policy will be committed to this file in the app's public
repository, so its full history is visible at
<https://github.com/SarveshP16/pinbox/commits/main/PRIVACY.md>.

## Contact

Open an issue at <https://github.com/SarveshP16/pinbox/issues>.
