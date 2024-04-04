//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine


// MARK: - RetryableGraphQLOperation
public final class RetryableGraphQLOperation<Payload: Decodable> {
    public typealias Payload = Payload

    public let requestFactory: AsyncStream<() -> GraphQLRequest<Payload>>
    public weak var api: APICategoryGraphQLBehavior?
    private var task: Task<Void, Never>?

    public init<T: AsyncSequence>(
        requestFactory: T,
        api: APICategoryGraphQLBehavior
    ) where T.Element == () -> GraphQLRequest<Payload> {
        self.requestFactory = requestFactory.asyncStream
        self.api = api
    }

    deinit {
        cancel()
    }

    public func execute(
        _ operationType: GraphQLOperationType
    ) -> Future<GraphQLTask<Payload>.Success, APIError> {
        Future() { promise in
            self.task = Task { promise(await self.run(operationType)) }
        }
    }

    public func run(_ operationType: GraphQLOperationType) async -> Result<GraphQLTask<Payload>.Success, APIError> {
        for await request in requestFactory {
            do {
                try Task.checkCancellation()
                switch (self.api, operationType) {
                case (.some(let api), .query):
                    return .success(try await api.query(request: request()))
                case (.some(let api), .mutation):
                    return .success(try await api.mutate(request: request()))
                default:
                    return .failure(.operationError("Unable to run GraphQL operation with type \(operationType)", ""))
                }

            } catch is CancellationError {
                return .failure(.operationError("GraphQL operation cancelled", ""))
            } catch {
                guard let error = error as? APIError,
                      let authError = error.underlyingError as? AuthError
                else {
                    return .failure(.operationError("Failed to send \(operationType) GraphQL request", "", error))
                }

                switch authError {
                case .signedOut, .notAuthorized: break;
                default: return .failure(error)
                }
            }
        }
        return .failure(APIError.operationError("Failed to execute GraphQL operation \(operationType)", "", nil))
    }

    public func cancel() {
        task?.cancel()
    }

}

public final class RetryableGraphQLSubscriptionOperation<Payload: Decodable> {

    public typealias Payload = Payload

    public let requestFactory: AsyncStream<() async -> GraphQLRequest<Payload>>
    public weak var api: APICategoryGraphQLBehavior?
    private var task: Task<Void, Error>?

    public init<T: AsyncSequence>(
        requestFactory: T,
        api: APICategoryGraphQLBehavior
    ) where T.Element == () async -> GraphQLRequest<Payload> {
        self.requestFactory = requestFactory.asyncStream
        self.api = api
    }

    deinit {
        cancel()
    }

    public func subscribe() -> AnyPublisher<GraphQLSubscriptionEvent<Payload>, APIError> {
        let subject = PassthroughSubject<GraphQLSubscriptionEvent<Payload>, APIError>()
        self.task = Task { await self.trySubscribe(subject) }
        return subject.eraseToAnyPublisher()
    }

    private func trySubscribe(_ subject: PassthroughSubject<GraphQLSubscriptionEvent<Payload>, APIError>) async {
        var apiError: APIError?
        for await request in requestFactory {
            guard let sequence = self.api?.subscribe(request: await request()) else {
                continue
            }
            do {
                try Task.checkCancellation()

                for try await event in sequence {
                    try Task.checkCancellation()
                    Self.log.debug("Subscribe event \(event)")
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
            sequence.cancel()
        }
        if apiError != nil {
            subject.send(completion: .failure(apiError!))
        } else {
            subject.send(completion: .finished)
        }
    }

    public func cancel() {
        self.task?.cancel()
    }
}

extension AsyncSequence {
    fileprivate var asyncStream: AsyncStream<Self.Element> {
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

extension RetryableGraphQLSubscriptionOperation {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
