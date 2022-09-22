# Combine support in Amplify

<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >

Amplify supports iOS 13+ and macOS 10.15+, and ships with APIs that leverage Swift Concurrenty (async/await) to return values. For example, the following returns an array of type `Geo.Place` with search results for coffee shops.

```swift
let places = try await Amplify.Geo.search(for "coffee")
```

Some APIs do not return a simple result, such as those that return subscriptions or provide progress updates. In cases where multiple values are expected over time, Amplify typically provides an `AmplifyAsyncSequence` or `AmplifyAsyncThrowingSequence`. These types conform to the `AsyncSequence` protocol and can be iterated over asyncronously. For example, the following subscribes to the creation of new Todos.

```swift
let subscription = try await Amplify.API.subscribe(
    request: .subscription(of: Todo.self, type: .onCreate)
)
```

## Amplify.Publisher

In order to support Combine, Amplify includes Amplify.Publisher, which can be used to get Combine Publishers for Amplify APIs, such as those listed above. Specifically, it provides static methods to create Combine Publishers from Tasks and AsyncSequences.

The following examples show how to create Combine Publishers for the above API calls.

```swift
let sink = Amplify.Publisher.create {
    try await Amplify.Geo.search(for "coffee")
}
    .sink { completion in
        // handle completion
    } receiveValue: { value in
        // handle value
    }
```

```swift
let subscription = Amplify.API.subscribe(
    request: .subscription(of: Todo.self, type: .onCreate)
)

let sink = Amplify.Publisher.create(subscription)
    .sink { completion in
        // handle completion
    } receiveValue: { value in
        // handle value
    }
```


#### Cancellation

When using Amplify.Publisher, cancelling a subscription to a publisher also cancels the underlying task. Note, however, that in the case of progress sequences, this would only cancel progress updates, and not the associated task such as a file upload or download. Those associated tasks would need to be cancelled separately, either by calling `.cancel()` on the task itself or by cancelling the parent task.

## Hub.publisher(for:)

The Amplify Hub category exposes only one Combine-related API: `Hub.publisher(for:)`, which returns a publisher for all events on a given channel. You can then apply the standard Combine [`filter`](https://developer.apple.com/documentation/combine/anypublisher/filter(_:)) operator to inspect only those events you care about.
