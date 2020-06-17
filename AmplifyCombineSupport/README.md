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

## API Mapping

AmplifyCombineSupport strives to provide the same API signature and call patterns as vanilla Amplify, minus the result callbacks. Thus, `Amplify.DataStore.save(_:where:completion:)` has a CombineSupport equivalent of `Amplify.DataStore.save(_:where:)`. Similarly, the types used in result callbacks in vanilla Amplify APIs translate logically to the Output and Error types of `AnyPublisher`s returned from AmplifyCombineSupport APIs. Where method signatures conflict because of ambiguous type requirements, AmplifyCombineSupport will provide a method flavor appended with `...WithPublisher`, as in a hypothetical `DataStore.saveWithPublisher(...) -> AnyPublisher<...>`.

### APIs with in-process listeners
APIs that accept both an "in process" and "result" listener have a CombineSupport flavor that returns a struct containing both a `result` and `inProcess` publisher.

### APIs that return operations

## API reference by category

### API

TBD

### Analytics

The Analytics category does not offer any CombineSupport APIs.

### Auth

TBD

### DataStore

**New Typealiases**

```swift
public typealias DataStorePublisher<Output> = AnyPublisher<Output, DataStoreError>
```

#### `save`

**Standard Amplify**

```swift
func save<M: Model>(_ model: M,
                    where condition: QueryPredicate?,
                    completion: @escaping DataStoreCallback<M>)
```

**AmplifyCombineSupport**
```swift
func save<M: Model>(_ model: M,
                    where condition: QueryPredicate? = nil) -> DataStorePublisher<M>
```

#### `query` by id

**Standard Amplify**

```swift
func query<M: Model>(_ modelType: M.Type,
                     byId id: String,
                     completion: DataStoreCallback<M?>)
```

**AmplifyCombineSupport**

```swift
func query<M: Model>(_ modelType: M.Type,
                     byId id: String) -> DataStorePublisher<M?>
```

#### `query` by predicate

**Standard Amplify**

```swift
func query<M: Model>(_ modelType: M.Type,
                     where predicate: QueryPredicate?,
                     paginate paginationInput: QueryPaginationInput?,
                     completion: DataStoreCallback<[M]>)
```

**AmplifyCombineSupport**

```swift
func query<M: Model>(_ modelType: M.Type,
                     where predicate: QueryPredicate? = nil,
                     paginate paginationInput: QueryPaginationInput? = nil) -> DataStorePublisher<[M]>
```

#### `delete` by id

**Standard Amplify**

```swift
func delete<M: Model>(_ modelType: M.Type,
                      withId id: String,
                      completion: @escaping DataStoreCallback<Void>)

```

**AmplifyCombineSupport**

```swift
func delete<M: Model>(_ modelType: M.Type,
                      withId id: String) -> DataStorePublisher<Void>
```

#### `delete` by predicate

**Standard Amplify**

```swift
func delete<M: Model>(_ model: M,
                      where predicate: QueryPredicate?,
                      completion: @escaping DataStoreCallback<Void>)
```

**AmplifyCombineSupport**

```swift
func delete<M: Model>(_ model: M,
                      where predicate: QueryPredicate? = nil) -> DataStorePublisher<Void>
```

#### `clear`

**Standard Amplify**

```swift
func clear(completion: @escaping DataStoreCallback<Void>)
```

**AmplifyCombineSupport**

```swift
func clear() -> DataStorePublisher<Void>
```

### Hub

TBD, but potentially:

```swift
typealias HubPublisher<Output> = AnyPublisher<Output, Never>

func publisher(for channel: HubChannel) -> HubPublisher
```

### Logging

The Logging category does not offer any CombineSupport APIs.

### Predictions

**New Typealiases**

```swift
public typealias PredictionsPublisher<Output> = AnyPublisher<Output, PredictionsError>
```

#### `convert` speech to text

**Standard Amplify**

```swift
func convert(speechToText: URL,
             options: PredictionsSpeechToTextRequest.Options?,
             listener: PredictionsSpeechToTextOperation.ResultListener?) -> PredictionsSpeechToTextOperation
```

**AmplifyCombineSupport**

```swift
func convert(speechToText: URL,
             options: PredictionsSpeechToTextRequest.Options? = nil) -> PredictionsPublisher<SpeechToTextResult>
```

#### `convert` text to speech

**Standard Amplify**

```swift
func convert(textToSpeech: String,
             options: PredictionsTextToSpeechRequest.Options?,
             listener: PredictionsTextToSpeechOperation.ResultListener?) -> PredictionsTextToSpeechOperation
```

**AmplifyCombineSupport**

```swift
    func convert(textToSpeech: String,
                 options: PredictionsTextToSpeechRequest.Options? = nil) -> PredictionsPublisher<TextToSpeechResult>
```

#### `convert` text to translate

**Standard Amplify**

```swift
func convert(textToTranslate: String,
             language: LanguageType?,
             targetLanguage: LanguageType?,
             options: PredictionsTranslateTextRequest.Options?,
             listener: PredictionsTranslateTextOperation.ResultListener?) -> PredictionsTranslateTextOperation
```

**AmplifyCombineSupport**

```swift
func convert(textToTranslate: String,
             language: LanguageType?,
             targetLanguage: LanguageType?,
             options: PredictionsTranslateTextRequest.Options? = nil) -> PredictionsPublisher<TranslateTextResult>
```

#### `identify`

**Standard Amplify**

```swift
func identify(type: IdentifyAction,
              image: URL,
              options: PredictionsIdentifyRequest.Options?,
              listener: PredictionsIdentifyOperation.ResultListener?) -> PredictionsIdentifyOperation
```

**AmplifyCombineSupport**

```swift
func identify(type: IdentifyAction,
              image: URL,
              options: PredictionsIdentifyRequest.Options? = nil) -> PredictionsPublisher<IdentifyResult>
```

#### `interpret`

**Standard Amplify**

```swift
func interpret(text: String,
               options: PredictionsInterpretRequest.Options?,
               listener: PredictionsInterpretOperation.ResultListener?) -> PredictionsInterpretOperation
```

**AmplifyCombineSupport**

```swift
func interpret(text: String,
               options: PredictionsInterpretRequest.Options? = nil) -> PredictionsPublisher<InterpretResult>
```

### Storage

**New types**

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

#### `downloadData`

**Standard Amplify**

```swift
func downloadData(key: String,
                  options: StorageDownloadDataOperation.Request.Options?,
                  progressListener: ProgressListener?,
                  resultListener: StorageDownloadDataOperation.ResultListener?) -> StorageDownloadDataOperation
```

**AmplifyCombineSupport**

```swift
func downloadData(key: String,
                  options: StorageDownloadDataOperation.Request.Options? = nil) -> StorageInProcessPublisher<Data>
```

#### `downloadFile`

**Standard Amplify**

```swift
func downloadFile(key: String,
                  local: URL,
                  options: StorageDownloadFileOperation.Request.Options?,
                  progressListener: ProgressListener?,
                  resultListener: StorageDownloadFileOperation.ResultListener?) -> StorageDownloadFileOperation
```

**AmplifyCombineSupport**

```swift
func downloadFile(key: String,
                  local: URL,
                  options: StorageDownloadFileOperation.Request.Options? = nil) -> StorageInProcessPublisher<Void>
```

#### `getURL`

**Standard Amplify**

```swift
func getURL(key: String,
            options: StorageGetURLOperation.Request.Options?,
            resultListener: StorageGetURLOperation.ResultListener?) -> StorageGetURLOperation
```

**AmplifyCombineSupport**

```swift
func getURL(key: String,
            options: StorageGetURLOperation.Request.Options? = nil) -> StoragePublisher<URL>
```

#### `list`

**Standard Amplify**

```swift
func list(options: StorageListOperation.Request.Options?,
          resultListener: StorageListOperation.ResultListener?) -> StorageListOperation
```

**AmplifyCombineSupport**

```swift
func list(options: StorageListOperation.Request.Options? = nil) -> StoragePublisher<StorageListResult>
```

#### `remove`

**Standard Amplify**

```swift
func remove(key: String,
            options: StorageRemoveOperation.Request.Options?,
            resultListener: StorageRemoveOperation.ResultListener?) -> StorageRemoveOperation
```

**AmplifyCombineSupport**

```swift
func remove(key: String,
            options: StorageRemoveOperation.Request.Options? = nil) -> StoragePublisher<String>
```

#### `uploadData`

**Standard Amplify**

```swift
func uploadData(key: String,
                data: Data,
                options: StorageUploadDataOperation.Request.Options?,
                progressListener: ProgressListener?,
                resultListener: StorageUploadDataOperation.ResultListener?) -> StorageUploadDataOperation
```
**AmplifyCombineSupport**

```swift
func uploadData(key: String,
                data: Data,
                options: StorageUploadDataOperation.Request.Options? = nil) -> StorageInProcessPublisher<String>
```

#### `uploadFile`

**Standard Amplify**

```swift
func uploadFile(key: String,
                local: URL,
                options: StorageUploadFileOperation.Request.Options?,
                progressListener: ProgressListener?,
                resultListener: StorageUploadFileOperation.ResultListener?) -> StorageUploadFileOperation
```
**AmplifyCombineSupport**

```swift
    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileOperation.Request.Options? = nil) -> StorageInProcessPublisher<String>
```

