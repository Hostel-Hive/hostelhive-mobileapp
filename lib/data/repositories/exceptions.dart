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

/// The complaint was created but some photos could not be uploaded. Carries
/// the saved complaint so the student is not asked to submit it again.
class PhotoUploadException extends RepositoryException {
  PhotoUploadException({required this.complaintId, required this.failed})
    : super(
        failed == 1
            ? 'Your complaint was sent, but 1 photo could not be uploaded.'
            : 'Your complaint was sent, but $failed photos could not be '
                  'uploaded.',
      );

  final String complaintId;
  final int failed;
}
