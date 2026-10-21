# Publishing Pinbox

Three destinations, in the order they make sense: GitHub (source + APK), F-Droid
(built from that source), Play Store (built and signed by you).

Store listing text and images live in `fastlane/metadata/android/en-US/` and are
shared by all three. The F-Droid build recipe is `fdroid/com.pinbox.app.yml`.

---

## Before any release

1. **Decide the version.** Bump `version:` in `pubspec.yaml` — the part before
   `+` is the versionName, the part after is the versionCode. Both F-Droid and
   Play refuse a versionCode that is not higher than the last one published.
2. **Flip the beta flag** when 1.0 stops being a beta:
   `kIsBetaRelease` in `lib/core/app_info.dart`. It only controls the
   "(Beta)" suffix on the Settings version line.
3. **Move `CHANGELOG.md`'s `[Unreleased]` items** under a real version heading.
4. **Write the store changelog**: `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`.
   F-Droid shows this file; the filename must be the versionCode, not the name.
5. **Run the tests**: `flutter test` — 118 pass today.
6. **Build**: `flutter build apk --release` and `flutter build appbundle --release`.

The upload keystore (`android/app/pinbox-release.jks`) and `android/key.properties`
are gitignored and exist only on this machine. **Back both up somewhere you will
still have in five years.** Lose them and no future Play Store update can install
over the current one — Play App Signing can be reset by Google, but only through a
support process, and the plain-APK/GitHub route cannot be recovered at all.

---

## 1. GitHub release

The repo is <https://github.com/SarveshP16/pinbox> and already public.

```bash
git tag -a v1.0.0 -m "Pinbox 1.0.0"
git push origin v1.0.0
gh release create v1.0.0 \
  build/app/outputs/flutter-apk/app-release.apk \
  --title "Pinbox 1.0.0" \
  --notes-file fastlane/metadata/android/en-US/changelogs/1.txt
```

The tag matters beyond GitHub: the F-Droid recipe pins `commit: v1.0.0`, and
`UpdateCheckMode: Tags` means F-Droid watches tags to notice future releases. Tag
names must stay in the `v<version>` shape for `AutoUpdateMode: Version v%v` to work.

---

## 2. F-Droid

F-Droid builds the app itself from this repository on its own server and signs it
with **F-Droid's** key, not yours. Practical consequence: the F-Droid build and
your Play/GitHub build are different signatures, so a user cannot switch between
them without uninstalling and losing their vault. Pick one channel per user and
say so in the listing if it becomes a question.

### What already qualifies

- GPL-3.0-or-later, full text in `LICENSE`.
- No proprietary dependencies — no Google Play Services, no Firebase, no
  analytics SDK. Checked: nothing in `android/` references `gms`, `firebase`,
  `crashlytics` or `play-services`.
- No anti-features to declare. Release builds hold no `INTERNET` permission, so
  `NonFreeNet`, `Tracking` and `Ads` do not apply.
- Bundled fonts are SIL OFL 1.1 with license text beside them in `assets/fonts/`.
- Listing metadata and screenshots in the fastlane tree, which F-Droid reads
  automatically.

### Submitting

Easiest route, and the one F-Droid prefers for a first-time app:

1. Open an RFP ("Request For Packaging") issue at
   <https://gitlab.com/fdroid/rfp/-/issues> using the *App Inclusion* template.
   Include the source URL, the license, the upstream version/tag, and a sentence
   on what the app does.
2. A maintainer reviews the licensing and dependencies. Expect weeks, not days —
   the queue is long and staffed by volunteers.
3. Either they write the build recipe, or you speed it up by opening a merge
   request against <https://gitlab.com/fdroid/fdroiddata> that adds
   `metadata/com.pinbox.app.yml` — copy `fdroid/com.pinbox.app.yml` from this
   repo to exactly that path and name.

### Testing the recipe before you submit

Worth doing; a recipe that fails on their server is the main cause of delay.

```bash
git clone https://gitlab.com/fdroid/fdroiddata
cd fdroiddata
cp /path/to/pinbox/fdroid/com.pinbox.app.yml metadata/
fdroid readmeta && fdroid lint com.pinbox.app
fdroid build -v -l com.pinbox.app
```

`fdroid lint` catches metadata mistakes in seconds. `fdroid build` needs
`fdroidserver` installed and will download a full Flutter SDK, so give it time
and disk.

### Notes on the recipe

- It pins `flutter@3.47.2`, matching the Flutter that builds this project today.
  Bump that pin when you upgrade Flutter, or F-Droid will build with the wrong SDK.
- `rm: [ios]` strips the iOS directory, which F-Droid's scanner would otherwise
  flag for bundled binaries it cannot verify.
- If `fdroid build` complains that `app-release.apk` is already signed, that is
  the debug-key fallback in `android/app/build.gradle.kts` kicking in on their
  server. F-Droid re-signs anyway, but if it blocks the build, the fix is to make
  the release `signingConfig` null when `key.properties` is absent instead of
  falling back to debug.

---

## 3. Play Store

More work and more gatekeeping than the other two. Nothing here is blocked by the
code — it is account and paperwork.

### Account

- $25 one-time registration at <https://play.google.com/console>.
- **New personal developer accounts must run a closed test with at least 12
  testers who stay opted in for 14 continuous days before they can apply for
  production access.** This is the single biggest schedule item — budget three
  weeks minimum before the app can go public. Verify the current rule in the
  Console, as Google has changed the numbers before.
- Identity verification (ID document, address) is required before publishing.

### Build

```bash
flutter build appbundle --release
```

New apps must ship an **AAB** (`build/app/outputs/bundle/release/app-release.aab`),
not an APK. Enroll in Play App Signing and upload with the existing
`pinbox-release.jks` as the upload key.

Confirm the target API level satisfies Play's current floor before uploading —
Google raises it every August and rejects uploads below it. Check the actual value
in the built artifact rather than trusting the Gradle config, since Flutter
supplies it:

```bash
# from the Android SDK build-tools
aapt dump badging build/app/outputs/flutter-apk/app-release.apk | grep -E "SdkVersion|package"
```

If it is below Play's floor, pin `targetSdk` explicitly in
`android/app/build.gradle.kts` instead of using `flutter.targetSdkVersion`.

### Listing requirements, and what is missing

| Item | Status |
| --- | --- |
| App icon, 512×512 PNG | Ready — `fastlane/.../images/icon.png` |
| Phone screenshots | **Need resizing.** The existing ones are 780×1688 (≈1:2.16). Play requires each phone screenshot between 1:2 and 2:1, so these are marginally too tall and will be rejected. Pad them to 780×1560 or re-render at a 1:2 size. F-Droid accepts them as they are. |
| Feature graphic, 1024×500 PNG | **Missing.** Play requires it. Nothing in `branding/` is this size. |
| Short description, ≤80 chars | Ready — 67 chars |
| Full description, ≤4000 chars | Ready, though it uses `<b>` tags, which Play accepts |
| Privacy policy URL | Ready — point it at `https://github.com/SarveshP16/pinbox/blob/main/PRIVACY.md` |
| Data safety form | Declare: no data collected, no data shared. Everything is on-device, which is a valid "no collection" answer. |
| Content rating questionnaire | Straightforward — a utility with no user content, no ads |
| Category | Tools, or Finance |

### Why the Data safety form is easy here

No network permission in release builds means there is genuinely no collection or
sharing to declare. Answer "No" to data collected and data shared, and mention
on-device encryption where it asks about security practices. `PRIVACY.md` is
written to line up with those answers.

---

## Keeping the three in step

A release is: bump version → changelog + `changelogs/<versionCode>.txt` → tag →
GitHub release → F-Droid picks the tag up automatically → upload the AAB to Play
by hand. F-Droid is the only one that updates itself; the other two need the
push.
