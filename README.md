# HostelHive Mobile App

[![CI](https://github.com/Hostel-Hive/hostelhive-mobileapp/actions/workflows/ci.yml/badge.svg)](https://github.com/Hostel-Hive/hostelhive-mobileapp/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/coverage-%E2%89%A580%25%20gate-brightgreen)](.github/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/Hostel-Hive/hostelhive-mobileapp)](https://github.com/Hostel-Hive/hostelhive-mobileapp/releases)

Student mobile application for **HostelHive**, an open-source hostel management system built as a capstone project at the University of Kelaniya. Built with Flutter (SRS 2.4, Technological Constraints).

The wider project (backend, web dashboard, hardware, infrastructure, documents) lives in the [Hostel-Hive](https://github.com/Hostel-Hive) organisation.

## Prerequisites
- Flutter 3.47 or later (stable channel) with Dart 3.13 or later
- Android Studio or Xcode for emulators and device builds
- Android 10 or later (NFR013)

### Environment variables
Set in `.env` (copied from `.env.example`, never committed):

| Variable | Description |
|---|---|
| `API_BASE_URL` | Base URL of the deployed HostelHive backend API |
| `FIREBASE_API_KEY` | Firebase web API key, used for authentication |

If unset, the app falls back to built-in demo data.

## Setup
1. Clone the repository and switch to `develop`:
   ```
   git clone https://github.com/Hostel-Hive/hostelhive-mobileapp.git
   cd hostelhive-mobileapp
   git checkout develop
   ```
2. Copy the environment template (placeholders only, never commit the real file):
   ```
   cp .env.example .env
   ```
3. Fill in `.env` with the backend address and the Firebase web API key (ask the backend owner), then install dependencies and run:
   ```
   flutter pub get
   flutter run --dart-define-from-file=.env
   ```
   Without `.env` the app runs on built-in demo data (`sanuthi.p@stu.kln.ac.lk` / `Hostel@123`). Students sign in with their university email.

## Quality checks
```
dart format --set-exit-if-changed .
flutter analyze
flutter test --coverage
flutter build apk --debug
```
The same checks run in GitHub Actions on every push and pull request.

## Project structure
```
lib/
  core/        theme, shared widgets, utilities, routing
  data/        models and repositories
  features/    one folder per feature (auth, passes, complaints, inbox, qr, profile, home)
test/          unit and widget tests
```

## Demo Account
- Email: `thagyakavindi@gmail.com`
- Password: `Kavindithagya2021`

## Deployed Application
As a mobile client, HostelHive has no hosted URL. The deployed build is the installable APK: latest tagged release at [Releases](https://github.com/Hostel-Hive/hostelhive-mobileapp/releases), built against the live backend. See [CHANGELOG.md](CHANGELOG.md) for what changed in each version.

## Documentation
See [CONTRIBUTING.md](CONTRIBUTING.md) for the branching strategy and commit conventions, and [CHANGELOG.md](CHANGELOG.md) for release notes.
