# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Attendance history screen: day-grouped IN/OUT gate-scan records with timestamps, current presence status badge, and a late-entry flag for unapproved scans (FR012-013, UC007-008). Accessible from the "View history" link on the Home status card.
- Change password screen accessible from the Me tab (FR006, UC002): current password verification, new password strength meter, and an inline error for wrong current password.


- Flutter project structure for Android and iOS with `flutter_lints` and a Riverpod-based placeholder home screen.
- GitHub Actions CI pipeline (format, analyze, tests with an 80% coverage gate, APK build, dependency scan).
- Dependabot configuration, pull request template, `.env.example`, README and contribution guide.
- Design tokens, `AppTheme` and bundled Plus Jakarta Sans and JetBrains Mono fonts matching the Figma student frames.
- Shared widgets: primary button, text field, app bar, status badge, category pill, info box, password strength meter and checklist, empty state, usage ring and confirmation screen.
- Password strength and form validation utilities, with unit and widget tests.
- Data layer: typed models for students, passes, complaints and inbox items, abstract repositories with in-memory mock implementations, and secure session token storage.
- Formatting helpers for durations and relative times.
- Authentication screens: sign in, first-login password activation, forgot and reset password, and a password updated confirmation.
- Router with session-aware redirects (signed-out students go to login, first-time students must set a password).
- My QR screen showing the student's unique QR code, and full-screen gate scan result screens for success and failure.
- Passes: yearly usage and Active, Pending and History tabs, pass detail with warden note and cancel, request late access with date and time pickers, and a going home flow with confirmations.
- Date and time formatting helpers and an injectable clock for deterministic tests.
- Complaints: report an issue with category, severity, title, description and up to five JPG or PNG photos (camera or gallery, 5 MB limit), a confirmation with the ticket ID, and a complaint detail with progress and updates.
- Inbox: announcements and alerts with All, Announcements and Alerts tabs, unread banner and dots, mark all as read, empty states, and a message detail that marks the message read.
- Profile (Me): student details with room, guardian and contact information, a shortcut to the QR code, and sign out with confirmation.
- Home dashboard with greeting, in/out status, curfew countdown, quick actions and the active request, inside a bottom navigation shell (Home, Passes, Inbox, Me) with an unread dot on Inbox.
- Backend connection: an authenticated API client, Firebase email sign-in with token refresh, student role check, first-time setup completion and the student profile loaded from the backend. Runs on demo data when `API_BASE_URL` and `FIREBASE_API_KEY` are not set.
- Home shows the student's real IN, OUT or UNKNOWN status from the gate scans, with pull-to-refresh on Home and Me, and My QR shows the QR code issued by the backend.
- Passes from the backend: one combined list of leave and late-access requests, the 18-day allowance, leave and late-access requests, cancel for pending requests and going home as a declaration that the next gate scan completes.
- Complaints from the backend: submit with a category and description, up to three photos uploaded one by one with a clear message when one fails, a detail screen with timeline and private photos, and notes on open complaints.
- Inbox from the backend: announcements with their full text and alerts about leave, late access and complaints that open the related record, with unread dots that update when a message is read.

### Changed
- The Inbox no longer has a "Mark all as read" button; messages are marked read when opened.
- Complaints no longer have a title or severity, and the categories are Maintenance and Disciplinary, to match the backend.
- The request form is now "Request a pass" with a Leave or Late access choice; purpose and destination were removed because the backend does not store them.
- Students sign in with their university email only; the Student ID login was removed.

### Fixed
- Hero cards on Home, Me and first sign-in rendered pale blue on devices instead of navy with a subtle glow.
- A student account without a student profile now gets a clear message at sign in instead of a generic error.
