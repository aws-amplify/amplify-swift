# AGENTS.md — Amplify Library for Swift

> Instructions and context for AI coding agents working on this repository.

---

## Project Info

- **Language**: Swift (5.9+)
- **Build System**: Swift Package Manager (SPM)
- **Platforms**: iOS 13+, macOS 12+, tvOS 13+, watchOS 9+, visionOS 1+ (preview)
- **Architecture**: Monorepo — core framework + pluggable AWS service plugins
- **Dependencies**: aws-sdk-swift (1.6.71), SQLite.swift (0.15.3), CwlPreconditionTesting (2.1.0+), amplify-swift-utils-notifications (1.1.0+)

---

## Setup

```bash
# Clone the repo
git clone git@github.com:aws-amplify/amplify-swift.git

# Open in Xcode (resolves SPM dependencies automatically)
open Package.swift

# Or resolve packages via command line
swift package resolve
```

> **Note**: Xcode 16.0+ is required. SPM is the sole build system — there is no CocoaPods support.

---

## Linting & Formatting

All changes **MUST** pass both SwiftLint and SwiftFormat checks. These are enforced via CI.

### SwiftLint

```bash
swiftlint
```

Key rules enforced (see `.swiftlint.yml`):
- **Line length**: 160 characters (ignores URLs, function declarations, comments)
- **Function body length**: 150 lines max
- **Identifier names**: allows `id`, `of`, `or`
- **Analyzer rules**: `unused_import`, `unused_declaration`
- **Error-level rules**: `closing_brace`, `colon`, `comma`, `empty_enum_arguments`, `opening_brace`, `return_arrow_whitespace`, `statement_position`, `trailing_semicolon`, `non_optional_string_data_conversion`
- **Scope**: Only `Amplify/` and `AmplifyPlugins/` directories (tests are excluded)

### SwiftFormat

```bash
swiftformat .
```

Key formatting rules (see `.swiftformat`):
- 4-space indentation, LF line endings
- Braces on same line (Allman disabled)
- Semicolons: never
- Trailing commas: disabled
- `self`: init-only (redundant self removed elsewhere)
- Wrap arguments: `before-first`
- Import sorting: disabled
- Void style: `Void` keyword

### Auto-format before committing

```bash
swiftformat .
swiftlint --fix
```

---

## License Header (Required on ALL Swift files)

Every Swift source file must include this header:

```swift
//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
```

This is enforced by SwiftFormat's `fileHeader` rule and CI checks.

---

## Project Coding Conventions & Patterns Summary

### 1. Repository Structure

```
amplify-swift/
├── Amplify/                          # Core framework
│   ├── Categories/                   # Category interfaces & models
│   │   ├── Analytics/
│   │   ├── API/
│   │   ├── Auth/
│   │   ├── DataStore/
│   │   ├── Geo/
│   │   ├── Hub/
│   │   ├── Logging/
│   │   ├── Notifications/
│   │   ├── Predictions/
│   │   └── Storage/
│   ├── Core/                         # Configuration, errors, models, plugins
│   │   ├── Category/
│   │   ├── Configuration/
│   │   ├── Error/
│   │   ├── Internal/
│   │   ├── Model/
│   │   ├── Plugin/
│   │   └── Support/
│   ├── DefaultPlugins/               # Built-in default plugins
│   └── DevMenu/                      # Developer menu
│
├── AmplifyPlugins/                   # AWS service plugin implementations
│   ├── Analytics/                    # → AWSPinpointAnalyticsPlugin
│   ├── API/                          # → AWSAPIPlugin (GraphQL + REST)
│   ├── Auth/                         # → AWSCognitoAuthPlugin (+ SRP, BigInteger, libtommath)
│   ├── Core/                         # → AWSPluginsCore, InternalAmplifyCredentials
│   ├── DataStore/                    # → AWSDataStorePlugin
│   ├── Geo/                          # → AWSLocationGeoPlugin
│   ├── Internal/                     # → InternalAWSPinpoint
│   ├── Logging/                      # → AWSCloudWatchLoggingPlugin
│   ├── Notifications/                # → AWSPinpointPushNotificationsPlugin
│   ├── Predictions/                  # → AWSPredictionsPlugin + CoreMLPredictionsPlugin
│   └── Storage/                      # → AWSS3StoragePlugin
│
├── AmplifyClients/                   # Additional client libraries
│   └── AmplifyKinesisClient/         # Kinesis data streaming
│
├── AmplifyFoundation/                # Foundation utilities
├── AmplifyFoundationBridge/          # AWS SDK ↔ Foundation bridge
├── AmplifyAsyncTesting/              # Async/await testing utilities
├── AmplifyTestCommon/                # Shared test utilities & mock models
├── AmplifyTests/                     # Core framework unit tests
├── AmplifyFunctionalTests/           # Core functional tests
├── AmplifyTestApp/                   # Test host application
├── AmplifyTools/                     # Xcode integration tools
│
├── api-dump/                         # API surface area snapshots (.json)
├── api-dump-test/                    # API regression test infrastructure
├── canaries/                         # Canary test apps
├── fastlane/                         # Release automation
├── .github/workflows/                # 60+ GitHub Actions workflows
├── CircleciScripts/                  # Legacy CI scripts
│
├── Package.swift                     # SPM manifest (all targets defined here)
├── .swiftlint.yml                    # SwiftLint configuration
├── .swiftformat                      # SwiftFormat configuration
├── .jazzy.yaml                       # Documentation generation config
├── .codecov.yml                      # Code coverage config
├── CONTRIBUTING.md                   # Contribution guidelines
├── ETHOS.md                          # Design philosophy
└── CHANGELOG.md                      # Version history
```

### 2. Category/Plugin Architecture

This is the most important architectural concept. Amplify uses a **Category + Plugin** pattern:

#### Categories (Interfaces)

Categories define the **public API** for a service domain. They live in `Amplify/Categories/`.

Each category has:
- **`<Category>CategoryBehavior`** — protocol defining the client-facing API methods (all `async throws`)
- **`<Category>CategoryPlugin`** — protocol extending `Plugin` + behavior, defining what plugins must implement
- **`<Category>Category`** — concrete class that routes calls to the registered plugin

```swift
// Protocol defining the API
public protocol StorageCategoryBehavior {
    func getURL(path: any StoragePath, options: ...) async throws -> URL
    func downloadData(path: any StoragePath, options: ...) -> StorageDownloadDataTask
    func uploadData(path: any StoragePath, data: Data, options: ...) -> StorageUploadDataTask
    func remove(path: any StoragePath, options: ...) async throws -> String
    func list(path: any StoragePath, options: ...) async throws -> StorageListResult
}

// Plugin protocol = Plugin + Behavior
public protocol StorageCategoryPlugin: Plugin, StorageCategoryBehavior {}

// Category routes to plugin
public final class StorageCategory: Category {
    var plugins = [PluginKey: StorageCategoryPlugin]()
}
```

#### Plugins (Implementations)

Plugins live in `AmplifyPlugins/` and provide concrete AWS implementations:

| Category | Plugin | AWS Service |
|----------|--------|-------------|
| Analytics | `AWSPinpointAnalyticsPlugin` | Amazon Pinpoint |
| API | `AWSAPIPlugin` | AWS AppSync (GraphQL) + API Gateway (REST) |
| Auth | `AWSCognitoAuthPlugin` | Amazon Cognito |
| DataStore | `AWSDataStorePlugin` | AppSync + local SQLite |
| Geo | `AWSLocationGeoPlugin` | Amazon Location Service |
| Logging | `AWSCloudWatchLoggingPlugin` | Amazon CloudWatch |
| Notifications | `AWSPinpointPushNotificationsPlugin` | Amazon Pinpoint |
| Predictions | `AWSPredictionsPlugin` | Comprehend, Polly, Rekognition, Textract, Translate, Transcribe |
| Predictions | `CoreMLPredictionsPlugin` | On-device CoreML |
| Storage | `AWSS3StoragePlugin` | Amazon S3 |

#### Plugin File Organization Pattern

Each plugin follows a consistent extension-based organization:

```
AWSCognitoAuthPlugin/
├── AWSCognitoAuthPlugin.swift                  # Main class, properties, init
├── AWSCognitoAuthPlugin+Configure.swift        # Configuration logic
├── AWSCognitoAuthPlugin+Resettable.swift       # Reset/cleanup
├── AWSCognitoAuthPlugin+ClientBehavior.swift   # Category API implementation
├── AWSCognitoAuthPlugin+PluginExtension.swift  # Plugin-specific methods
├── Actions/                                     # Action implementations
├── ClientBehavior/                              # API method implementations
├── Models/                                      # Data models
├── StateMachine/                                # State management (Auth)
├── Service/                                     # AWS service layer
├── Task/                                        # Task implementations
├── Environment/                                 # DI/environment
├── CredentialStorage/                           # Credential handling
├── Support/                                     # Helpers & utilities
└── HubEvents/                                   # Hub event handling
```

> **Convention**: Extensions on the main plugin class are split into files named `PluginName+Concern.swift`.

### 3. Concurrency Model

The project primarily uses **Swift async/await** for modern concurrency:

- All category behavior protocol methods are `async throws`
- `Task` and structured concurrency used throughout
- `actor` types used for thread-safe state management (e.g., `ChildTask<>`)
- Some legacy `DispatchQueue` usage remains for specific thread-safety needs (logging, operation state)
- `OperationQueue` used in some plugins for regulated execution

When writing new code:
- **Prefer** `async/await` and Swift structured concurrency
- **Use** `actor` for mutable shared state
- **Avoid** introducing new `DispatchQueue` or callback-based patterns
- **Do not** use Combine in the core library

### 4. Error Handling

All errors conform to the `AmplifyError` protocol:

```swift
public protocol AmplifyError: Error, CustomDebugStringConvertible {
    var errorDescription: ErrorDescription { get }       // What went wrong
    var recoverySuggestion: RecoverySuggestion { get }   // How to fix it
    var underlyingError: Error? { get }                  // Root cause

    init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Error)
}
```

Category-specific error types are enums with associated values:

```swift
public enum StorageError {
    case accessDenied(ErrorDescription, RecoverySuggestion, Error? = nil)
    case authError(ErrorDescription, RecoverySuggestion, Error? = nil)
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)
    case httpStatusError(Int, RecoverySuggestion, Error? = nil)
    case keyNotFound(ErrorDescription, RecoverySuggestion, Error? = nil)
    case localFileNotFound(ErrorDescription, RecoverySuggestion, Error? = nil)
    case service(ErrorDescription, RecoverySuggestion, Error? = nil)
    case unknown(ErrorDescription, Error? = nil)
    case validation(Field, ErrorDescription, RecoverySuggestion, Error? = nil)
}
```

**Rules**:
- Every error **must** include a human-readable `errorDescription` and `recoverySuggestion`
- Wrap underlying errors rather than discarding them
- Use category-specific error types (never throw raw `Error` or generic `NSError`)
- Recovery suggestions should be actionable developer guidance

### 5. Configuration

Amplify uses a JSON-based configuration system:

```swift
// Configuration is loaded from amplifyconfiguration.json or AmplifyOutputs
Amplify.configure()

// Or programmatic configuration
let config = AmplifyConfiguration(auth: authConfig, storage: storageConfig)
try Amplify.configure(config)
```

**Configuration lifecycle**:
1. Logging configured first (all other plugins depend on it)
2. Hub and Auth configured next (other categories depend on Auth)
3. Remaining categories configured in order
4. `HubPayload.EventName.Amplify.configured` dispatched to all Hub channels

### 6. Plugin Protocol & Lifecycle

Every plugin must conform to `Plugin`:

```swift
public protocol Plugin: CategoryTypeable, Resettable {
    var key: PluginKey { get }                         // Unique identifier
    func configure(using configuration: Any?) throws   // Setup from config
}
```

And `Resettable` for test/cleanup support:

```swift
public protocol Resettable {
    func reset() async
}
```

### 7. Dependency Injection

The project uses **constructor-based and property-based injection**:

- Plugins accept optional dependencies as constructor parameters with defaults
- Internal services injected during `configure(using:)` phase
- Behavior protocols abstract service implementations (e.g., `AWSAuthCredentialsProviderBehavior`)
- `@visibleForTesting` used for test-only injection points

```swift
// Plugin accepts optional config in init
public init(configuration: AWSS3StoragePluginConfiguration = .init()) {
    self.storageConfiguration = configuration
}

// Services resolved during configure
var authService: AWSAuthCredentialsProviderBehavior!  // Injected
```

### 8. Logging

Amplify uses **OS Unified Logging** (`os.log`) via the `AWSUnifiedLoggingPlugin`:

```swift
// Each plugin accesses logging via extension
extension AWSAPIPlugin {
    var log: Logger {
        Amplify.Logging.logger(
            forCategory: CategoryType.api.displayName,
            forNamespace: String(describing: self)
        )
    }
}

// Usage
log.info("Configuring plugin")
log.debug("Request details: \(request)")
log.error("Failed to authenticate: \(error)")
```

Log levels: `error`, `warn`, `info`, `debug`, `verbose`

### 9. Hub (Event System)

Amplify has a built-in pub/sub event system called Hub:

```swift
// Dispatching events
Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: .signedIn))

// Listening for events
let token = Amplify.Hub.listen(to: .auth) { payload in
    switch payload.eventName {
    case HubPayload.EventName.Auth.signedIn:
        // Handle sign-in
    }
}
```

Hub channels correspond to categories (`.auth`, `.storage`, `.api`, etc.).

### 10. Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Source files | PascalCase matching primary type | `StorageCategory.swift` |
| Extension files | `TypeName+Concern.swift` | `AWSAPIPlugin+Configure.swift` |
| Protocols | PascalCase, descriptive suffix | `StorageCategoryBehavior` |
| Classes/Structs | PascalCase | `AmplifyConfiguration` |
| Enums | PascalCase type, camelCase cases | `StorageError.accessDenied` |
| Functions/Properties | camelCase | `downloadData(path:options:)` |
| Type aliases | PascalCase | `PluginKey`, `ErrorDescription` |
| Plugin keys | String constant | `"awsS3StoragePlugin"` |
| Test files | `<TypeUnderTest>Tests.swift` | `AWSS3StoragePluginTests.swift` |

### 11. Documentation

- **Doc comments**: Required on all public APIs using `///` style
- **Source tags**: Used for cross-referencing: `/// - Tag: StorageCategoryBehavior.getURL`
- **Cross-references**: `/// See: [AmplifyError.errorDescription](x-source-tag://AmplifyError.errorDescription)`
- **Parameter documentation**: Use `- Parameters:` and `- Returns:` in doc comments
- **Deprecation**: Use `@available(*, deprecated, message: "Use newMethod()")` with migration guidance

### 12. API Surface Stability

API surface is tracked via **API dumps** in `api-dump/`:
- `Amplify.json` — Core framework API surface
- `AWSPluginsCore.json` — Plugin core API surface
- `AWSDataStorePlugin.json` — DataStore API surface
- `CoreMLPredictionsPlugin.json` — CoreML API surface

Breaking changes are detected automatically via CI (`api_digester_check.yml`, `api-breaking-changes-detection.yml`).

**Rules**:
- New enum cases = **minor** version bump (add `default` in switch statements)
- Removing/renaming public APIs = **major** version bump (requires team approval)
- Run the API digester check before submitting PRs that modify public APIs

---

## Testing

### Test Organization

Tests are organized at multiple levels:

```
# Core unit tests (SPM test targets)
AmplifyTests/                         # Core framework tests
  ├── CoreTests/
  ├── CategoryTests/
  └── DevMenuTests/

# Plugin unit tests (SPM test targets, defined in Package.swift)
AmplifyPlugins/<Category>/Tests/<PluginName>UnitTests/

# Integration tests (Xcode projects with host apps)
AmplifyPlugins/<Category>/Tests/<Category>HostApp/
  └── <Category>HostApp.xcodeproj
```

### Unit Tests

- Framework: **XCTest**
- Async testing: **AmplifyAsyncTesting** module for async/await test helpers
- Shared utilities: **AmplifyTestCommon** and **AWSPluginsTestCommon**

Run unit tests:
```bash
# All unit tests via SPM
swift test

# Specific test target
swift test --filter AWSCognitoAuthPluginUnitTests

# Via xcodebuild (as CI does)
xcodebuild test \
  -scheme Amplify-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Unit test targets** (19 defined in Package.swift):
1. `AmplifyTests`
2. `AmplifyAsyncTestingTests`
3. `AWSPluginsCoreTests`
4. `InternalAmplifyCredentialsTests`
5. `AWSAPIPluginTests`
6. `AWSCognitoAuthPluginUnitTests`
7. `AmplifyBigIntegerTests`
8. `AWSDataStoreCategoryPluginTests`
9. `AWSS3StoragePluginTests`
10. `AWSLocationGeoPluginTests`
11. `InternalAWSPinpointUnitTests`
12. `AWSPinpointAnalyticsPluginUnitTests`
13. `AWSPinpointPushNotificationsPluginUnitTests`
14. `AWSPredictionsPluginUnitTests`
15. `CoreMLPredictionsPluginUnitTests`
16. `AWSCloudWatchLoggingPluginTests`
17. `AmplifyFoundationTests`
18. `AmplifyFoundationBridgeTests`
19. `AmplifyKinesisClientTests`

### Integration Tests

Integration tests run against real AWS services and require:
- AWS credentials/configuration
- Amplify CLI-provisioned backend resources
- Host app Xcode projects (for Keychain access)

**Host apps** (Xcode projects):
- `AmplifyPlugins/Auth/Tests/AuthHostApp/`
- `AmplifyPlugins/Auth/Tests/AuthWebAuthnApp/`
- `AmplifyPlugins/Auth/Tests/AuthHostedUIApp/`
- `AmplifyPlugins/API/Tests/APIHostApp/`
- `AmplifyPlugins/DataStore/Tests/DataStoreHostApp/`
- `AmplifyPlugins/Storage/Tests/StorageHostApp/`
- `AmplifyPlugins/Geo/Tests/GeoHostApp/`
- `AmplifyPlugins/Analytics/Tests/AnalyticsHostApp/`
- `AmplifyPlugins/Logging/Tests/AWSCloudWatchLoggingPluginHostApp/`
- `AmplifyPlugins/Notifications/Push/Tests/PushNotificationHostApp/`
- `AmplifyPlugins/Predictions/Tests/PredictionsHostApp/`

**Integration test categories** include multiple variants per service (e.g., DataStore tests with different auth modes, custom primary keys, lazy loading, multi-auth).

### Test Plans

Integration tests use `.xctestplan` files for organizing test scenarios:
- Gen2 tests (latest Amplify backend)
- Gen1 tests (legacy backend)
- Auth-specific variants (WebAuthn, HostedUI)
- DataStore variants (CPK, lazy-load, multi-auth)

### Testing Conventions

- Mock services using behavior protocols (not concrete types)
- Use `AmplifyTestCommon` for shared mock models and utilities
- Use `@testable import` for accessing internal members
- Use `AmplifyAsyncTesting` for async test assertions
- Every change requires new or updated unit tests
- Integration tests should be run for the affected category

---

## CI/CD

### GitHub Actions Workflows

The project has 60+ GitHub Actions workflows in `.github/workflows/`:

#### Build Verification
| Workflow | Purpose |
|----------|---------|
| `build_amplify_swift_platforms.yml` | Multi-platform SPM builds (iOS, macOS, tvOS, watchOS, visionOS) |
| `build_minimum_supported_swift_platforms.yml` | Minimum Swift version compatibility |
| `build_xcode_beta.yml` | Xcode beta testing |
| `build_scheme.yml` | Reusable build workflow |

#### Unit Tests
| Workflow | Purpose |
|----------|---------|
| `run_unit_tests.yml` | All unit tests |
| `run_unit_tests_platforms.yml` | Platform-specific testing |
| `nightly_unit_test.yml` | Scheduled nightly runs |
| `unit_test_amplify.yml` | Core Amplify tests |
| `unit_test_analytics.yml` | Analytics plugin tests |
| `unit_test_api.yml` | API plugin tests |
| `unit_test_auth.yml` | Auth plugin tests |
| `unit_test_core.yml` | AWSPluginsCore tests |
| `unit_test_datastore.yml` | DataStore plugin tests |
| `unit_test_geo.yml` | Geo plugin tests |
| `unit_test_logging.yml` | Logging plugin tests |
| `unit_test_predictions.yml` | Predictions plugin tests |
| `unit_test_push_notifications.yml` | Push Notifications plugin tests |
| `unit_test_storage.yml` | Storage plugin tests |
| `unit_test_internal_pinpoint.yml` | Internal Pinpoint tests |

#### Integration Tests
| Workflow | Purpose |
|----------|---------|
| `run_integration_tests.yml` | Reusable integration test framework |
| `integ_test.yml` | Orchestrates all integration tests |
| `integ_test_auth.yml` / `_webauthn.yml` | Auth integration tests |
| `integ_test_api.yml` / `_functional.yml` / `_graphql_*.yml` / `_rest_*.yml` | API integration tests (multiple variants) |
| `integ_test_datastore.yml` / `_base.yml` / `_cpk.yml` / `_lazy_load.yml` / `_multi_auth.yml` / `_v2.yml` / `_auth_cognito.yml` / `_auth_iam.yml` | DataStore integration tests |
| `integ_test_storage.yml` | Storage integration tests |
| `integ_test_geo.yml` | Geo integration tests |
| `integ_test_logging.yml` | Logging integration tests |
| `integ_test_analytics.yml` | Analytics integration tests |
| `integ_test_push_notifications.yml` | Push Notifications integration tests |
| `integ_test_predictions.yml` | Predictions integration tests |
| `integ_test_kinesis.yml` | Kinesis integration tests |

#### Code Quality
| Workflow | Purpose |
|----------|---------|
| `swiftlint.yml` | Lint checking |
| `swiftformat.yml` | Format checking |
| `api_digester_check.yml` | API surface verification |
| `api-breaking-changes-detection.yml` | Breaking change detection |
| `codeql.yml` | CodeQL security scanning |
| `dependency-review.yml` | Dependency vulnerability checks |
| `fortify_scan.yml` | Fortify security scanning |

#### Release
| Workflow | Purpose |
|----------|---------|
| `release_kickoff.yml` | Initiate release |
| `deploy_release.yml` | Deploy stable release |
| `deploy_unstable.yml` | Deploy canary/unstable |
| `deploy_package.yml` | Package deployment |
| `release_doc.yml` | Documentation generation |
| `notify_release.yml` | Release notifications |
| `upload_coverage_report.yml` | Code coverage reporting |

### Reusable Composite Actions (`.github/actions/`)
- `download_test_configuration` — Test config download
- `get_platform_parameters` — Platform-specific build parameters
- `install_simulators_if_needed` — Simulator setup
- `run_xcodebuild` — Generic Xcode build
- `run_xcodebuild_test` — Xcode test execution

### Release Process (Fastlane)

Releases are managed via Fastlane (`fastlane/Fastfile`):
- `unstable` lane — Create pre-release version
- `release` lane — Create stable release with version bump, git tag, and changelog

---

## Commit Message Conventions

This project follows [Conventional Commits](https://www.conventionalcommits.org):

```
<type>(<scope>): <description>

feat(storage): add progress stall timeout for S3 uploads
fix(api): populate the auth mode when parsing the request response
chore: update aws-swift-sdk dependency (#4171)
refactor(auth): simplify credential storage flow
test(datastore): add integration tests for multi-auth
```

**Types**: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`, `ci`

**Scopes** (category names): `auth`, `api`, `storage`, `datastore`, `geo`, `analytics`, `logging`, `predictions`, `push`, `kinesis`, `core`, `foundation`, `deps`

**Rules**:
- No period at end of title
- PR titles **must** follow Conventional Commits (changelog is auto-generated from them)
- Reference issues: `fixes #<issue>` or `closes #<issue>`
- Keep to one feature/bugfix per PR

---

## Semantic Versioning

This project follows [semantic versioning](https://semver.org/):

- **Patch** (x.y.Z): Bug fixes, dependency updates
- **Minor** (x.Y.0): New features, new enum cases (consumers should use `default` in switch statements)
- **Major** (X.0.0): Breaking API changes (rare, requires team approval)

---

## Key Design Principles

From `ETHOS.md` — these inform all code decisions:

1. **Declarative, interaction-based APIs**: Expose "what" not "how" (e.g., `uploadData` not `createMultipartUpload` + `putObject`)
2. **Opinionated implementations**: Favor best practices and optimize for cost/performance
3. **Pluggable architecture**: AWS-first but designed for alternative cloud providers
4. **Rule of Least Power**: Encourage best practices, enable quick starts
5. **Human-readable errors**: Every error includes `errorDescription` + `recoverySuggestion`
6. **Modular imports**: Each plugin is independent — avoid cross-plugin dependencies
7. **Minimal public API surface**: Mark internals as `internal` or `private`, expose only what consumers need

---

## Amplify Clients (New Building Block)

Amplify Clients are a **new architectural pattern** for building standalone AWS service clients that are **independent of the core Amplify framework**. Unlike category plugins (which require `Amplify.configure()` and the plugin registration system), Amplify Clients are self-contained, lightweight libraries that can be used directly.

### Architecture Overview

The Amplify Clients pattern is built on three layers:

```
┌──────────────────────────────────────────────────────────────┐
│  Amplify Clients  (e.g., AmplifyKinesisClient)               │
│  Public-facing AWS service clients with high-level APIs      │
│  Actor-based concurrency, local caching, retry logic         │
├──────────────────────────────────────────────────────────────┤
│  AmplifyFoundation  (Protocol Layer)                         │
│  Pure Swift protocols — zero external dependencies           │
│  Credentials, Logging, Errors, Metadata                      │
├──────────────────────────────────────────────────────────────┤
│  AmplifyFoundationBridge  (Adapter Layer)                    │
│  Translates Foundation protocols ↔ AWS SDK types             │
│  Credential adapters, User-Agent injection                   │
├──────────────────────────────────────────────────────────────┤
│  AWS SDK  (aws-sdk-swift)                                    │
│  External dependency — direct service communication          │
└──────────────────────────────────────────────────────────────┘
```

**Key difference from plugins**: Amplify Clients do NOT depend on the `Amplify` core module, `AWSPluginsCore`, or any category infrastructure. They depend only on `AmplifyFoundation`, `AmplifyFoundationBridge`, and the specific AWS SDK service package they need.

### AmplifyFoundation — Protocol Layer

**Location**: `AmplifyFoundation/Sources/`
**Dependencies**: None (pure Swift + Foundation framework only)

AmplifyFoundation provides reusable, framework-agnostic building blocks:

#### Credentials

```swift
// Pure Swift protocols — no AWS SDK dependency
public protocol AWSCredentials {
    var accessKeyId: String { get }
    var secretAccessKey: String { get }
}

public protocol AWSTemporaryCredentials: AWSCredentials {
    var sessionToken: String { get }
    var expiration: Date { get }
}

public protocol AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials
}
```

#### Logging

A broadcast-based logging system with pluggable sinks:

```swift
public protocol Logger: Sendable {
    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)
    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)
    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)
    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)
    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)
}

public protocol LogSinkBehavior: Identifiable, Sendable {
    var id: String { get }
    func isEnabled(for logLevel: LogLevel) -> Bool
    func emit(message: LogMessage)
}

public enum LogLevel: Int, Sendable, Comparable {
    case none, error, warn, info, debug, verbose
}
```

- `BroadcastLogger` routes log messages to multiple sinks simultaneously
- `AmplifyOSLogSink` is a ready-to-use sink backed by `os.log`
- Thread-safe via `DispatchQueue` for sink management

#### Error Protocol

```swift
public protocol AmplifyError: Error {
    var errorDescription: ErrorDescription { get }
    var recoverySuggestion: RecoverySuggestion { get }
    var underlyingError: Error? { get }
    init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Error?)
}
```

#### Metadata

```swift
public enum AmplifyMetadata {
    public static let version = "2.54.1"
    public static let platformName = "amplify-swift"
}
```

#### Design Principles for AmplifyFoundation

- **Zero framework coupling** — no imports of `Amplify`, `AWSPluginsCore`, or any category
- **No external dependencies** — only Foundation framework
- **Async/await first** — all credential resolution is async
- **`Sendable` everywhere** — full strict concurrency compliance
- **Extensible** — all behaviors defined as protocols

### AmplifyFoundationBridge — Adapter Layer

**Location**: `AmplifyFoundationBridge/Sources/`
**Dependencies**: `AmplifyFoundation`, `AWSClientRuntime` (from aws-sdk-swift)

The bridge translates between AmplifyFoundation protocols and AWS SDK types using adapter patterns:

#### Credential Adapters

Four bidirectional adapters for credential type conversion:

```swift
// AmplifyFoundation → AWS SDK (Smithy)
public struct FoundationToSDKCredentialsAdapter:
    AWSCredentialsProvider, AWSCredentialIdentityResolver

// AWS SDK (Smithy) → AmplifyFoundation
public struct SDKToFoundationCredentialsAdapter:
    AWSCredentialIdentityResolver, AWSCredentialsProvider

// AmplifyFoundation → AWS CRT
public struct FoundationToCRTCredentialsAdapter:
    AWSCredentialsProvider, AwsCommonRuntimeKit.CredentialsProviding

// AWS CRT → AmplifyFoundation
public struct CRTToFoundationCredentialsAdapter:
    AwsCommonRuntimeKit.CredentialsProviding, AWSCredentialsProvider
```

Each adapter conforms to **both** the Foundation and SDK protocols simultaneously, enabling seamless bidirectional conversion. Extension-based bridging auto-implements the reverse direction to minimize boilerplate.

#### User-Agent Client Engine

```swift
public struct UserAgentClientEngine: HTTPClient {
    // Wraps the underlying HTTP client to inject Amplify metadata into User-Agent headers
    // Appends "lib/amplify-swift#<version>" plus optional client metadata
    // e.g., "md/amplify-kinesis#<version>"
    public init(target: HTTPClient, additionalMetadata: [String] = [])
    public func send(request: HTTPRequest) async throws -> HTTPResponse
}
```

#### Error Type

```swift
public enum FoundationBridgeError: AmplifyError {
    case unknown(ErrorDescription, Error? = nil)
}
```

### AmplifyKinesisClient — Reference Client Implementation

**Location**: `AmplifyClients/AmplifyKinesisClient/`
**Dependencies**: `AmplifyFoundation`, `AmplifyFoundationBridge`, `SQLite.swift`, `AWSKinesis`

The Kinesis client is the first Amplify Client and serves as the **reference implementation** for the pattern. Study it when building new clients.

#### Public API

```swift
public class AmplifyKinesisClient {
    // Initialize with credentials provider and options
    public init(
        region: String,
        credentialsProvider: AWSCredentialsProvider,
        options: Options = .init()
    )

    // Record data to a Kinesis stream (cached locally first)
    public func record(data: Data, partitionKey: String, streamName: String) async throws -> RecordData

    // Flush cached records to Kinesis (with concurrent flush guard)
    public func flush() async throws -> FlushData

    // Toggle record collection
    public func enable() async
    public func disable() async

    // Clear all locally cached records
    public func clearCache() async throws -> ClearCacheData

    // Escape hatch for direct AWS SDK access
    public func getKinesisClient() -> AWSKinesis.KinesisClient
}
```

#### Configuration Options

```swift
public struct Options {
    public var cacheMaxBytes: Int           // Default: 5MB
    public var maxRetries: Int              // Default: 5
    public var flushStrategy: FlushStrategy // .interval(TimeInterval) or .none
    public var configureClient: ((inout AWSKinesis.KinesisClient.KinesisClientConfiguration) throws -> Void)?
}

public enum FlushStrategy {
    case interval(TimeInterval)  // Auto-flush on timer (default: 30s)
    case none                    // Manual flush only
}
```

#### Internal Architecture

```
AmplifyKinesisClient (public facade)
    ↓
RecordClient (actor — orchestration layer)
    ↓
┌─────────────────────────┬───────────────────────────────┐
│ RecordStorage (protocol) │ RecordSender (protocol)       │
│   ↓                      │   ↓                           │
│ SQLiteRecordStorage      │ KinesisRecordSender           │
│ (actor — local cache)    │ (wraps SDK PutRecords API)    │
└─────────────────────────┴───────────────────────────────┘
    ↓
AutoFlushScheduler (actor — periodic flush)
```

**Key implementation patterns**:

1. **Actor-based concurrency**: All internal components (`RecordClient`, `SQLiteRecordStorage`, `AutoFlushScheduler`) are actors for thread-safe isolation
2. **Strict concurrency**: Compiled with `StrictConcurrency` upcoming feature flag enabled
3. **Local SQLite caching**: Records are persisted locally before being sent to Kinesis, enabling offline support and retry
4. **Protocol-driven internals**: `RecordStorage` and `RecordSender` are protocols, making components independently testable with mocks
5. **Smart error classification**:
   - SDK/modeled errors (e.g., `ProvisionedThroughputExceededException`) → retryable, logged but don't block other streams
   - Network/storage errors → thrown to caller
6. **Batch operations**: Uses `withThrowingTaskGroup` for concurrent per-stream flushing
7. **Kinesis API constraints enforced**: Max 500 records/stream, max 10MB/stream, partition key 1–256 Unicode scalars

#### Error Handling

```swift
public enum KinesisError: AmplifyError {
    case cache(ErrorDescription, RecoverySuggestion, Error? = nil)
    case cacheLimitExceeded(ErrorDescription, RecoverySuggestion, Error? = nil)
    case validation(ErrorDescription, RecoverySuggestion, Error? = nil)
    case unknown(ErrorDescription, Error? = nil)
}
```

Internal `RecordCacheError` is mapped to public `KinesisError` via `KinesisError.from(_:)`.

#### Testing

- **Unit tests**: `AmplifyKinesisClientTests` — tests for RecordClient, AutoFlushScheduler, SQLiteRecordStorage, KinesisRecordSender
- **Integration tests**: E2E tests against real Kinesis with Cognito credentials in `Tests/IntegrationTests/`
- **Test patterns**: In-memory SQLite for fast tests, configurable mock senders for retry/error scenarios

### How to Build a New Amplify Client

Follow the Kinesis client as a reference. Here is the standard pattern:

#### 1. Create the directory structure

```
AmplifyClients/Amplify<ServiceName>Client/
├── Sources/
│   ├── Amplify<ServiceName>Client.swift    # Public facade
│   ├── Support/
│   │   ├── <ServiceName>Error.swift        # Public error type (conforms to AmplifyError)
│   │   ├── <InternalActor>.swift           # Internal actor for orchestration
│   │   ├── <Storage/Sender protocols>.swift # Testable protocol abstractions
│   │   └── <Implementations>.swift         # Concrete implementations
│   └── ...
├── Tests/
│   ├── UnitTests/
│   └── IntegrationTests/
└── README.md
```

#### 2. Add the target to Package.swift

```swift
.target(
    name: "Amplify<ServiceName>Client",
    dependencies: [
        "AmplifyFoundation",
        "AmplifyFoundationBridge",
        .product(name: "AWS<ServiceName>", package: "aws-sdk-swift")
        // Add other dependencies as needed (e.g., SQLite for caching)
    ],
    path: "AmplifyClients/Amplify<ServiceName>Client/Sources",
    swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
    ]
),
.testTarget(
    name: "Amplify<ServiceName>ClientTests",
    dependencies: ["Amplify<ServiceName>Client"],
    path: "AmplifyClients/Amplify<ServiceName>Client/Tests/UnitTests"
)
```

#### 3. Follow these architectural rules

| Rule | Details |
|------|---------|
| **No Amplify core dependency** | Import only `AmplifyFoundation` and `AmplifyFoundationBridge` — never `Amplify` or `AWSPluginsCore` |
| **Actor-based internals** | Use actors for all mutable shared state |
| **Strict concurrency** | Enable `StrictConcurrency` flag; mark all types `Sendable` |
| **Protocol-driven** | Abstract storage, network, and scheduler behind protocols for testability |
| **`AmplifyError` conformance** | Public error type must conform to `AmplifyError` with `errorDescription` + `recoverySuggestion` |
| **Credentials via Foundation** | Accept `AWSCredentialsProvider` (from AmplifyFoundation), convert via Bridge adapters |
| **User-Agent injection** | Use `UserAgentClientEngine` to append Amplify metadata to HTTP requests |
| **Escape hatch** | Provide a method to access the underlying AWS SDK client directly |
| **Configurable** | Accept an `Options` struct with sensible defaults |
| **Testable** | In-memory alternatives for storage, mock senders for network |

#### 4. Wire up credentials and User-Agent

```swift
import AmplifyFoundation
import AmplifyFoundationBridge
import AWS<ServiceName>

public class Amplify<ServiceName>Client {
    private let sdkClient: AWS<ServiceName>.<ServiceName>Client

    public init(
        region: String,
        credentialsProvider: AWSCredentialsProvider,
        options: Options = .init()
    ) {
        // Convert Foundation credentials to SDK type
        let sdkCredentials = FoundationToSDKCredentialsAdapter(provider: credentialsProvider)

        // Create SDK client with User-Agent injection
        let config = try AWS<ServiceName>.<ServiceName>Client.<ServiceName>ClientConfiguration(
            region: region,
            credentialIdentityResolver: sdkCredentials
        )
        config.httpClientEngine = UserAgentClientEngine(
            target: config.httpClientEngine,
            additionalMetadata: ["md/amplify-<service-name>#\(AmplifyMetadata.version)"]
        )

        self.sdkClient = AWS<ServiceName>.<ServiceName>Client(config: config)
    }
}
```

---

## Common Tasks for Agents

### Adding a new API to an existing category

1. Add the method signature to `Amplify/Categories/<Category>/<Category>CategoryBehavior.swift`
2. Add the method to the category routing class in `Amplify/Categories/<Category>/<Category>Category+ClientBehavior.swift`
3. Add the method to the plugin protocol (if distinct) in `Amplify/Categories/<Category>/<Category>CategoryPlugin.swift`
4. Implement the method in the plugin at `AmplifyPlugins/<Category>/Sources/<PluginName>/`
5. Add unit tests to the corresponding test target
6. Update API dump if public API surface changed

### Adding a new plugin

1. Create the plugin directory under `AmplifyPlugins/<Category>/Sources/<PluginName>/`
2. Implement the `<Category>CategoryPlugin` protocol
3. Add the target to `Package.swift`
4. Add a test target to `Package.swift`
5. Add unit tests
6. Add CI workflow for the new plugin

### Adding a new Amplify Client

See the detailed guide in the [Amplify Clients](#amplify-clients-new-building-block) section above. Summary:

1. Create directory structure under `AmplifyClients/Amplify<ServiceName>Client/`
2. Depend only on `AmplifyFoundation`, `AmplifyFoundationBridge`, and the AWS SDK service package
3. Use actors for all mutable shared state; enable `StrictConcurrency`
4. Accept `AWSCredentialsProvider` for credentials; use `UserAgentClientEngine` for HTTP
5. Create a public error enum conforming to `AmplifyError`
6. Abstract internals behind protocols for testability
7. Add target + test target to `Package.swift`
8. Add unit tests (with in-memory mocks) and integration tests
9. Add CI workflow in `.github/workflows/`

### Fixing a bug

1. Write a failing test that reproduces the bug
2. Fix the bug in the minimal way
3. Verify all existing tests pass
4. Follow commit convention: `fix(<category>): <description>`

### Running specific tests

```bash
# Run all unit tests
swift test

# Run a specific test target
swift test --filter AWSS3StoragePluginTests

# Run a specific test case
swift test --filter AWSS3StoragePluginTests/<TestClassName>/<testMethodName>

# Run integration tests (requires Xcode and host app)
xcodebuild test \
  -project AmplifyPlugins/Storage/Tests/StorageHostApp/StorageHostApp.xcodeproj \
  -scheme AWSS3StoragePluginIntegrationTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Important Files Reference

| File | Purpose |
|------|---------|
| `Package.swift` | All SPM targets, dependencies, and products |
| `.swiftlint.yml` | SwiftLint rules |
| `.swiftformat` | SwiftFormat configuration |
| `.jazzy.yaml` | Documentation generation |
| `.codecov.yml` | Coverage thresholds |
| `.github/CODEOWNERS` | Code ownership rules |
| `CONTRIBUTING.md` | Contributor guidelines |
| `ETHOS.md` | Design philosophy |
| `CHANGELOG.md` | Version history |
| `Gemfile` | Ruby dependencies (fastlane, jazzy, xcpretty) |
| `fastlane/Fastfile` | Release automation |
| `Amplify/Core/Support/AmplifyError.swift` | Base error protocol |
| `Amplify/Core/Plugin/Plugin.swift` | Base plugin protocol |
| `Amplify/Core/Configuration/AmplifyConfiguration.swift` | Configuration system |
