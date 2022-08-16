//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Combine

public struct AsyncPassthroughSubject<Success> {
    let task: Task<Success, Error>

    public init(operation: @escaping @Sendable () async throws -> Success) {
        task = Task(operation: operation)
    }

    public func eraseToAnyPublisher() -> AnyPublisher<Success, Error> {
        let subject = PassthroughSubject<Success, Error>()

        Task {
            do {
                let value = try await task.value
                subject.send(value)
                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
            }
        }

        return subject.eraseToAnyPublisher()
    }
}
#endif
