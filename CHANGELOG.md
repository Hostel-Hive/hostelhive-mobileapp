# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-10-25

### Added
- Attendance history screen: day-grouped IN/OUT gate-scan records with timestamps, current presence status badge, and a late-entry flag for unapproved scans (FR012-013, UC007-008). Accessible from the "View history" link on the Home status card.
- Going home option added to the "Request a pass" form (UC009): replaces the retired Leave workflow (backend returns 410); selecting Going home shows a simplified confirmation with no date or reason fields, and records the declaration via `POST /going-home`. Quota card in the Passes screen is now hidden gracefully when the retired leave-allowance endpoint is unavailable.
- Edit profile screen (Me tab) for contact phone and guardian details, backed by `PATCH /me/student-profile`.
- Profile photo upload and removal via `PUT`/`DELETE /me/student-profile/image`; the photo now shows consistently in both the Me and Home headers via a shared `StudentAvatar` widget.
- A reminder banner on Home when a Going Home declaration is still open and the student has not yet scanned out at the gate.

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
- Change password (Me tab) now reuses the same emailed reset-link flow as Forgot Password, with the email prefilled and locked, instead of a current/new/confirm form: Firebase has no endpoint to verify a typed current password against a bearer token.
- Going Home's confirmation screen leads straight to "Show my QR" instead of "Back to Home", since scanning out at the gate is the actual next step.
- The in-app "set a new password" screen was removed; passwords are now always chosen on Firebase's own page from the emailed link.

### Fixed
- Hero cards on Home, Me and first sign-in rendered pale blue on devices instead of navy with a subtle glow.
- A student account without a student profile now gets a clear message at sign in instead of a generic error.
- Cancelling a pass always failed: the retired ordinary-leave workflow answers 410 instead of 404, so the fallback to the late-access cancel endpoint never ran.
- The attendance screen called a backend endpoint that does not exist, so it always showed "Could not load attendance" even with no real error; it now combines `/me/student-profile` and `/me/attendance/events`.
- The profile photo feature read the wrong JSON field (`photo_url` instead of `profile_image_url`), so it never showed against the real backend; the photo is also private and is now fetched with the student's token like complaint photos.
- Passes, complaints, inbox and attendance could leak from one signed-in student to the next on the same device, because several providers cached data for the life of the app and never reset on sign in/out.
- Going Home's presence badge jumped to "OUT" the moment a declaration was confirmed, even before the student scanned out at the gate; it now always reflects the backend's real presence, with a separate reminder banner while a declaration is open.
- A stale snackbar from Forgot Password could still be showing after navigating to an unrelated screen, since `ScaffoldMessenger` is shared app-wide.
- The Home tab header avatar never showed the uploaded profile photo, only initials, unlike the Me tab.
