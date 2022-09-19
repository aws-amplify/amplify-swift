# Combine support in Amplify

<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >

Amplify supports iOS 13+ and macOS 10.15+, and ships with APIs that leverage Swift Concurrenty (async/await) to return values, as in:

```swift
Amplify.DataStore.save(Post(title: "My Post", content: "My content", ...), completion: { result in
    switch result {
        case .success:
            print("Post saved")
        case .failure(let dataStoreError):
            print("An error occurred saving the post: \(dataStoreError)")
    }
})
```

If your project declares platform support of iOS 13 or higher, Amplify also provides APIs that expose [Combine](https://developer.apple.com/documentation/combine) Publishers, which allows you to use familiar Combine patterns, as in:

```swift
Amplify.DataStore.save(Post(title: "My Post", content: "My content"))
    .sink { completion in
        if case .failure(let dataStoreError) = completion {
            print("An error occurred saving the post: \(dataStoreError)")
        }
    }
    receiveValue: { value in
        print("Post saved: \(value)")
    }
```

While this doesn't save much for a single invocation, it provides great readability benefits when chaining asynchronous calls, since you can use standard Combine operators and publishers to compose complex functionality into readable chunks:

```swift
subscription = Publishers.Zip(
    Amplify.DataStore.save(Person(name: "Rey")),
    Amplify.DataStore.save(Person(name: "Kylo"))
).flatMap { hero, villain in
    Amplify.DataStore.save(EpicBattle(hero: hero, villain: villain))
}.flatMap { battle in
    Publishers.Zip(
        Amplify.DataStore.save(
            Outcome(of: battle)
        ),
        Amplify.DataStore.save(
            Checkpoint()
        )
    )
}.sink { completion in
    if case .failure(let dataStoreError) = completion {
        print("An error occurred in a preceding operation: \(dataStoreError)")
    }
}
receiveValue: { _ in
    print("Everything completed successfully")
}
```

Compared to nesting these dependent calls in callbacks, this provides a much more readable pattern.

**NOTE**: Remember that Combine publishers do not retain `sink` subscriptions, so you must maintain a reference to the subscription in your code, such as in an instance variable of the enclosing type:

```swift
class MyAppCode {
    var subscription: AnyCancellable?

    ...

    func doSomething() {
        // Subscription is retained by the `self.subscription` instance
        // variable, so the `sink` code will be executed
        subscription = Amplify.DataStore.save(Person(name: "Rey"))
            .sink(...)
    }
}
```

## Installation

There is no additional work needed to enable Combine support. Projects that declare a deployment target of iOS 13.0 or higher will automatically see the appropriate method signatures and properties, depending on the Category and API you are calling.

## API Comparison: APIs that return operations vs. listener-only APIs

Amplify strives to provide an intuitive interface for APIs that expose Combine functionality by overloading the no-Combine API signature, minus the result callbacks. Thus, `Amplify.DataStore.save(_:where:completion:)` has an equivalent Combine-supporting API of `Amplify.DataStore.save(_:where:)`. In most cases, the Result callback `Success` and `Failure` types in standard Amplify APIs translate exactly to the `Output` and `Failure` types of publishers returned from Combine-supporting APIs.

The way to get to a Combine publisher for a given API varies depending on whether the asynchronous work can be cancelled or not:

- APIs that **do not** return an operation simply return an `AnyPublisher` directly from the API call:
    ```swift
    let publisher = Amplify.DataStore
        .save(myPost)
    ```

- Most APIs that **do** return an operation for cancellability expose a `resultPublisher` property on the returned operation
    ```swift
    let publisher = Amplify.Predictions
        .convert(textToSpeech: text, options: options)
        .resultPublisher
    ```

### Special cases

Not all APIs map neatly to the `resultPublisher` pattern. While this asymmetry increases the mental overhead of learning to use Amplify with Combine, the ease of use at the call site should make up for the additional learning curve. In addition, Xcode will show the available publisher properties, making it easier to discover which publisher you need:

![image](readme-images/combine-xcode.png?raw=true)

#### `API.subscribe()`

The `API.subscribe()` method exposes a `subscriptionDataPublisher` for the stream of subscription data, and a `connectionStatePublisher` for the status of the underlying connection. Many apps will only need to use the `subscriptionDataPublisher`, since a closed GraphQL subscription will be reported as a completion on that publisher. The `connectionStatePublisher` exists for apps that need to inspect when the connection initially begins, even if data has not yet been received by that subscription.

#### `Hub.publisher(for:)`

The Amplify Hub category exposes only one Combine-related API: `Hub.publisher(for:)`, which returns a publisher for all events on a given channel. You can then apply the standard Combine [`filter`](https://developer.apple.com/documentation/combine/anypublisher/filter(_:)) operator to inspect only those events you care about.

#### `Storage` upload & download operations

Storage upload and download APIs report both completion and overall operation progress. In addition to the typical `resultPublisher` that reports the overall status of the operation, Storage upload and download APIs also have a `progressPublisher` that reports incremental progress when available.

## Cancelling operations

Most Amplify APIs return a use-case specific Operation that you may use to cancel an in-process operation. On iOS 13 and above, those Operations contain publishers to report values back to the app.

Cancelling a subscription to a publisher simply releases that publisher, but does not affect the work in the underlying operation. For example, say you start a file upload on a view in your app:

```swift
import Combine

class MyView: UIView {

// Declare instance properties to retain the operation and subscription cancellables
var uploadOperation: StorageUploadFileOperation?
var resultSink: AnyCancellable?
var progressSink: AnyCancellable?

// Then when you start the operation, assign those instance properties
func uploadFile() {
    uploadOperation = Amplify.Storage.uploadFile(key: fileNameKey, local: filename)

    resultSink = uploadOperation
        .resultPublisher
        .sink(
            receiveCompletion: { completion in
                if case .failure(let storageError) = completion {
                    handleUploadError(storageError)
                }
            }, receiveValue: { print("File successfully uploaded: \($0)") }
        )

    progressSink = uploadOperation
        .progressPublisher
        .sink{ print("\($0.fractionCompleted * 100)% completed") }
}
```

After you call `uploadFile()` as above, your containing class retains a reference to the operation that is actually performing the upload, as well as Combine `AnyCancellable`s that can be used to stop receiving result and progress events.

To cancel the upload (for example, in response to the user pressing a **Cancel** button), you simply call `cancel()` on the upload operation:

```swift
func cancelUpload() {
    // Automatically sends a completion to `resultPublisher` and `progressPublisher`
    uploadOperation.cancel()
}
```

If you navigate away from `MyView`, the `uploadOperation`, `resultSink`, and `progressSink` instance variables will be released, and you will no longer receive progress or result updates on those sinks, but Amplify will continue to process the upload operation.

## Examples

### `API.get(request:)`

```swift
let operation = Amplify.API.get(request: getRequest)
sink = operation
    .resultPublisher
    .sink {
        if case .failure(let apiError) = $0 {
            print("Error uploading: \(apiError)")
        }
    }
    receiveValue: { print("Data received: \($0)") }
```

### `API.subscribe(request:)`

```swift
let operation = Amplify.API.subscribe(request: subscribeRequest)
sink = operation
    .subscriptionDataPublisher
    .sink { completion in
        print("Subscription disconnected")
    }
    receiveValue: { graphQLResult in
        switch graphQLResult {
        case .failure(let graphQLError):
            print("Error decoding subscription data: \(graphQLError)")
        case .success(let value):
            print("Received subscription data: \(value)")
        }
    }
```

### `Auth.signUp(username:,password:)`

```swift
sink = Amplify.Auth.signUp(username: username, password: password)
    .resultPublisher
    .sink {
        if case let .failure(error) = $0 {
            print("Error signing up: \(error)")
        }
    }
    receiveValue: { result in print("Successful result: \(result)") }
```

### `DataStore.save(_:)`

```swift
let post = Post(
    title: "My post",
    content: "Here is my new post",
    createdAt: Temporal.DateTime.now()
)
let comment1 = Comment(
    content: "Here is comment 1",
    createdAt: Temporal.DateTime.now(),
    post: post
)
let comment2 = Comment(
    content: "Here is comment 2",
    createdAt: Temporal.DateTime.now(),
    post: post
)

sink = Amplify.DataStore.save(post)
    .flatMap { post in
        Publishers.Zip(
            Amplify.DataStore.save(comment1),
            Amplify.DataStore.save(comment2)
        )
    }
    .sink {
        if case let .failure(error) = $0 {
            print("Error saving post and comments: \(error)")
        }
    }
    receiveValue: { _ in print("Post and comment saved successfully") }
```

### `Hub.publisher(for:)`

```swift
sink = Amplify.Hub.publisher(for: .auth)
    .filter { $0.eventName == HubPayload.EventName.Auth.signedIn }
    .sink { print("User is now signed in") }
```

### `Predictions.convert(textToSpeech:)`

```swift
sink = Amplify.Predictions.convert(textToSpeech: "Hello world")
    .resultPublisher
    .sink {
        if case let .failure(error) = $0 {
            print("Error converting: \(error)")
        }
    }
    receiveValue: { result in print("Successful result: \(result)") }
```

### `Storage.uploadFile(key:local:)`

```swift
sink = Amplify.Storage.uploadFile(key: fileNameKey, local: fileName)
    .resultPublisher
    .sink {
        if case let .failure(error) = $0 {
            print("Error uploading: \(error)")
        }
    }
    receiveValue: { result in print("Successful result: \(result)") }
```
