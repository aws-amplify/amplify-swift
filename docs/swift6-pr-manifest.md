# Swift 6 migration — stacked PR manifest

PR #4283 stays open as the read-only reference. This stack reproduces it exactly, split for review.

Integration branch: `feat/swift6`. Stack: #4328. Every slice commit carries `[skip ci]`; the full
matrix runs on `feat/swift6` after each merge, and the final PR to `main` runs everything.

| # | PR | Slice | Files | Notes |
|---:|---|---|---:|---|
| 1 | #4289 | `swift6/01-unchecked-sendable-helper` | 1 | needed by slice 6 |
| 2 | #4290 | `swift6/02-test-helpers` | 2 | needed by slice 32 |
| 3 | #4291 | `swift6/03-async-sequence-cancellation` | 3 | real fix (data race) |
| 4 | #4292 | `swift6/04-credentials-unconfigured-auth` | 3 | real fix + tests |
| 5 | #4293 | `swift6/05-activity-tracker-registration` | 2 | real fix (regression) |
| 6 | #4294 | `swift6/06-appsync-sink-isolation` | 1 | real fix (isolation abort) |
| 7 | #4295 | `swift6/07-devmenu-concurrency` | 3 | real fix (locking) |
| 8 | #4296 | `swift6/08-watchos-reachability` | 1 | real fix (locking) |
| 9 | #4297 | `swift6/09-anchor-placeholder-sendable` | 1 | unblocks 88 tvOS/watchOS errors |
| 10 | #4298 | `swift6/10-kinesis-withlock` | 2 |  |
| 11 | #4299 | `swift6/11-plugin-category-sendable` | 2 | **breaking**: new requirement on conformers |
| 12 | #4300 | `swift6/12-core-support-sendable` | 14 |  |
| 13 | #4301 | `swift6/13-model-sendable` | 9 | **breaking**: new requirement on Model conformers |
| 14 | #4302 | `swift6/14-lazy-loading-sendable` | 2 |  |
| 15 | #4303 | `swift6/15-datastore-category-sendable` | 7 | **breaking**: `@Sendable` callbacks |
| 16 | #4304 | `swift6/16-hub-sendable` | 6 | **breaking**: `@Sendable` listeners |
| 17 | #4305 | `swift6/17-storage-category-sendable` | 5 | **breaking**: `@Sendable` ProgressListener |
| 18 | #4306 | `swift6/18-auth-category-sendable` | 3 |  |
| 19 | #4307 | `swift6/19-other-categories-sendable` | 21 |  |
| 20 | #4308 | `swift6/20-default-plugins-sendable` | 4 |  |
| 21 | #4309 | `swift6/21-amplify-misc-sendable` | 1 |  |
| 22 | #4310 | `swift6/22-pluginscore-sendable` | 16 |  |
| 23 | #4311 | `swift6/23-auth-statemachine-sendable` | 21 |  |
| 24 | #4312 | `swift6/24-auth-plugin-sendable` | 59 |  |
| 25 | #4313 | `swift6/25-datastore-plugin-sendable` | 34 |  |
| 26 | #4314 | `swift6/26-api-plugin-sendable` | 14 |  |
| 27 | #4315 | `swift6/27-storage-plugin-sendable` | 18 |  |
| 28 | #4316 | `swift6/28-predictions-plugin-sendable` | 26 |  |
| 29 | #4317 | `swift6/29-logging-plugin-sendable` | 8 |  |
| 30 | #4318 | `swift6/30-pinpoint-analytics-push-sendable` | 16 |  |
| 31 | #4319 | `swift6/31-tests-core` | 105 |  |
| 32 | #4320 | `swift6/32-tests-auth` | 88 |  |
| 33 | #4321 | `swift6/33-tests-datastore` | 133 |  |
| 34 | #4322 | `swift6/34-tests-api` | 82 |  |
| 35 | #4323 | `swift6/35-tests-storage` | 77 |  |
| 36 | #4324 | `swift6/36-tests-predictions-pluginscore` | 84 |  |
| 37 | #4325 | `swift6/37-tests-remaining` | 85 |  |
| 38 | #4326 | `swift6/38-enable-swift6` | 2 | flips `swiftLanguageModes: [.v6]` — must be last |

## Gates

1. **Equivalence** — `git diff origin/swift6/38-enable-swift6 origin/feat/swift-6-language-mode` over the
   reference's 961 changed files must be empty. Verified empty at creation time.
2. **Green integration** — each merge into `feat/swift6` must pass the full matrix before the next slice merges.
3. **Up to date with main** — `main` has `strict: true`, so `feat/swift6` must be current before the final merge.

## Why the mode flips last

Until `swiftLanguageModes: [.v6]` is set, every `Sendable` conformance violation is a *warning*, not an
error, and the repo sets no warnings-as-errors. So each slice compiles on its own and the annotations
accumulate harmlessly. The final one-line slice turns the mode on once everything satisfies it.
