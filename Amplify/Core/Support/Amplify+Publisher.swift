//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Combine

public extension Amplify {

    /// Get Combine Publishers for Amplify APIs.
    ///
    /// Provides static methods to create Combine Publishers from Tasks and
    /// AsyncSequences.
    ///
    /// These can be used to get Combine Publishers for any Amplify API.
    enum Publisher {
        /// Create a Combine Publisher for a given Task.
        ///
        /// Example Usage
        /// ```
        /// let sink = Amplify.Publisher.create {
        ///     try await Amplify.Geo.search(for "coffee")
        /// }
        ///     .sink { completion in
        ///         // handle completion
        ///     } receiveValue: { value in
        ///         // handle value
        ///     }
        /// ```
        ///
        /// - Parameter operation: The Task for which to create the Publisher.
        /// - Returns: The Publisher for the given Task.
        public static func create<Success: Sendable>(
            _ operation: @escaping @Sendable () async throws -> Success
        ) -> AnyPublisher<Success, Error> {
            let task = Task(operation: operation)
            return Future { promise in
                // `Future.Promise` is not `Sendable`, but Combine guarantees it is called
                // at most once, so moving it into the task is safe.
                let promise = UncheckedSendable(promise)
                Task {
                    do {
                        let value = try await task.value
                        promise.value(.success(value))
                    } catch {
                        promise.value(.failure(error))
                    }
                }
            }
            .handleEvents(receiveCancel: { task.cancel() })
            .eraseToAnyPublisher()
        }

        /// Create a Combine Publisher for a given non-throwing Task.
        ///
        /// Example Usage
        /// ```
        /// let sink = Amplify.Publisher.create {
        ///     try await Amplify.Auth.signOut()
        /// }
        ///     .sink(receiveValue: { value in
        ///         // handle value
        ///     })
        /// ```
        ///
        /// - Parameter operation: The Task for which to create the Publisher.
        /// - Returns: The Publisher for the given Task.
        public static func create<Success: Sendable>(
            _ operation: @escaping @Sendable () async -> Success
        ) -> AnyPublisher<Success, Never> {
            let task = Task(operation: operation)
            return Future { promise in
                // See the throwing overload above: `Future.Promise` is not `Sendable` but
                // is called at most once.
                let promise = UncheckedSendable(promise)
                Task {
                    let value = await task.value
                    promise.value(.success(value))
                }
            }
            .handleEvents(receiveCancel: { task.cancel() })
            .eraseToAnyPublisher()
        }

        /// Create a Combine Publisher for a given AsyncSequence.
        ///
        /// Example Usage
        /// ```
        /// let subscription = Amplify.API.subscribe(
        ///     request: .subscription(of: Todo.self, type: .onCreate)
        /// )
        ///
        /// let sink = Amplify.Publisher.create(subscription)
        ///     .sink { completion in
        ///         // handle completion
        ///     } receiveValue: { value in
        ///         // handle value
        ///     }
        /// ```
        ///
        /// - Parameter sequence: The AsyncSequence for which to create the Publisher.
        /// - Returns: The Publisher for the given AsyncSequence.
        // `Sequence` is captured by the `onCancel` closure and its elements are sent
        // through a Combine subject from inside a `Task`, so both the sequence and its
        // element type must be `Sendable` in the Swift 6 language mode.
        public static func create<Sequence: AsyncSequence & Sendable>(
            _ sequence: Sequence
        ) -> AnyPublisher<Sequence.Element, Error> where Sequence.Element: Sendable {
            let subject = PassthroughSubject<Sequence.Element, Error>()
            // `PassthroughSubject` is not `Sendable`, but `send` is documented as safe to
            // call from any thread, so it can be driven from the task below.
            let boxedSubject = UncheckedSendable(subject)
            let task = Task {
                let subject = boxedSubject.value
                do {
                    // If the Task is cancelled, this will allow the onCancel closure to be called immediately.
                    // This is necessary to prevent continuing to wait until another value is received from
                    // the sequence before cancelling in the case of a slow Iterator.
                    try await withTaskCancellationHandler {
                        for try await value in sequence {
                            // If the Task is cancelled, this will end the loop and send a CancellationError
                            // via the publisher.
                            // This is necessary to prevent the sequence from continuing to send values for a time
                            // after cancellation in the case of a fast Iterator.
                            try Task.checkCancellation()
                            subject.send(value)
                        }
                        subject.send(completion: .finished)
                    } onCancel: {
                        // If the Task is cancelled and the AsyncSequence is Cancellable, as
                        // is the case with AmplifyAsyncSequence, cancel the AsyncSequence.
                        if let cancellable = sequence as? Cancellable {
                            cancellable.cancel()
                        }
                    }
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
            return subject
                .handleEvents(receiveCancel: { task.cancel() })
                .eraseToAnyPublisher()
        }
    }
}
#endif
