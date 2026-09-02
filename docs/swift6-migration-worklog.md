# Swift 6 language mode migration — worklog

Tracks the adoption of `swiftLanguageModes: [.v6]` across amplify-swift. Written as we went, so it
records dead ends and reversals as well as what landed.

Branch: `feat/swift-6-language-mode`

---

## Goal and approach

`Package.swift` moved to `swift-tools-version: 6.0` in the Xcode 26 version bump (#4271), but pinned
`swiftLanguageModes: [.v5]` so that change stayed behaviour-neutral. This work removes that pin.

The whole package flips to `.v6` at once rather than per-target. That was a deliberate choice: a
per-target migration keeps the package green throughout and gives smaller PRs, but produces a long
series of changes to the same core protocols. One flip surfaces every root cause together.

**Consequence worth knowing:** SwiftPM stops at the first failing module and cancels sibling compile
jobs, so an error count from any single build is a *lower bound*. Counts moved 512 → 4 → 170 → 5 → 145
→ … not because work regressed, but because each module going clean revealed the next. Do not read a
falling count as "almost done."

---

## Measured scope

Baseline, before any fixes, from a full build under `-strict-concurrency=complete`:

| Diagnostic | Count |
|---|---|
| `SendableClosureCaptures` | 122 |
| `SendingClosureRisksDataRace` | 81 |
| `MutableGlobalVariable` | 56 |
| `SendingRisksDataRace` | 54 |
| Missing `Sendable` conformance | 49 |
| `SendableMetatypes` | 34 |
| Non-Sendable result leaving an actor | 30 |
| Non-Sendable property exiting an actor | 22 |
| Long tail | ~64 |
| **Total** | **512** |

Densest modules: DataStore 105, Auth 83, `InternalAWSPinpoint` 53, Storage 43, `Amplify/Core/Support`
42, Predictions 39, API 27, `AWSPluginsCore` 23.

A separate ~360 `DeprecatedDeclaration` warnings are pre-existing baseline noise, confirmed against a
control build, and are **not** part of this work.

---

## The single most useful rule

**Swift does not infer `Sendable` for public types.** A payload-free `public enum` such as
`CategoryType` or `LogLevel` is obviously concurrency-safe and still needs an explicit `: Sendable`.
That rule accounts for a large share of the 512, and each fix is one line with no logic change. It is
also why the initial count looked more alarming than the work turned out to be.

---

## Root-cause fixes, by leverage

Most of the total was cleared by a small number of protocol-level changes, not by per-site edits.

| Change | Effect |
|---|---|
| `Model: Sendable` | ~180 `MutationSync<AnyModel>` errors |
| `EnumPersistable`, `Embeddable: Sendable` | The whole test-model fixture set (~1,300 error lines) |
| `Plugin: Sendable` | All 9 `*Category+Resettable` sites, for only 2 new errors |
| `Logger: Sendable` | Referenced across 224 files |
| `State`, `Environment`, `EventDispatcher`, `Action: Sendable` | Most of the Auth state machine |
| `HubFilter`, `HubListener: @Sendable` | Hub dispatch throughout |
| `InternalTaskRunner: Sendable` | DataStore's task runners |
| `Persistable`, `QueryPredicate: Sendable` | DataStore query surface |
| `StorageTransferDatabase`, `StorageServiceProxy`, `StorageURLSession: Sendable` | Storage transfer machinery |
| `PinpointClientProtocol`, `SessionClientBehaviour: Sendable` | Analytics/Pinpoint |

DataStore went from 494 error lines to zero almost entirely from the first four rows.

---

## Real bugs found, not just annotations

Swift 6 surfaced genuine races. These are behaviour fixes, not conformance paperwork.

### 1. `AmplifyAsyncSequence.cancel()` and `AmplifyAsyncThrowingSequence.cancel()`

```swift
guard !isCancelled else { return }
isCancelled = true        // check-then-set on unsynchronized state
parent?.cancel()
```

Two concurrent callers could both observe `false` and each cancel the parent. These are public classes
sitting behind every API and DataStore subscription, and they had no lock at all. Now the cancellation
is claimed atomically under an `NSLock`, and only the claiming caller proceeds.

### 2. Self-referential Hub listeners (5 sites)

The pattern was `var token; let listener = { ... remove(token) }; token = listen(listener)` — the
listener needs to unregister itself, so it referenced a variable assigned after it was built. Genuinely
racy and rejected outright by Swift 6. Now the token lives in an `AtomicValue` box that the closure
captures immutably.

### 3. Dead writes in two `deinit`s

`WebSocketClient.deinit` and `AppSyncRealTimeClient.deinit` wrote to actor-isolated state. Those writes
were already no-ops during deallocation: nothing can observe the flags once teardown starts, and
clearing a cancellable set is redundant because releasing the storage deinitializes each
`AnyCancellable`, which cancels it. Removed, with the reasoning recorded at the site.

---

## Deliberate behaviour change (needs a reviewer's eye)

`ActivityTracker` registers its app-lifecycle notification observers from
`Task { @MainActor in … }` instead of synchronously in `init`.

Why: the notification *names* read main-actor-isolated `UIApplication`/`NSApplication`/`WKExtension`
statics. Making `init` `@MainActor` would propagate through `SessionClient.init` and reach
`AWSPinpointFactory.sharedPinpoint`, which is **public API**. That was judged the worse option.

Cost: registration is now asynchronous, so a lifecycle notification posted in the same turn as
construction could be missed. In practice the tracker is built during plugin configuration, well before
any backgrounding event. The tradeoff is documented at the call site.

---

## Annotated rather than fixed (flagged in code)

Two places where `@unchecked Sendable` asserts something the code does not fully earn. Both carry a
comment saying so; neither is a silent papering-over.

- **`List` / `LazyReference`** — the lazy-load transition on `loadedState` is not synchronized, so two
  concurrent `load()` calls can both fetch. Making it genuinely safe means putting the transition
  behind a lock across the `Collection` and `Codable` surface. Out of scope here; worth its own change.
- **`AWSUnifiedLoggingPlugin`** — `registeredLogs` is guarded inconsistently (`concurrencyQueue` on the
  caching and `reset` paths, `lock` in `enable()`/`disable()`), and `enabled` is not guarded at all.
  Deliberately *not* "fixed": `enabled` is read from inside `lock.execute`, so backing it with the same
  non-recursive lock would deadlock. Needs untangling separately.

---

## Mistake made and corrected

Several Storage production classes were marked `final` alongside `@unchecked Sendable`. `final` was
unnecessary — `@unchecked Sendable` works on non-final classes — and it broke 120 test subclasses that
mock those types. Reverted on 9 classes.

Generalisable: reach for `@unchecked Sendable` alone. Add `final` only when it is independently wanted,
and check for test subclasses first.

---

## Public API surface

All of the following are new constraints on public declarations. The API digester will flag them, and
they are technically source-breaking for external conformers.

**Protocols now requiring `Sendable`:** `Model`, `Plugin`, `Logger`, `Persistable`, `QueryPredicate`,
`Embeddable`, `EnumPersistable`, `AmplifyOperationRequest` (and its `Options`), `AuthCategoryBehavior`,
`APICategoryGraphQLBehavior`, `AnalyticsPropertyValue`, `UserProfilePropertyValue`, `StoragePath`,
`TemporalSpec`, `AuthorizationMode`, `AmplifyAuthTokenProvider`, `AWSAuthServiceBehavior`,
`KeychainStoreBehavior`, `AuthCognitoTokens`, `PinpointClientProtocol`, `SessionClientBehaviour`,
`RemoteNotificationsBehaviour`, `LivenessService`.

**Associated types now `Sendable`:** `AmplifyTask.Success`, `AmplifyInProcessReportingTask.InProcess`.

**Typealiases now `@Sendable`:** `DataStoreCallback`, `BasicClosure`, `HubListener`, `HubFilter`,
`IdentityIDPathResolver`, `EventIDFactory`, the Auth environment factories, the Storage service event
handlers.

**New public API:** `UncheckedSendable<Value>` in `Amplify/Core/Support`. Needed across module
boundaries for Combine `Future.Promise` and `PassthroughSubject` interop, where the type is safe by the
surrounding contract but not expressible as `Sendable`.

`Model` is the one that reaches customer code most directly: codegen'd models are structs of
value-typed properties and satisfy it unchanged, but a hand-written conformance holding reference-type
state would need work. Recommendation is **minor with release notes**; that call is the maintainers'.

---

## Test target migration

Started after production code was clean. The patterns differ from production code, so they are worth
recording separately.

### The four patterns that account for nearly all of it

1. **`XCTestCase` subclasses captured by `@Sendable` closures.** Production APIs now take `@Sendable`
   completions, so a test body that reaches `self` fails. `XCTestCase` is not `Sendable` and XCTest
   runs one test at a time, so `@unchecked Sendable` on the test class is the right assertion. Swept
   577 files in one pass; it took the count from 187 to 43.
2. **Test doubles conforming to now-`Sendable` protocols.** Same `@unchecked Sendable` treatment.
3. **Captured counters** — `var callCount = 0` incremented from a mock closure. Boxed in `AtomicValue`
   (or `TestCounter`, see below).
4. **Captured `result` accumulators** — `var result: X?` assigned inside a closure and asserted after.
   These need per-site judgment rather than a script, and are the slowest part of the tail.

### Two collisions worth knowing about

- **`final` breaks test subclasses.** Marking Storage production classes `final` alongside
  `@unchecked Sendable` broke 120 test subclasses that mock those types. `@unchecked Sendable` does not
  require `final`. Reverted on 9 classes.
- **`AtomicValue` is ambiguous inside Auth tests.** `AWSCognitoAuthPlugin` declares its own internal
  `AtomicValue`, which `@testable import` makes visible alongside Amplify's. The collision cannot be
  spelled away: `Amplify.AtomicValue` resolves against the `Amplify` *type*, not the module, because
  the two share a name. Added a purpose-built `TestCounter` in the Auth test support instead, with the
  reason recorded in the file.
- Also: `MockRecordStorage` is an `actor`, so its counters were already isolated. The counter sweep
  boxed them unnecessarily and that was reverted — a reminder to check isolation before boxing.

### Progress

Compile errors in test targets, per iteration: 69 → 6 → 92 → 51 → 6 → 132 → 43 → 119 → 4 → 115 → 57
→ 20 → 59 → 100.

The number does not fall monotonically for the same reason as production code: SwiftPM cancels sibling
compile jobs, so clearing one target reveals the next. Judge progress by which targets compile, not by
the count.

---

## Runtime failures found once tests actually ran

Compiling was the easy half. Three runtime aborts only appeared once tests executed, and each was the
same underlying shape: **a closure that Swift 6 treats as actor-isolated, invoked synchronously from a
thread that is not on that actor.** In Swift 5 mode these checks are advisory; under `.v6` they abort
the process, so each one halted the whole suite at a different point.

| Site | Why it aborted | Fix |
|---|---|---|
| `ActivityTracker` notification names | Carried `@MainActor`, which pushed observer registration out of `init` into a `Task`; callers that post immediately after construction then saw no observer | Annotation was unnecessary — the platform notification *names* are plain constants. Registration is synchronous again, and no isolation reaches `AWSPinpointFactory` |
| `ActivityTrackerTests.testApplicationStateChanged` | Posted notifications from a background executor into a main-actor-isolated `@objc` handler | Test is now `@MainActor`, matching its already-annotated sibling. The handler's isolation is correct: the platform posts these on the main thread |
| `AppSyncRealTimeClient.subscribeToWebSocketEvent` | `sink`'s closures are not `@Sendable`, so they inherited the enclosing actor's isolation; Combine then called them on the publishing thread | Closures marked `@Sendable`, reaching the actor through an explicit hop |

The `ActivityTracker` case is worth singling out because I got it wrong first. I assumed the `@MainActor`
on those constants was load-bearing and worked around it asynchronously, which introduced a real
regression. Removing the annotation and rebuilding took one command and showed it was never needed.
**Check whether an annotation is actually required before designing around it.**

## Pre-existing failure, not a migration regression

`swift test` cannot get past `testPreconditionFailureInvokingBeforeConfig`. These tests rely on
`AmplifyTesting.getInstanceFactory()`, which is gated on the `XCTestConfigurationFilePath` environment
variable — set by Xcode's test runner, **not** by `swift test`. Without it the injected factory is nil
and the real `Swift.preconditionFailure` fires, killing the process.

Verified against a `main` worktree rather than assumed: `swift test --filter
AmplifyTests.AuthCategoryConfigurationTests` on **`main`** dies at the *same* test, with zero
precondition tests passing. `Fatal.swift`, `AmplifyTesting.swift`, and `TypeRegistry.swift` are all
byte-identical to `main`.

So the honest local completion criterion is: `swift test` green *except* the three
`testPreconditionFailure*` families, which only pass under `xcodebuild`. CI uses `xcodebuild`, so it
exercises them properly there.

## Platform-gated code was the real blind spot

Local `swift test` runs on macOS, so it never compiles the `#if os(...)`-gated code. Every remaining CI
failure lived in exactly those regions, and one root cause accounted for almost all of them.

| Root cause | Platform | CI impact |
|---|---|---|
| `AuthUIPresentationAnchorPlaceholder` not `Sendable` | tvOS, watchOS | **88 build errors → ~50 failing checks** |
| `AmplifyReachability` passes `self` to `NWPathMonitor`'s `@Sendable` handler | watchOS | watchOS build |
| `Amplify/DevMenu` — `PersistentLogWrapper`, `PersistentLoggingPlugin`, `LongPressGestureRecognizer` | iOS, visionOS | iOS/tvOS/visionOS builds |

The anchor case is the one worth remembering. On iOS, macOS and visionOS `AuthUIPresentationAnchor` is a
typealias for `ASPresentationAnchor`; on tvOS and watchOS it resolves to a local placeholder class that
was not `Sendable`. Because these Auth state types are *internal*, they rely on Swift's `Sendable`
**inference**, and inference is all-or-nothing: one non-`Sendable` member silently removed the
conformance from `HostedUIOptions`, then `SignInMethod`, then `SignedInData`, then every state-machine
enum carrying them. Eighty-eight errors, one missing conformance, invisible on macOS.

The placeholder has no stored properties and a private `init`, so it takes a fully checked `Sendable`
conformance — not `@unchecked`.

**Lesson: a cascade of `Sendable`-inference errors usually has a single root. Find the type at the
bottom instead of annotating the types the compiler names.**

## Not caused by this branch

Each of these was checked against `main` rather than assumed:

- **`testPreconditionFailure*`** — `swift test` dies on these because they need `XCTestConfigurationFilePath`,
  which only `xcodebuild` sets. `main` dies at the identical test.
- **`DefaultStorageTransferDatabaseTests`** — 10-second timeouts in full-suite runs, passes in isolation.
  `main` fails the same two tests the same way.
- **HostedUI and WebAuthn integration tests** — failing on `main` as well.
- **`NSLock.lock()` / `unlock()`** — only the Xcode Preview (beta) toolchain rejects these as unavailable
  from async contexts. Converted to `withLock`, which is equivalent and portable.

## CI builds the merge ref, not your branch

The Xcode Preview leg reported `lock`/`unlock` errors in source that **did not exist in this branch**.
Searching the worktree for the symbols in the error snippets (`connectionInitCount`, `startCount`) found
nothing, which looked like a stale log.

It was not. GitHub Actions builds `refs/pull/<n>/merge`, so CI compiles the branch *merged with `main`* —
and `AppSyncRealTimeClientReconnectTests.swift` had landed on `main` after this branch was cut. That file
uses captured `var` counters guarded by a hand-rolled `NSLock`, and both halves are rejected under the
Swift 6 language mode.

Two lessons:

1. **When a CI error names source you cannot find, check `origin/main` before assuming a stale log.**
   `git grep <symbol> origin/main` settles it in one command.
2. A long-running language-mode migration has to keep merging `main`, because every newly landed file is
   another file that must satisfy the new mode. This branch was 6 commits behind and that was enough to
   produce a failure with no local reproduction.

## Open: Analytics iOS integration test

Genuinely a regression — `main`'s job log has zero occurrences of the fatal error and needs no retries,
while this branch crashes and retries. Localised by elimination to **`testGetEscapeHatch`**: `main` runs
7 tests, this branch runs 6, and that is the one missing.

The crash is `Fatal.preconditionFailure` from `AuthCategory.plugin`, reached via
`AmplifyAWSCredentialsProvider.getCredentials()` → `Amplify.Auth.fetchAuthSession()`. So some Pinpoint
work is resolving credentials while the Auth category has no plugin.

What has been ruled out: every file in the Pinpoint, Analytics-plugin and host-app diffs is
annotation-or-comment-only, `Amplify/Core/Configuration` is untouched, and `getEscapeHatch()` itself only
reads a stored property. That points at *concurrent* Pinpoint work rather than the test body — most
likely the static `AWSPinpointFactory.instances` cache, which survives `Amplify.reset()` in `tearDown`
and can outlive the Auth plugin. Not yet proven; it cannot be reproduced locally because the test needs a
real AWS backend.

## Status

- `swift build` — clean under `swiftLanguageModes: [.v6]`.
- `swift test` — **0 compile errors; all 23 of 23 test targets execute**, ~1,440 tests. The only failure
  is the pre-existing Storage flake above, which behaves identically on `main`.
- Lint and format — clean: 0 SwiftLint errors, 0 SwiftFormat diffs. The 382 remaining SwiftLint warnings
  are pre-existing and not enforced.
- Platform builds — iOS verified locally (`BUILD SUCCEEDED`). tvOS, watchOS and visionOS cannot be built
  on this machine (no simulator runtimes or devices for them), so those rely on CI.
- CI — **64 failing checks down to 3**, and the last of those are the Analytics job above plus codecov
  upload steps.

## A process note worth keeping

Three mistakes here came from tooling rather than from Swift:

1. **Type-unaware regex sweeps.** Rewriting declarations without rewriting every read site broke more
   than it fixed — shadowed locals, `switch x {`, `x == y`, and array types starting with `[` all slipped
   through. One sweep took the error count from 86 to 118 and was reverted wholesale.
2. **Working directory drift.** A `swift test` run silently targeted the `release` checkout instead of
   this worktree, because the session's cwd is the primary project directory. Caught by comparing
   `.build` mtimes. Every SwiftPM command here should pass `--package-path` explicitly.
3. **Designing around an annotation instead of testing it.** I assumed `@MainActor` on `ActivityTracker`'s
   notification-name constants was load-bearing and restructured registration to be asynchronous, which
   caused a real regression. Deleting the annotation and rebuilding took one command and proved it was
   never needed.
