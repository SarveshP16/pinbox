/// Failed unlock attempts allowed before the app starts imposing waits.
const freeAttempts = 5;

/// How long unlocking is refused after [failures] consecutive wrong entries:
/// nothing for the first few, then 30 s, doubling each further miss, capped at 1 h.
Duration lockoutDuration(int failures) {
  if (failures < freeAttempts) return Duration.zero;
  final doublings = (failures - freeAttempts).clamp(0, 7);
  final seconds = 30 * (1 << doublings);
  return Duration(seconds: seconds > 3600 ? 3600 : seconds);
}

/// Misses left before the first wait kicks in (0 once it has).
int attemptsLeft(int failures) =>
    (freeAttempts - failures).clamp(0, freeAttempts);
