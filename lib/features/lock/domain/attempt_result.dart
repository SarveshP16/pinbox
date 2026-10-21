/// Outcome of trying to unlock (or re-verify) with a PIN or password.
sealed class AttemptResult {
  const AttemptResult();
}

class AttemptSuccess extends AttemptResult {
  const AttemptSuccess();
}

/// Wrong entry. [attemptsLeft] is how many more misses before a wait is imposed.
class AttemptWrong extends AttemptResult {
  const AttemptWrong(this.attemptsLeft);
  final int attemptsLeft;
}

/// Too many misses; nothing is checked until [until].
class AttemptLockedOut extends AttemptResult {
  const AttemptLockedOut(this.until);
  final DateTime until;
}
