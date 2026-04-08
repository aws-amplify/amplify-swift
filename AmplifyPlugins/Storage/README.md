# AWS S3 Storage Plugin

Amplify Storage plugin for Amazon S3. Manages content in public, protected, and private storage buckets.

## Configuration

### Plugin initialization

```swift
try Amplify.add(plugin: AWSS3StoragePlugin(
    configuration: AWSS3StoragePluginConfiguration(
        progressStallTimeout: .interval(30)
    )
))
```

### progressStallTimeout

Uses `ProgressStallTimeout` (same pattern as flush strategies in other Amplify clients):

- `.disabled` — do not cancel when progress stalls (default).
- `.interval(seconds)` — cancel if progress does not advance within the given duration.

### Per-upload override

Use `progressStallTimeout` on `StorageUploadFileRequest.Options` or `StorageUploadDataRequest.Options`. Pass `nil` to use the plugin default. Pass `.disabled` to turn off stall detection for that upload even when the plugin default is `.interval(...)`.

```swift
// Plugin default: 30s
let plugin = AWSS3StoragePlugin(
    configuration: AWSS3StoragePluginConfiguration(progressStallTimeout: .interval(30))
)

// Override for a large upload: 120s
let options = StorageUploadFileRequest.Options(progressStallTimeout: .interval(120))
try await Amplify.Storage.uploadFile(path: path, local: url, options: options)
```

### Detecting stall timeout errors

When an upload fails due to progress stall timeout, the completion handler receives `StorageError.unknown` with this message:

```swift
if case .unknown("Upload cancelled due to progress stall timeout.", _) = error as? StorageError {
    // Progress stall timeout
}
```

### Recovered uploads

Multipart sessions restored from the transfer database use the storage service configuration for stall timeout (per-operation overrides are not persisted).
