const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _clock(DateTime at) {
  final h = at.hour.toString().padLeft(2, '0');
  final m = at.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// How a snapshot's age reads in the restore list: "Just now", "12 minutes ago",
/// "Today 09:14", "Yesterday 22:40", then "3 Oct 22:40" for anything older.
///
/// [now] is injectable so the wording can be tested without waiting.
String describeSnapshotTime(DateTime takenAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final elapsed = current.difference(takenAt);

  if (elapsed.inSeconds < 60) return 'Just now';
  if (elapsed.inMinutes < 60) {
    final m = elapsed.inMinutes;
    return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
  }

  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(takenAt.year, takenAt.month, takenAt.day);
  final daysBack = today.difference(day).inDays;

  if (daysBack == 0) return 'Today ${_clock(takenAt)}';
  if (daysBack == 1) return 'Yesterday ${_clock(takenAt)}';
  return '${takenAt.day} ${_months[takenAt.month - 1]} ${_clock(takenAt)}';
}

/// "12 entries" / "1 entry" / "empty".
String describeSnapshotSize(int entryCount) {
  if (entryCount == 0) return 'empty';
  return '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}';
}
