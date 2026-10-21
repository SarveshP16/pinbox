import 'attempt_result.dart';

/// User-facing text for a failed attempt, or null when it succeeded.
String? attemptMessage(AttemptResult result, String what, {DateTime? now}) {
  switch (result) {
    case AttemptSuccess():
      return null;
    case AttemptWrong(:final attemptsLeft):
      return attemptsLeft <= 2
          ? 'Incorrect $what · $attemptsLeft ${attemptsLeft == 1 ? 'try' : 'tries'} left'
          : 'Incorrect $what';
    case AttemptLockedOut(:final until):
      final secs = until.difference(now ?? DateTime.now()).inSeconds + 1;
      final safe = secs < 1 ? 1 : secs;
      return 'Too many attempts. Try again in ${safe ~/ 60}:${(safe % 60).toString().padLeft(2, '0')}';
  }
}
