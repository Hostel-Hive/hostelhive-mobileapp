import '../repositories/exceptions.dart';

/// The student-facing reason for a failed backend request. The backend sends
/// `{"error": "<code>"}`; the code and status are turned into plain words.
class ApiException extends RepositoryException {
  ApiException({required this.statusCode, this.code})
    : super(messageForError(statusCode, code));

  final int statusCode;
  final String? code;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isGone => statusCode == 410;
}

/// The phone could not reach the server at all.
class NetworkException extends RepositoryException {
  const NetworkException()
    : super('Could not reach the server. Check your connection and try again.');
}

const _codeMessages = {
  'invalid_input': 'Some of the details are not valid. Please check them.',
  'unauthorized': 'Your session has ended. Please sign in again.',
  'forbidden': 'You do not have access to this.',
  'setup_required': 'Finish setting up your account from the invitation email.',
  'not_found': 'We could not find that.',
  'payload_too_large': 'That file is too large.',
  'unsupported_media_type': 'That file type is not supported.',
  'rate_limited': 'Too many requests. Please wait a moment and try again.',
  'service_unavailable': 'The service is busy. Please try again shortly.',
  'already_outside': 'You are already recorded as outside the hostel.',
  'presence_unknown':
      'Your current status is unknown. Scan your ID at the gate first.',
  'going_home_pending': 'You have already declared going home.',
  'going_home_conflict': 'Going home could not be recorded. Please try again.',
  'leave_conflict':
      'This overlaps another leave request or was already submitted.',
  'leave_unavailable': 'Leave requests are unavailable right now.',
  'late_access_conflict': 'A request for this time already exists.',
  'late_access_unavailable': 'Late access requests are unavailable right now.',
  'complaint_conflict':
      'The complaint changed or no longer accepts this. Refresh and try again.',
  'complaint_images_unavailable': 'Photos cannot be uploaded right now.',
  'active_student_required': 'Your student profile is not active.',
  'active_student_account_required': 'Your student account is not active.',
  'active_student_qr_required': 'Your QR code is not available yet.',
  'push_device_conflict': 'This phone could not be registered for alerts.',
};

String messageForError(int status, String? code) {
  final known = code == null ? null : _codeMessages[code];
  if (known != null) return known;
  if (status == 401) return _codeMessages['unauthorized']!;
  if (status == 403) return _codeMessages['forbidden']!;
  if (status == 404) return _codeMessages['not_found']!;
  if (status == 429) return _codeMessages['rate_limited']!;
  if (status >= 500) return _codeMessages['service_unavailable']!;
  return 'Something went wrong. Please try again.';
}
