//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Combine

extension Amplify {
    enum Publisher {
        static func create<Success>(
            operation: @escaping @Sendable () async throws -> Success
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
        
        static func create<Sequence: AsyncSequence>(
            sequence: Sequence
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
