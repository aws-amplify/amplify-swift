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
    }
}
#endif
