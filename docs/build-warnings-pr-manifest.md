# Build warnings — stacked PR manifest

Integration branch: `chore/build-warnings`. Each slice below is a PR into that branch. The draft PR from
`chore/build-warnings` to `main` (#4351) stays open for the whole effort. PR-triggered builds, unit tests and
integration tests only run for PRs into `main`, so the draft PR runs the full matrix after every slice merge. It
lands on `main` as a merge commit, which keeps each slice's commit in the history.

## Baseline

Measured on `548625655` with Swift 6.3.3 and Xcode 26. SPM library and unit-test targets were rebuilt from scratch
(macOS). Every host-app test scheme was built with `build-for-testing` for the iOS simulator. Counts are unique
warnings (file, line, column, message).

| Area | Sources | Unit tests | Host-app tests | Total |
|---|---:|---:|---:|---:|
| `Amplify` core and `AWSPluginsCore` | 55 | 74 | — | 129 |
| `AmplifyTestCommon` | — | 178 | — | 178 |
| Auth | 15 | 48 | 52 | 115 |
| Storage | 94 | 165 | 157 | 416 |
| API | 6 | 17 | 179 | 202 |
| DataStore | 18 | 40 | 406 | 464 |
| **Total** | **188** | **522** | **794** | **1,504** |

## Slices

"Fixed" and "Accepted" are the planned outcomes. Each slice PR confirms them against a rebuild.

| # | PR | Branch | Scope | Warnings | Fixed | Accepted | Depends on |
|---:|---|---|---|---:|---:|---:|---|
| 1 | — | `warnings/01-core` | `Amplify`, `AWSPluginsCore`, `AmplifyTests`, `AWSPluginsCoreTests` | 129 | 64 | 65 | — |
| 2 | — | `warnings/02-test-common` | `AmplifyTestCommon` | 178 | 67 | 111 | 1 |
| 3 | — | `warnings/03-auth` | Auth sources, unit tests, host apps | 115 | 94 | 21 | 1 |
| 4 | — | `warnings/04-storage` | Storage sources, unit tests, `StorageHostApp` | 416 | 60 | 356 | 1 |
| 5 | — | `warnings/05-api` | API sources, unit tests, `APIHostApp` | 202 | 177 | 25 | 1 |
| 6 | — | `warnings/06-datastore` | DataStore sources and unit tests | 58 | 47 | 11 | 1 |
| 7 | — | `warnings/07-datastore-integ` | `DataStoreHostApp` | 406 | 250 | 156 | 1 |
| | | | **Total** | **1,504** | **759** | **745** | |

Slice 1 goes first. Its `GraphQLRequest` and `RESTRequest` conformances clear warnings in slices 5 and 6. Slices 2–7
touch separate directories and can proceed in parallel once slice 1 is merged.

## Rules

- **Legacy APIs.** A deprecation warning is accepted until the next major version when the code implements or
  exercises a deprecated public API and no behavior-identical replacement exists. Most of these are the key-based
  Storage API, legacy token initializers, `AuthFlowType.custom` and `.id()`. Accepted warnings are left as they are:
  no `@available(*, deprecated)` wrappers or other suppression.
- **`@unchecked Sendable`.** Used on public types whose stored properties can't be proven `Sendable` (for example
  `[String: Any]` or metatypes), and on non-`final` public classes whose stored properties are all `Sendable` `let`s
  (the compiler only checks `final` classes). Each has a one-line reason at the declaration. Not used on `open`
  classes, because every subclass would then have to restate the conformance (for example `APIAuthProviderFactory`).
  Not used to paper over unsynchronized mutable state either; those types get a lock (for example
  `AmplifyReachability`).
- **Test models.** `model.pluralName = "X"` becomes `model.listPluralName = "X"` plus `model.syncPluralName = "X"`.
  This is behavior-identical, because `pluralName` is only the fallback for both. Models are not regenerated: most
  schemas are stale or the models are hand-edited, and the generated `AmplifyModels.swift` changes the version
  hash. `.id()` stays: replacing it drops the field's own primary-key attribute, which changes DataStore `UPDATE`
  SQL and, for models keyed by an unnamed index, the primary key.
- **Out of scope.** `AWSDataStorePluginFlutterTests` (doesn't compile) and
  `AWSAPIPluginGraphQLAPIKeyIntegrationTests` (no build-for-testing action).

## Gates

1. **Slice.** Warnings in the slice's scope reach its planned count, with no new warnings elsewhere. Unit tests pass
   with an unchanged executed-test count, affected host-app schemes build, and changed files are run through
   `swiftformat`.
2. **Integration.** The draft PR to `main` is green before the next slice merges.
3. **Up to date with main.** `main` is merged into `chore/build-warnings` (merge, not rebase) before the final merge.
4. **Public API.** The Public Interface Breakage Detection workflow runs on every PR and commits refreshed
   `api-dump/*.json`. The checked-in dumps were last updated in `f15cc457b`, before the Swift 6 migration, so the
   first refresh includes that earlier drift.

## Reproducing the baseline

```bash
# SPM targets: touch the target's sources so every file recompiles, then collect warnings.
find <target-dirs> -name '*.swift' -exec touch {} +
swift build --target <Target> 2>&1 | grep -E '^/.*:[0-9]+:[0-9]+: warning: ' | sort -u

# Host apps: one scheme at a time.
xcodebuild build-for-testing -quiet -project <HostApp>.xcodeproj -scheme <Scheme> \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 \
  | grep -E '^/.*:[0-9]+:[0-9]+: warning: ' | sed -E 's/ \(in target .*\)$//' | sort -u
```

## Found along the way

These are existing bugs rather than warnings, and are tracked separately from this effort:

- `AWSHTTPURLResponse` declares `supportsSecureCoding` but decodes with the non-secure `decodeObject(forKey:)`.
- `CascadeDeleteOperation.syncDeletions` never calls its completion when there are no models to delete, and its
  `==` completion gate would hang if a submit callback fired twice.
- `DataStoreConsecutiveUpdatesTests` has an expectation that is never awaited, and
  `AWSDataStoreLazyLoadBlogPostComment8V2Tests` compares a comment id with itself.
- `StateMachineTests` reads and writes a local `var` from two queues without synchronization.
- Storage integration tests leave objects behind in S3 (for example `public/public/<uuid>` in the GetURL tests).
