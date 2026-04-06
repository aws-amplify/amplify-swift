# AmplifyPlugins — Agent Guide

## Overview

`AmplifyPlugins/` contains all AWS service plugin implementations. Each plugin implements a category behavior protocol from `Amplify/Categories/` and provides the concrete AWS integration.

## Plugin Map

| Directory | Plugin | AWS Service | Category |
|-----------|--------|-------------|----------|
| `Analytics/` | `AWSPinpointAnalyticsPlugin` | Amazon Pinpoint | Analytics |
| `API/` | `AWSAPIPlugin` | AppSync (GraphQL) + API Gateway (REST) | API |
| `Auth/` | `AWSCognitoAuthPlugin` | Amazon Cognito | Auth |
| `DataStore/` | `AWSDataStorePlugin` | AppSync + local SQLite | DataStore |
| `Geo/` | `AWSLocationGeoPlugin` | Amazon Location Service | Geo |
| `Internal/` | `InternalAWSPinpoint` | Amazon Pinpoint (shared) | Internal |
| `Logging/` | `AWSCloudWatchLoggingPlugin` | Amazon CloudWatch | Logging |
| `Notifications/` | `AWSPinpointPushNotificationsPlugin` | Amazon Pinpoint | Push |
| `Predictions/` | `AWSPredictionsPlugin` | Comprehend, Polly, Rekognition, Textract, Translate, Transcribe | Predictions |
| `Predictions/` | `CoreMLPredictionsPlugin` | On-device CoreML | Predictions |
| `Storage/` | `AWSS3StoragePlugin` | Amazon S3 | Storage |
| `Core/` | `AWSPluginsCore`, `InternalAmplifyCredentials` | Shared plugin infra | Core |

## Plugin File Organization

Every plugin follows an extension-based pattern:

```
<PluginName>/
├── <PluginName>.swift                  # Main class, properties, init
├── <PluginName>+Configure.swift        # Configuration logic
├── <PluginName>+Resettable.swift       # Reset/cleanup
├── <PluginName>+ClientBehavior.swift   # Category API implementation
├── Actions/                             # Discrete action implementations
├── ClientBehavior/                      # API method implementations
├── Models/                              # Data models
├── Service/                             # AWS service layer
├── Support/                             # Helpers & utilities
└── ...                                  # Plugin-specific dirs (StateMachine, Task, etc.)
```

**Convention**: Extensions on the main plugin class → `PluginName+Concern.swift`

## Dependency Injection

- Constructor-based with optional parameters and defaults
- Services injected during `configure(using:)` phase
- Behavior protocols abstract AWS service calls (e.g., `AWSAuthCredentialsProviderBehavior`)
- `@visibleForTesting` for test-only injection points

## Logging

Each plugin accesses logging via extension pattern:

```swift
extension AWSAPIPlugin {
    var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName,
                               forNamespace: String(describing: self))
    }
}
```

## Testing

**Unit tests**: `AmplifyPlugins/<Category>/Tests/<PluginName>UnitTests/` (SPM test targets)

**Integration tests**: `AmplifyPlugins/<Category>/Tests/<Category>HostApp/` (Xcode projects) — require AWS credentials and provisioned backends. Multiple test plan variants per category (Gen1, Gen2, auth modes, etc.).

Mock services using behavior protocols, not concrete types. Use `AWSPluginsTestCommon` for shared plugin test utilities.

## Adding a New Plugin

1. Create `AmplifyPlugins/<Category>/Sources/<PluginName>/`
2. Implement `<Category>CategoryPlugin` protocol (inherits `Plugin` + behavior)
3. Follow extension-based file organization above
4. Add target + test target to root `Package.swift`
5. Add unit tests with mocked service layer
6. Add integration test host app if needed
7. Add CI workflow in `.github/workflows/`

## Auth Plugin Notes

The Auth plugin (`AWSCognitoAuthPlugin`) is the most complex — it includes:
- SRP protocol implementation (`AmplifySRP`, `AmplifyBigInteger`, `libtommath`)
- State machine architecture for auth flows
- WebAuthn and HostedUI support
- Credential storage and keychain integration
