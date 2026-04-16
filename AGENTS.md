# AGENTS.md — Amplify Library for Swift

## Project Info

- **Language**: Swift 5.9+ | **Build**: SPM (Xcode 16.0+) | **No CocoaPods**
- **Platforms**: iOS 13+, macOS 12+, tvOS 13+, watchOS 9+, visionOS 1+
- **Architecture**: Monorepo — core framework (`Amplify/`), category plugins (`AmplifyPlugins/`), standalone clients (`AmplifyClients/`)
- **Setup**: `open Package.swift` or `swift package resolve`

## Sub-Package Guides

Detailed conventions and patterns live closer to the code. Read the relevant guide when working in that area:

- [`Amplify/AGENTS.md`](Amplify/AGENTS.md) — Core framework: categories, plugin protocols, error handling, configuration, Hub
- [`AmplifyPlugins/AGENTS.md`](AmplifyPlugins/AGENTS.md) — Plugin implementations: Auth, API, Storage, DataStore, etc.
- [`AmplifyClients/AGENTS.md`](AmplifyClients/AGENTS.md) — Standalone clients: Foundation, Bridge, Kinesis (new pattern)

## Linting & Formatting (MUST pass)

**Always run `swiftformat` on changed files before every commit.** CI enforces both formatting and linting — PRs will fail if files are not formatted. See `.swiftlint.yml` and `.swiftformat` for full rules.

```bash
swiftformat <changed-files>   # Format changed files before committing
swiftformat .                 # Or format everything
swiftlint --fix               # Then lint
```

## License Header (Required on ALL Swift files)

```swift
//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
```

## Repository Structure

```
amplify-swift/
├── Amplify/                    # Core framework (categories, protocols, errors, config)
├── AmplifyPlugins/             # AWS service plugins (Auth, API, Storage, DataStore, etc.)
├── AmplifyClients/             # Standalone AWS clients (Kinesis) — new pattern
├── AmplifyFoundation/          # Shared protocols (credentials, logging, errors) — no deps
├── AmplifyFoundationBridge/    # Foundation ↔ AWS SDK adapters
├── AmplifyTests/               # Core unit tests
├── AmplifyTestCommon/          # Shared test utilities
├── AmplifyAsyncTesting/        # Async test helpers
├── Package.swift               # All SPM targets defined here
├── .swiftlint.yml / .swiftformat
└── CONTRIBUTING.md / ETHOS.md
```

## Key Architectural Concepts

**Two building block patterns exist in this repo:**

1. **Category Plugins** (`Amplify/` + `AmplifyPlugins/`) — Pluggable architecture via `Amplify.configure()`. Categories define behavior protocols, plugins implement them. See [`Amplify/AGENTS.md`](Amplify/AGENTS.md).

2. **Amplify Clients** (`AmplifyClients/` + `AmplifyFoundation/` + `AmplifyFoundationBridge/`) — Standalone AWS clients independent of core Amplify. Actor-based, strict concurrency, protocol-driven. See [`AmplifyClients/AGENTS.md`](AmplifyClients/AGENTS.md).

## Concurrency Rules

- **Prefer** async/await and structured concurrency for all new code
- **Use** `actor` for mutable shared state
- **Avoid** new `DispatchQueue` or callback patterns
- **Do not** use Combine in the core library
- New Amplify Clients **must** enable `StrictConcurrency`

## Error Handling

All errors conform to `AmplifyError` — requires `errorDescription`, `recoverySuggestion`, and `underlyingError`. Category-specific error enums with associated values. Never throw raw `Error` or `NSError`.

## Commit Conventions

[Conventional Commits](https://www.conventionalcommits.org) — enforced via PR title (auto-generates changelog):

```
feat(storage): add progress stall timeout for S3 uploads
fix(api): populate auth mode when parsing request response
chore: update aws-swift-sdk dependency
```

**Types**: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`, `ci`
**Scopes**: `auth`, `api`, `storage`, `datastore`, `geo`, `analytics`, `logging`, `predictions`, `push`, `kinesis`, `core`, `foundation`

No period at end. One feature/bugfix per PR. Reference issues: `fixes #<issue>`.

## Testing

```bash
swift test                                          # All unit tests
swift test --filter AWSCognitoAuthPluginUnitTests    # Specific target
```

- **Unit tests**: XCTest, defined in Package.swift (19 test targets)
- **Integration tests**: Xcode host app projects under `AmplifyPlugins/<Category>/Tests/<Category>HostApp/`
- **Conventions**: Mock via behavior protocols, use `AmplifyTestCommon` for shared utilities, `AmplifyAsyncTesting` for async helpers
- **Test documentation**: Use Given/When/Then doc comments on all test methods:
  ```swift
  /// Test description
  ///
  /// - Given: ...
  /// - When:
  ///    - ...
  /// - Then:
  ///    - ...
  ///
  func testSomething() async throws { ... }
  ```
- Every change requires new or updated tests

## Semver

New enum cases = **minor** bump. Breaking API changes = **major** (rare, needs approval). API surface tracked via `api-dump/` JSON snapshots and CI checks.

## CI/CD

60+ GitHub Actions workflows in `.github/workflows/`: per-category unit tests (`unit_test_*.yml`), integration tests (`integ_test_*.yml`), platform builds, SwiftLint/SwiftFormat checks, API digester, CodeQL, Fortify. Releases via Fastlane.

## Common Agent Tasks

| Task | Key steps |
|------|-----------|
| **Add Amplify Client** | See [`AmplifyClients/AGENTS.md`](AmplifyClients/AGENTS.md) — use Foundation/Bridge, actors, strict concurrency |
| **Fix bug** | Write failing test → fix → verify all tests pass → `fix(<scope>): <desc>` |

## Key Files

| File | Purpose |
|------|---------|
| `Package.swift` | All targets, deps, products |
| `CONTRIBUTING.md` | Contributor guidelines |
| `ETHOS.md` | Design philosophy |
| `Amplify/Core/Support/AmplifyError.swift` | Base error protocol |
| `Amplify/Core/Plugin/Plugin.swift` | Base plugin protocol |
| `Amplify/Core/Configuration/AmplifyConfiguration.swift` | Configuration system |
