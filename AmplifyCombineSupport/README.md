# Combine support for Amplify for iOS

<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >

The default Amplify library for iOS supports iOS 11 and higher, and ships with APIs that return results on `Result` callbacks, as in:

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

The AmplifyCombineSupport module extends the base Amplify categories with APIs that return appropriate Combine publishers, which allow developers to use familiar Combine patterns, as in:

```swift
Amplify.DataStore.save(Post(title: "My Post", content: "My content", ...))
    .sink(
        receiveCompletion: { completion in
            if case .failure(let dataStoreError) = completion {
                print("An error occurred saving the post: \(dataStoreError)")
            }
        }, receiveValue: { value in
            print("Post saved")
        }
    )
```

While this doesn't save much for a single invocation, it provides great readability benefits when chaining asynchronous calls, since you can use standard Combine publishers to compose complex functionality into readable chunks:

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
}.sink(receiveCompletion: { completion in
    if case .failure(let dataStoreError) = completion {
        print("An error occurred during one of the preceding operations: \(dataStoreError)")
    }
}, receiveValue: { _ in
    print("Everything completed successfully")
})
```

Compared to nesting these dependent calls in callbacks, this provides a much more readable pattern.

**NOTE**: Remember that Combine `sink` subscriptions are not retained by the publishers, so you must maintain a reference to the subscription in your code, such as in an instance variable of the enclosing type:

```swift
struct MyAppCode {
    var subscription AnyCancellable?

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

Install from CocoaPods by adding the pod to your Podfile:

```ruby
pod 'Amplify'
pod 'AmplifyCombineSupport'
# ... other pods, such as Amplify plugins
```

## Usage

Use in your projects by importing the AmplifyCombineSupport module alongside Amplify and AmplifyPlugins:

```swift
import Amplify
import AmplifyPlugins
import AmplifyCombineSupport
```

## API Comparison: Standard Amplify vs. AmplifyCombineSupport

`AmplifyCombineSupport` strives to provide the same API signature and call patterns as vanilla Amplify, minus the result callbacks. Thus, `Amplify.DataStore.save(_:where:completion:)` has an `AmplifyCombineSupport` equivalent of `Amplify.DataStore.save(_:where:)`. Similarly, the types used in result callbacks in standard Amplify APIs translate logically to the `Output` and `Failure` types of `AnyPublisher`s returned from `AmplifyCombineSupport` APIs.

### APIs with in-process listeners
APIs that accept both an "in process" and "result" listener have a CombineSupport flavor that returns a category-specific struct containing both an "in process" and "result" publisher. Callers can subscribe to either or both, as in this example for the Storage category:

```swift
let publisher = Amplify.Storage.downloadData(key: "myObject")
let progressSubscription = publisher.progressPublisher.sink { print($0.fractionCompleted) }
let resultSubscription = publisher.resultPublisher.sink(
    receiveCompletion: { print("Download completed: \($0)") },
    receiveValue: { print("Data downloaded: \($0)") }
)
```

The names of the "in process" and "result" publishers vary by API category, to reflect their use case.

### APIs that return operations

The Standard Amplify flavor of most APIs returns a use-case specific Operation that may be used to cancel an in-progress operation. The `AmplifyCombineSupport` APIs do not support cancellation of the operation. Canceling a subscription to a publisher simply releases that publisher, but does not affect the work in the underlying operation.

If your use case requires both Combine-style publisher support and cancellation, you can adapt the standard API, as in this example for the Storage category:

```swift
let progressSubject = PassthroughSubject<Progress, Never>()
let resultSubject = PassthroughSubject<Data, StorageError>()

let progressListener: ProgressListener = {
    progressSubject.send($0)
}

let downloadOperation = Amplify.Storage.downloadData(
    key: "myObject",
    progressListener: progressListener
) { result in
        progressSubject.send(completion: .finished)
    switch result {
    case .failure(let storageError):
        resultSubject.send(completion: .failure(storageError))
    case .success(let data):
        resultSubject.send(data)
        resultSubject.send(completion: .finished)
    }
}

let progressSubscription = progressSubject.sink { print($0.fractionCompleted) }
let resultSubscription = resultSubject.sink(
    receiveCompletion: { print("Download completed: \($0)") },
    receiveValue: { print("Data downloaded: \($0)") }
)

progressSubscription.cancel() // Only cancels subscription, download is still progressing
resultSubscription.cancel() // Only cancels subscription, download is still progressing
downloadOperation.cancel() // Cancels download
```

## Category reference

---
API
---

**GraphQL APIs**

### New Typealiases

```swift
/// A publisher that returns values from `query` and `mutate` GraphQL operations
public typealias GraphQLPublisher<R: Decodable> = AnyPublisher<
    GraphQLResponse<R>,
    APIError
>

/// A publisher that returns values from a GraphQL `subscribe` operation. Subscription events delivered
/// in the result stream may include GraphQL errors (such as partially-decoded results), but those
/// errors do not represent the end of the subscription stream. The publisher will emit a `completion`
/// when the subscription is terminated and no longer receiving updates.
public typealias GraphQLSubscriptionPublisher<R: Decodable> = AnyPublisher<
    SubscriptionEvent<GraphQLResponse<R>>,
    APIError
>
```

### `query`

```swift
func query<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLPublisher<R>
```

### `mutate`

```swift
func mutate<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLPublisher<R>
```

### `subscribe`

```swift
func subscribe<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLSubscriptionPublisher<R>
```

**REST APIs**

### New Typealias

```swift
public typealias APIRESTPublisher = AnyPublisher<Data, APIError>
```

### `delete`

```swift
func delete(request: RESTRequest) -> APIRESTPublisher
```

### `get`

```swift
func get(request: RESTRequest) -> APIRESTPublisher
```

### `head`

```swift
func head(request: RESTRequest) -> APIRESTPublisher
```

### `patch`

```swift
func patch(request: RESTRequest) -> APIRESTPublisher
```

### `post`

```swift
func post(request: RESTRequest) -> APIRESTPublisher
```

### `put`

```swift
func put(request: RESTRequest) -> APIRESTPublisher
```

---
Analytics
---

The Analytics category does not offer any CombineSupport APIs.

---
Auth
---

TBD

---
DataStore
---

### New Typealiases

```swift
public typealias DataStorePublisher<Output> = AnyPublisher<Output, DataStoreError>
```

### `save`

```swift
func save<M: Model>(_ model: M,
                    where condition: QueryPredicate? = nil) -> DataStorePublisher<M>
```

### `query` by id

```swift
func query<M: Model>(_ modelType: M.Type,
                     byId id: String) -> DataStorePublisher<M?>
```

### `query` by predicate

```swift
func query<M: Model>(_ modelType: M.Type,
                     where predicate: QueryPredicate? = nil,
                     paginate paginationInput: QueryPaginationInput? = nil) -> DataStorePublisher<[M]>
```

### `delete` by id

```swift
func delete<M: Model>(_ modelType: M.Type,
                      withId id: String) -> DataStorePublisher<Void>
```

### `delete` by predicate

```swift
func delete<M: Model>(_ model: M,
                      where predicate: QueryPredicate? = nil) -> DataStorePublisher<Void>
```

### `clear`

```swift
func clear() -> DataStorePublisher<Void>
```

---
Hub
---

TBD, but potentially:

```swift
typealias HubPublisher<Output> = AnyPublisher<Output, Never>

func publisher(for channel: HubChannel) -> HubPublisher
```

---
Logging
---

The Logging category does not offer any CombineSupport APIs.

---
Predictions
---

### New Typealiases

```swift
public typealias PredictionsPublisher<Output> = AnyPublisher<Output, PredictionsError>
```

### `convert` speech to text

```swift
func convert(speechToText: URL,
             options: PredictionsSpeechToTextRequest.Options? = nil) -> PredictionsPublisher<SpeechToTextResult>
```

### `convert` text to speech

```swift
    func convert(textToSpeech: String,
                 options: PredictionsTextToSpeechRequest.Options? = nil) -> PredictionsPublisher<TextToSpeechResult>
```

### `convert` text to translate

```swift
func convert(textToTranslate: String,
             language: LanguageType?,
             targetLanguage: LanguageType?,
             options: PredictionsTranslateTextRequest.Options? = nil) -> PredictionsPublisher<TranslateTextResult>
```

### `identify`

```swift
func identify(type: IdentifyAction,
              image: URL,
              options: PredictionsIdentifyRequest.Options? = nil) -> PredictionsPublisher<IdentifyResult>
```

### `interpret`

```swift
func interpret(text: String,
               options: PredictionsInterpretRequest.Options? = nil) -> PredictionsPublisher<InterpretResult>
```

---
Storage
---

### New types

```swift
/// Convenience typealias defining a result publisher for Storage operations
public typealias StoragePublisher<Output> = AnyPublisher<Output, StorageError>

/// Encapsulates a result publisher and a progress publisher for operations that publish in-process updates, such as
/// uploads and downloads.
public struct StorageInProcessPublisher<Output> {
    /// Publishes progress updates for the associated operation. Completes when the `resultPublisher` receives a
    /// completion.
    public let progressPublisher: AnyPublisher<Progress, Never>
    
    /// Publishes an update with the result of an operation
    public let resultPublisher: StoragePublisher<Output>
}
```

### `downloadData`

```swift
func downloadData(key: String,
                  options: StorageDownloadDataOperation.Request.Options? = nil) -> StorageInProcessPublisher<Data>
```

### `downloadFile`

```swift
func downloadFile(key: String,
                  local: URL,
                  options: StorageDownloadFileOperation.Request.Options? = nil) -> StorageInProcessPublisher<Void>
```

### `getURL`

```swift
func getURL(key: String,
            options: StorageGetURLOperation.Request.Options? = nil) -> StoragePublisher<URL>
```

### `list`

```swift
func list(options: StorageListOperation.Request.Options? = nil) -> StoragePublisher<StorageListResult>
```

### `remove`

```swift
func remove(key: String,
            options: StorageRemoveOperation.Request.Options? = nil) -> StoragePublisher<String>
```

### `uploadData`

```swift
func uploadData(key: String,
                data: Data,
                options: StorageUploadDataOperation.Request.Options? = nil) -> StorageInProcessPublisher<String>
```

### `uploadFile`

```swift
    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileOperation.Request.Options? = nil) -> StorageInProcessPublisher<String>
```
