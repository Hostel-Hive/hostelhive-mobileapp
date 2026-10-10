# HostelHive Mobile App

[![CI](https://github.com/Hostel-Hive/hostelhive-mobileapp/actions/workflows/ci.yml/badge.svg)](https://github.com/Hostel-Hive/hostelhive-mobileapp/actions/workflows/ci.yml)

Student mobile application for **HostelHive**, the hostel management system of Bulugaha Girls' Hostel, University of Kelaniya. Built with Flutter (SRS 2.4, Technological Constraints).

The wider project (backend, web dashboard, hardware, infrastructure, documents) lives in the [Hostel-Hive](https://github.com/Hostel-Hive) organisation.

## Prerequisites
- Flutter 3.47 or later (stable channel) with Dart 3.13 or later
- Android Studio or Xcode for emulators and device builds
- Android 10 or later (NFR013)

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
3. Install dependencies and run:
   ```
   flutter pub get
   flutter run
   ```

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

## Documentation
See [CONTRIBUTING.md](CONTRIBUTING.md) for the branching strategy and commit conventions, and [CHANGELOG.md](CHANGELOG.md) for release notes.
