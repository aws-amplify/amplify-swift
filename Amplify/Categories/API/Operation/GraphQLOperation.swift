//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

open class GraphQLOperation<R: Decodable>: AmplifyOperation<
    GraphQLOperationRequest<R>,
    GraphQLResponse<R>,
    APIError
> { }


/// GraphQL Subscription Operation
open class GraphQLSubscriptionOperation<R: Decodable>: AmplifyInProcessReportingOperation<
    GraphQLOperationRequest<R>,
    SubscriptionEvent<GraphQLResponse<R>>,
    Void,
    APIError
> { }

public extension HubPayload.EventName.API {
    /// eventName for HubPayloads emitted by this operation
    static let mutate = "API.mutate"

    /// eventName for HubPayloads emitted by this operation
    static let query = "API.query"

    /// eventName for HubPayloads emitted by this operation
    static let subscribe = "API.subscribe"
}


/// Retryable GraphQL operation
public final class RetryableGraphQLOperation<Payload: Decodable>: Operation {
    public enum RetryableGraphQLOperationType<P: Decodable> {
        case subscription(inProcess: GraphQLSubscriptionOperation<Payload>.InProcessListener,
                          completion: GraphQLSubscriptionOperation<Payload>.ResultListener)
        case mutation(completion: GraphQLOperation<Payload>.ResultListener)
        case query(completion: GraphQLOperation<Payload>.ResultListener)
    }

    public typealias RequestFactory = () -> GraphQLRequest<Payload>
    
    let api: APICategoryGraphQLBehavior
    let requestFactory: RequestFactory
    var underlyingOperation: AsynchronousOperation?
    var operationType: RetryableGraphQLOperationType<Payload>
    var attempts = 0
    let maxRetries: Int
    let id = UUID()


    /// Initialize a new retryable operation
    /// - Parameters:
    ///   - requestFactory: `GraphQLRequest<Payload>` factory, called at every new attempt
    ///   - api: `APICategoryGraphQLBehavior`
    ///   - operationType: type of GraphQL operation
    ///   - maxRetries: maximum number of retries (default 1)
    public init(requestFactory: @escaping RequestFactory,
                api: APICategoryGraphQLBehavior,
                operationType: RetryableGraphQLOperationType<Payload>,
                maxRetries: Int = 1) {
        self.requestFactory = requestFactory
        self.api = api
        self.operationType = operationType
        self.maxRetries = max(1, maxRetries)
    }

    public override func main() {
        start(request: requestFactory())
    }
    
    private func start(request: GraphQLRequest<Payload>) {
        attempts += 1
        var operation: AsynchronousOperation?
        switch operationType {
        case .subscription(inProcess: let inProcess, completion: let completion):
            let wrappedCompletionListener: GraphQLSubscriptionOperation<Payload>.ResultListener = {
                if case let .failure(error) = $0, self.attempts < self.maxRetries {
                    self.start(request: self.requestFactory())
                    return
                }
                completion($0)
            }
            operation = api.subscribe(request: request,
                                          valueListener: inProcess,
                                          completionListener: wrappedCompletionListener)
        case .mutation(completion: let completion):
            let wrappedCompletionListener: GraphQLOperation<Payload>.ResultListener = {
                if case let .failure(error) = $0, self.attempts < self.maxRetries {
                    self.start(request: self.requestFactory())
                    return
                }
                completion($0)
            }
            operation = api.mutate(request: request,
                                   listener: wrappedCompletionListener)
        case .query(completion: let completion):
            let wrappedCompletionListener: GraphQLOperation<Payload>.ResultListener = {
                if case let .failure(error) = $0, self.attempts < self.maxRetries {
                    self.start(request: self.requestFactory())
                    return
                }
                completion($0)
            }
            operation = api.query(request: request,
                                  listener: wrappedCompletionListener)
        }
        inFlightOperation(operation: operation)
    }

    public override func cancel() {
        underlyingOperation?.cancel()
    }

    private func inFlightOperation(operation: AsynchronousOperation?) {
        underlyingOperation = operation
    }
}

extension RetryableGraphQLOperation: DefaultLogger {}
