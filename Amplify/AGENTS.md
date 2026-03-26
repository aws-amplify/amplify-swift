# Amplify Core — Agent Guide

## Overview

`Amplify/` is the core framework that defines the public API surface. It contains **category interfaces**, **plugin protocols**, **error types**, **configuration**, and the **Hub event system**. The core module itself has zero AWS SDK dependencies — plugins (in `AmplifyPlugins/`) are where AWS SDK dependencies live.

## Category/Plugin Architecture

Amplify uses a **Category + Plugin** pattern. Each service domain (Auth, Storage, API, etc.) is a "category":

- **`<Cat>CategoryBehavior`** — protocol with client-facing API methods (all `async throws`)
- **`<Cat>CategoryPlugin`** — protocol extending `Plugin` + behavior (what plugins implement)
- **`<Cat>Category`** — concrete class routing calls to the registered plugin

```swift
public protocol StorageCategoryBehavior {
    func getURL(path: any StoragePath, options: ...) async throws -> URL
    func downloadData(path: any StoragePath, options: ...) -> StorageDownloadDataTask
    func uploadData(path: any StoragePath, data: Data, options: ...) -> StorageUploadDataTask
    func remove(path: any StoragePath, options: ...) async throws -> String
    func list(path: any StoragePath, options: ...) async throws -> StorageListResult
}

public protocol StorageCategoryPlugin: Plugin, StorageCategoryBehavior {}
```

## Directory Structure

```
Amplify/
├── Categories/          # One subdir per category
│   ├── Analytics/       # AnalyticsCategoryBehavior, AnalyticsCategoryPlugin
│   ├── API/             # APICategoryBehavior (GraphQL + REST)
│   ├── Auth/            # AuthCategoryBehavior (sign-in, sign-up, session, MFA)
│   ├── DataStore/       # DataStoreCategoryBehavior (sync, query, observe)
│   ├── Geo/             # GeoCategoryBehavior (search, maps)
│   ├── Hub/             # Built-in pub/sub event system (no plugin needed)
│   ├── Logging/         # LoggingCategoryBehavior
│   ├── Notifications/   # Push notification behavior
│   ├── Predictions/     # ML prediction behavior (text, vision, speech)
│   └── Storage/         # StorageCategoryBehavior (upload, download, list)
├── Core/
│   ├── Category/        # Base Category protocol
│   ├── Configuration/   # AmplifyConfiguration, category configs
│   ├── Error/           # ConfigurationError, PluginError
│   ├── Internal/        # Private utilities
│   ├── Model/           # Model, Schema, Field definitions (DataStore)
│   ├── Plugin/          # Plugin protocol, PluginKey, Resettable
│   └── Support/         # AmplifyError protocol, utilities
├── DefaultPlugins/      # Built-in default plugin implementations
└── DevMenu/             # Developer debug menu
```

## Plugin Protocol

Every plugin must conform to:

```swift
public protocol Plugin: CategoryTypeable, Resettable {
    var key: PluginKey { get }
    func configure(using configuration: Any?) throws
}

public protocol Resettable {
    func reset() async
}
```

## Error Handling

All errors conform to `AmplifyError`:

```swift
public protocol AmplifyError: Error, CustomDebugStringConvertible {
    var errorDescription: ErrorDescription { get }
    var recoverySuggestion: RecoverySuggestion { get }
    var underlyingError: Error? { get }
    init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Error)
}
```

Category errors are enums with associated values (e.g., `StorageError.accessDenied(desc, suggestion, error?)`). Always include actionable recovery suggestions. Wrap underlying errors; never discard them.

## Configuration Lifecycle

1. `Amplify.configure()` loads from `amplifyconfiguration.json` or programmatic config
2. Logging configured **first** (all plugins depend on it)
3. Hub and Auth configured **next** (other categories depend on Auth)
4. Remaining categories configured in order
5. `HubPayload.EventName.Amplify.configured` dispatched to all Hub channels

## Hub (Event System)

Built-in pub/sub — no plugin required:

```swift
Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: .signedIn))
let token = Amplify.Hub.listen(to: .auth) { payload in ... }
```

## Naming & Documentation Conventions

- Extensions split into `TypeName+Concern.swift` files
- Doc comments required on all public APIs (`///` style)
- Source tags: `/// - Tag: StorageCategoryBehavior.getURL`
- Deprecation: `@available(*, deprecated, message: "Use newMethod()")`

## API Surface Stability

API dumps in `api-dump/*.json` track the public surface. Breaking changes detected by CI (`api_digester_check.yml`). New enum cases = minor bump; removing/renaming public APIs = major bump (needs approval).

## Adding a New API to a Category

1. Add method to `Categories/<Cat>/<Cat>CategoryBehavior.swift`
2. Add routing in `Categories/<Cat>/<Cat>Category+ClientBehavior.swift`
3. Update plugin protocol if distinct
4. Implement in the plugin (see `AmplifyPlugins/AGENTS.md`)
5. Add tests, update API dump
