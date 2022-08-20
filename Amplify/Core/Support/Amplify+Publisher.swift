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
        /// - Parameter operation: The Task for which to create the Publisher.
        /// - Returns: The Publisher for the given Task.
        public static func create<Success>(
            _ operation: @escaping @Sendable () async throws -> Success
        ) -> AnyPublisher<Success, Error> {
            let task = Task(operation: operation)
            return Future() { promise in
                Task {
                    do {
                        let value = try await task.value
                        promise(.success(value))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
            .handleEvents(receiveCancel: { task.cancel() } )
            .eraseToAnyPublisher()
        }
        
        /// Create a Combine Publisher for a given AsyncSequence.
        /// - Parameter sequence: The AsyncSequence for which to create the Publisher.
        /// - Returns: The Publisher for the given AsyncSequence.
        public static func create<Sequence: AsyncSequence>(
            _ sequence: Sequence
        ) -> AnyPublisher<Sequence.Element, Error> {
            let subject = PassthroughSubject<Sequence.Element, Error>()
            let task = Task {
                do {
                    for try await value in sequence {
                        // If the Task is cancelled and the AsyncSequence is Cancellable, as
                        // is the case with AmplifyAsyncSequence, cancel the AsyncSequence.
                        if Task.isCancelled {
                            if let cancellable = sequence as? Cancellable {
                                cancellable.cancel()
                            }
                            // This will end the loop and send a CancellationError to the publisher
                            throw CancellationError()
                        }
                        subject.send(value)
                    }
                    subject.send(completion: .finished)
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
