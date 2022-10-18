# Upgrade Guide: Amplify Library for Swift

As part of the latest version of Amplify Library for Swift, we have re-written our APIs to support idiomatic Swift features. 

### Structured Concurrency (async/await pattern)

All our APIs have been refactored to follow the async/await structured concurrency pattern. The following is an example of how you would implement Sign-In for your authentication flows:

v1 - Callback api

```
func signIn(username: String, password: String) {
    Amplify.Auth.signIn(username: username, password: password) { result in
        switch result {
        case .success:
            print("Sign in succeeded")
        case .failure(let error):
            print("Sign in failed \(error)")
        }
    }
}
```

v2 - Async/Await

```
func signIn(username: String, password: String) async throws {
    let signInResult = try await Amplify.Auth.signIn(
        username: username, 
        password: password
    )
    if signInResult.isSignedIn {
        print("Sign in succeeded")
    }
}
```

### Combine support

Support for combine apis was also changed in the v2. You can read more about the changes in the dedicated doc here - 
https://github.com/aws-amplify/amplify-swift/blob/main/README-combine-support.md

For detailed definitions of all the Amplify features available in this version, please refer to o[ur latest v2 documentation](https://docs.amplify.aws/lib/q/platform/ios/).

### Predictions

Currently, we do not have an upgrade plan for predictions APIs. We will keep this guide updated when we have more information on this.

### Escape Hatch

With Amplify Library for Swift, we have also changed the way you access the underlying SDK. You now have access to the AWS SDK for Swift and the following is an example on how you would SDK calls via Amplify.

```
`import AWSPinpointAnalyticsPlugin`

do {
    // Retrieve the reference to AWSPinpointAnalyticsPlugin
    let plugin = try Amplify.Analytics.getPlugin(for: "awsPinpointAnalyticsPlugin")
    guard let analyticsPlugin = plugin as? AWSPinpointAnalyticsPlugin else {
        return
    }
    
    // Retrieve the reference to PinpointClientProtocol from AWS SDK for Swift
    let pinpointClient = analyticsPlugin.getEscapeHatch()

    // Make requests using pinpointClient...
    // ...
} catch {
    print("Get escape hatch failed with error - \(error)")
}
```

**Note:** While the Amplify Library for Swift is production ready, please note that the underlying AWS SDK for Swift is currently in Developer Preview, and is not yet intended for production workloads. [Here is additional reading material](https://github.com/awslabs/aws-sdk-swift/blob/main/docs/stability.md) on the stability of the SDK.
