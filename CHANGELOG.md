# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
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
