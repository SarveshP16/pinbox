# Feature backlog

Ideas for Pinbox, not yet built. Nothing here is scheduled — pull items into
`CHANGELOG.md`'s `[Unreleased]` section as they're actually built.

**Top 3 recommended next** (biggest safety gaps, no design trade-offs):
1. Soft delete / "Recently deleted" bin
2. Idle auto-lock while foregrounded
3. Backup staleness reminder

## Security & safety

- **Soft delete with a "Recently deleted" bin** (e.g. 30 days) instead of
  permanent deletion on confirm. There's currently no undo once "Delete" is
  confirmed.
- **Backup staleness reminder.** Export is manual only; Settings could show
  "Last backup: 3 months ago" and nudge, the way FixedWise nudges for its own
  auto-backup.
- **Idle auto-lock while the app stays in the foreground.** Right now locking
  only triggers on backgrounding (`onBackgrounded`/`onForegrounded` in
  `LockController`); a few minutes of on-screen inactivity could lock too.
- **Weak-PIN / reused-PIN warning.** Flag "1234", "0000", ascending/descending
  runs, or the same PIN reused across two entries — a gentle hint on save, not
  a hard block.
- **Duplicate-entry detection.** Warn before saving a second Debit card for the
  same bank with the same last-4 digits.

## Organization

- **Favorites/pinning** — pin frequently used entries above the bank groups.
- **Sort options** — alphabetical, most recently used, most recently added
  (currently always first-added order, per `groupByBank`).
- **Photo attachment per entry** — an encrypted photo of the physical card,
  stored through the same `PackedCipher`/keystore path as secrets.

## Convenience

- **One-time secure share** — a short-lived, self-destructing way to hand a
  PIN to a family member instead of reading it aloud or texting it.
- **Home-screen widget** that opens straight to the unlock screen. Never shows
  data — just a faster entry point (precedent: Pulse's home widgets).
- **More routing-code formats** — `EntryValidation.routingCode` currently
  accepts 6-11 alphanumeric chars (covers BSB/IFSC); could explicitly
  recognise US routing numbers, UK sort codes, etc.

## Backup

- **Cloud backup** (Google Drive, as built for FixedWise). This cuts against
  Pinbox's current "nothing ever leaves the device" design (see README) — only
  add if that trade-off is actually wanted.
- **Local device-to-device transfer** (Wi-Fi/QR, no cloud) as a multi-device
  option that keeps the offline-only design intact.
