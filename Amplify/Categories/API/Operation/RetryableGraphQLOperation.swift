//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation


// MARK: - RetryableGraphQLOperation
public final class RetryableGraphQLOperation<Payload: Decodable & Sendable> {
    public typealias Payload = Payload

    private let nondeterminsticOperation: NondeterminsticOperation<GraphQLTask<Payload>.Success>

    public init(
        requestStream: AsyncStream<@Sendable () async throws -> GraphQLTask<Payload>.Success>
    ) {
        self.nondeterminsticOperation = NondeterminsticOperation(
            operations: requestStream,
            shouldTryNextOnError: Self.onError(_:)
        )
    }

    deinit {
        cancel()
    }

    static func onError(_ error: Error) -> Bool {
        guard let error = error as? APIError,
              let authError = error.underlyingError as? AuthError
        else {
            return false
        }

        switch authError {
        case .notAuthorized: return true
        default: return false
        }
    }

    public func execute(
        _ operationType: GraphQLOperationType
    ) -> AnyPublisher<GraphQLTask<Payload>.Success, APIError> {
        nondeterminsticOperation.execute().mapError {
            if let apiError = $0 as? APIError {
                return apiError
            } else {
                return APIError.operationError("Failed to execute GraphQL operation", "", $0)
            }
        }.eraseToAnyPublisher()
    }

    public func run() async -> Result<GraphQLTask<Payload>.Success, APIError> {
        do {
            let result = try await nondeterminsticOperation.run()
            return .success(result)
        } catch {
            if let apiError = error as? APIError {
                return .failure(apiError)
            } else {
                return .failure(.operationError("Failed to execute GraphQL operation", "", error))
            }
        }
    }

    public func cancel() {
        nondeterminsticOperation.cancel()
    }

}

/// - Note: `@unchecked Sendable` because `_task` is mutable but every access is serialized by
///   `lock`.
public final class RetryableGraphQLSubscriptionOperation<Payload>: @unchecked Sendable
    where Payload: Decodable, Payload: Sendable {

    public typealias Payload = Payload
    public typealias SubscriptionEvents = GraphQLSubscriptionEvent<Payload>

    /// Guards `_task`.
    private let lock = NSLock()
    private var _task: Task<Void, Never>?

    private var task: Task<Void, Never>? {
        get { lock.withLock { _task } }
        set { lock.withLock { _task = newValue } }
    }

    private let nondeterminsticOperation: NondeterminsticOperation<AmplifyAsyncThrowingSequence<SubscriptionEvents>>

    public init(
        requestStream: AsyncStream<@Sendable () async throws -> AmplifyAsyncThrowingSequence<SubscriptionEvents>>
    ) {
        self.nondeterminsticOperation = NondeterminsticOperation(operations: requestStream)
    }

    deinit {
        cancel()
    }

    public func subscribe() -> AnyPublisher<SubscriptionEvents, APIError> {
        let subject = PassthroughSubject<SubscriptionEvents, APIError>()
        // `PassthroughSubject` is not `Sendable`, but `send` is safe to call from any thread.
        let boxedSubject = UncheckedSendable(subject)
        task = Task { await self.trySubscribe(boxedSubject.value) }
        return subject.eraseToAnyPublisher()
    }

    private func trySubscribe(_ subject: PassthroughSubject<SubscriptionEvents, APIError>) async {
        var apiError: APIError?
        do {
            try Task.checkCancellation()
            let sequence = try await nondeterminsticOperation.run()
            defer { sequence.cancel() }
            for try await event in sequence {
                try Task.checkCancellation()
                subject.send(event)
            }
        } catch is CancellationError {
            subject.send(completion: .finished)
        } catch {
            if let error = error as? APIError {
                apiError = error
            }
            Self.log.debug("Failed with subscription request: \(error)")
        }

        if apiError != nil {
            subject.send(completion: .failure(apiError!))
        } else {
            subject.send(completion: .finished)
        }
    }

    public func cancel() {
        task?.cancel()
        nondeterminsticOperation.cancel()
    }
}

// The sequence is captured by a `Task` and its elements are yielded to a continuation, so
// both must be `Sendable` in the Swift 6 language mode.
private extension AsyncSequence where Self: Sendable, Element: Sendable {
    var asyncStream: AsyncStream<Self.Element> {
        AsyncStream { continuation in
            Task {
                var it = self.makeAsyncIterator()
                do {
                    while let ele = try await it.next() {
                        continuation.yield(ele)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}

public extension RetryableGraphQLSubscriptionOperation {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }
    var log: Logger {
        Self.log
    }
}
