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

The AmplifyCombineSupport pod extends the base Amplify categories with APIs that return appropriate Combine publishers, which allow developers to use familiar Combine patterns, as in:

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

### DataStore

**New Typealiases**

```swift
public typealias DataStorePublisher<Output> = AnyPublisher<Output, DataStoreError>
```

#### `Save`

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
                      where predicate: QueryPredicate? = nil) -> DataStorePublisher<Void> {
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
