/// "30 seconds", "1 minute", "15 minutes" — the wording used in Settings rows.
/// A value of 0 reads as [zero].
String describeSeconds(int seconds, {String zero = 'Never'}) {
  if (seconds <= 0) return zero;
  if (seconds < 60) return '$seconds ${seconds == 1 ? 'second' : 'seconds'}';
  final minutes = seconds ~/ 60;
  return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
}
