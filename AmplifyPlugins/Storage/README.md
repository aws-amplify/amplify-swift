# AWS S3 Storage Plugin

Amplify Storage plugin for Amazon S3. Manages content in public, protected, and private storage buckets.

## Configuration

### Plugin initialization

```swift
try Amplify.add(plugin: AWSS3StoragePlugin(
    configuration: AWSS3StoragePluginConfiguration(
        progressStallTimeoutInterval: 10
    )
))
```

### progressStallTimeoutInterval

When upload progress does not advance for the specified number of seconds (e.g. due to network issues), the upload is cancelled and the completion handler receives an error.

- **Type:** `TimeInterval`
- **Default:** `0` (disabled)
- **Behavior:** A timer starts at upload start and resets on each progress callback. If no progress arrives within the interval, the upload is aborted.

Recommended values: 10–60 seconds depending on expected network conditions. Set to `0` to keep the previous behavior (no timeout).

```swift
// Disabled (default)
AWSS3StoragePluginConfiguration(progressStallTimeoutInterval: 0)

// 10 second timeout
AWSS3StoragePluginConfiguration(progressStallTimeoutInterval: 10)
```

### Detecting stall timeout errors

When an upload fails due to progress stall timeout, the error is wrapped in `StorageError` with the underlying cause preserved. To detect this case:

```swift
if let storageError = error as? StorageError,
   let underlying = storageError.underlyingError as NSError?,
   underlying.domain == "com.amazonaws.AWSS3TransferUtilityErrorDomain",
   underlying.code == 10 {
    // Progress stall timeout - consider retrying or informing the user
}
```

Alternatively, check the error description for `"progress did not advance"` or `"timeout"`.

### Per-bucket configuration

When using Amplify configuration files (e.g. `amplify_outputs.json`), the stall timeout is applied to the default bucket. For programmatic configuration with multiple buckets, use `StorageConfiguration(forBucket:progressStallTimeoutInterval:)`.
