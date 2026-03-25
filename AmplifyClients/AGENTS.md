# AmplifyClients — Agent Guide

## Overview

Amplify Clients are **standalone AWS service clients** independent of the core `Amplify` framework. Unlike category plugins (which require `Amplify.configure()` and the plugin system), Amplify Clients are self-contained libraries that can be used directly.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Amplify Clients  (e.g., AmplifyKinesisClient)          │
│  High-level APIs, actor-based, local caching, retry     │
├─────────────────────────────────────────────────────────┤
│  AmplifyFoundation  (Protocol Layer)                    │
│  Pure Swift protocols — zero external deps              │
│  Credentials, Logging, Errors, Metadata                 │
├─────────────────────────────────────────────────────────┤
│  AmplifyFoundationBridge  (Adapter Layer)               │
│  Foundation ↔ AWS SDK type adapters                     │
│  Credential converters, User-Agent injection            │
├─────────────────────────────────────────────────────────┤
│  AWS SDK  (aws-sdk-swift)                               │
└─────────────────────────────────────────────────────────┘
```

**Key rule**: Clients depend on `AmplifyFoundation` + `AmplifyFoundationBridge` only — never on `Amplify` or `AWSPluginsCore`.

## AmplifyFoundation (`AmplifyFoundation/Sources/`)

Zero-dependency protocol layer providing:

**Credentials** — `AWSCredentials`, `AWSTemporaryCredentials`, `AWSCredentialsProvider` (async resolution)

**Logging** — `Logger` protocol with `error`/`warn`/`info`/`debug`/`verbose` levels. `BroadcastLogger` routes to multiple `LogSinkBehavior` sinks. `AmplifyOSLogSink` provides os.log integration.

**Errors** — `AmplifyError` protocol requiring `errorDescription` + `recoverySuggestion` + `underlyingError`

**Metadata** — `AmplifyMetadata.version` and `.platformName`

Design: zero framework coupling, no external deps, async/await first, `Sendable` everywhere.

## AmplifyFoundationBridge (`AmplifyFoundationBridge/Sources/`)

Depends on: `AmplifyFoundation`, `AWSClientRuntime`

**Credential adapters** — Four bidirectional adapters:
- `FoundationToSDKCredentialsAdapter` / `SDKToFoundationCredentialsAdapter` (Smithy)
- `FoundationToCRTCredentialsAdapter` / `CRTToFoundationCredentialsAdapter` (CRT)

Each conforms to both Foundation and SDK protocols simultaneously.

**`UserAgentClientEngine`** — HTTP client wrapper that injects `lib/amplify-swift#<version>` into User-Agent headers.

## AmplifyKinesisClient (Reference Implementation)

Location: `AmplifyClients/AmplifyKinesisClient/`
Deps: `AmplifyFoundation`, `AmplifyFoundationBridge`, `SQLite.swift`, `AWSKinesis`

### Public API

```swift
public class AmplifyKinesisClient {
    init(region: String, credentialsProvider: AWSCredentialsProvider, options: Options)
    func record(data: Data, partitionKey: String, streamName: String) async throws -> RecordData
    func flush() async throws -> FlushData
    func enable() async / func disable() async
    func clearCache() async throws -> ClearCacheData
    func getKinesisClient() -> AWSKinesis.KinesisClient  // escape hatch
}
```

### Internal Architecture

```
AmplifyKinesisClient (public facade)
  → RecordClient (actor — orchestration, flush guard)
    → RecordStorage (protocol) ← SQLiteRecordStorage (actor, local cache)
    → RecordSender (protocol)  ← KinesisRecordSender (wraps SDK PutRecords)
    → AutoFlushScheduler (actor — periodic flush timer)
```

### Key Patterns

- **All actors**: RecordClient, SQLiteRecordStorage, AutoFlushScheduler — strict concurrency enabled
- **SQLite caching**: Records persisted locally before sending; enables offline + retry
- **Protocol-driven**: Storage and sender abstracted for testability (in-memory SQLite, mock senders)
- **Smart error handling**: SDK errors → logged, don't block other streams. Network errors → thrown to caller
- **Kinesis constraints enforced**: 500 records/stream, 10MB/stream, partition key 1–256 Unicode scalars
- **Concurrent flush guard**: `isFlushing` flag prevents overlapping flushes

### Error Type

```swift
public enum KinesisError: AmplifyError {
    case cache(ErrorDescription, RecoverySuggestion, Error?)
    case cacheLimitExceeded(ErrorDescription, RecoverySuggestion, Error?)
    case validation(ErrorDescription, RecoverySuggestion, Error?)
    case unknown(ErrorDescription, Error?)
}
```

## Building a New Amplify Client

### Directory structure

```
AmplifyClients/Amplify<Service>Client/
├── Sources/
│   ├── Amplify<Service>Client.swift      # Public facade
│   └── Support/                           # Error type, actors, protocols, impls
├── Tests/
│   ├── UnitTests/
│   └── IntegrationTests/
```

### Package.swift target

```swift
.target(
    name: "Amplify<Service>Client",
    dependencies: ["AmplifyFoundation", "AmplifyFoundationBridge",
                    .product(name: "AWS<Service>", package: "aws-sdk-swift")],
    path: "AmplifyClients/Amplify<Service>Client/Sources",
    swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
)
```

### Architectural rules

| Rule | Details |
|------|---------|
| No Amplify core dep | Import `AmplifyFoundation` + `AmplifyFoundationBridge` only |
| Actor internals | All mutable shared state in actors |
| Strict concurrency | Enable flag, all types `Sendable` |
| Protocol-driven | Abstract storage/network/scheduler behind protocols |
| `AmplifyError` errors | Public error enum with `errorDescription` + `recoverySuggestion` |
| Credentials via Foundation | Accept `AWSCredentialsProvider`, convert via Bridge adapters |
| User-Agent injection | Use `UserAgentClientEngine` for HTTP requests |
| Escape hatch | Expose the underlying AWS SDK client |
| Configurable | `Options` struct with sensible defaults |
| Testable | In-memory storage alternatives, mock senders |

### Wiring credentials + User-Agent

```swift
let sdkCredentials = FoundationToSDKCredentialsAdapter(provider: credentialsProvider)
var config = try AWS<Service>.<Service>Client.<Service>ClientConfiguration(
    region: region, credentialIdentityResolver: sdkCredentials
)
config.httpClientEngine = UserAgentClientEngine(
    target: config.httpClientEngine,
    additionalMetadata: ["md/amplify-<service>#\(AmplifyMetadata.version)"]
)
```
