/// A failure that is safe to show to the student.
class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthException extends RepositoryException {
  const AuthException(super.message);
}

/// Raised when "Going home" is recorded for a student who is already out
/// (UC009 alternative flow).
class AlreadyOutsideException extends RepositoryException {
  const AlreadyOutsideException()
    : super('You are already recorded as outside the hostel.');
}
