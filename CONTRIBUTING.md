# Contributing

## Branches
| Branch | Purpose |
|---|---|
| `main` | Production-ready code, tagged with a semantic version on each release |
| `develop` | Integration branch; every feature is merged here first |
| `feature/<issue-id>-<slug>` | One branch per GitHub issue, e.g. `feature/4-auth-screens` |
| `fix/<issue-id>-<slug>` | Bug fixes |
| `release/<version>` | Release preparation (version bump, changelog) |

Feature branches are short-lived and open a pull request against `develop`.

## Commits
Use [Conventional Commits](https://www.conventionalcommits.org/): `feat`, `fix`, `test`, `ci`, `build`, `perf`, `refactor`, `docs`, `chore`, `style`, `revert`.

```
feat(auth): add first-login password change

Implements UC001 alternative flow (SDS 4.1).

Closes #4
```

## Before opening a pull request
```
dart format --set-exit-if-changed .
flutter analyze
flutter test --coverage
```
New code needs at least 80% line coverage. Update `CHANGELOG.md` under `[Unreleased]`.
