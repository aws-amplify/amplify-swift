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

## Status

- `swift build` — **clean.** All modules compile under `swiftLanguageModes: [.v6]`.
- `swift test` — **not yet compiling.** Roughly 100 sites left across ~90 test files, dominated by the
  captured-`result` pattern that needs per-site judgment.
- **No test has been executed yet.** Every result so far is compile-only. Runtime behaviour under the
  new language mode is unverified, and that is the real remaining risk: the `@unchecked Sendable`
  annotations on test doubles assert safety the compiler cannot check, so a genuinely racy test would
  now compile silently.
- CI on the PR is red: 144 failing checks, which are the unit-test targets plus the platform builds.
  Only macOS was verified locally, so the visionOS/tvOS/watchOS build failures are unexamined.
