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
public final class RetryableGraphQLOperation<Payload: Decodable>: AmplifyCancellable {
    public enum RetryableGraphQLOperationType<P: Decodable> {
        case subscription(inProcess: GraphQLSubscriptionOperation<Payload>.InProcessListener,
                          completion: GraphQLSubscriptionOperation<Payload>.ResultListener)
        case mutation(completion: GraphQLOperation<Payload>.ResultListener)
        case query(completion: GraphQLOperation<Payload>.ResultListener)
    }

    public typealias RequestFactory = () -> GraphQLRequest<Payload>?
    let api: APICategoryGraphQLBehavior
    let requestFactory: RequestFactory
    var underlyingOperation: AsynchronousOperation?
    var operationType: RetryableGraphQLOperationType<Payload>
    var attempts = 0
    let id = UUID()

    
    /// Initialize a new retryable operation
    /// - Parameters:
    ///   - requestFactory: `GraphQLRequest<Payload>` factory, called at every new attempt
    ///   - api: `APICategoryGraphQLBehavior`
    ///   - operationType: type of GraphQL operation
    public init(requestFactory: @escaping RequestFactory,
                api: APICategoryGraphQLBehavior,
                operationType: RetryableGraphQLOperationType<Payload>) {
        self.requestFactory = requestFactory
        self.api = api
        self.operationType = operationType
    }

    public func start() {
        guard let request = requestFactory() else {
            // TODO: log error
            return
        }
        start(request: request)
    }

    private func start(request: GraphQLRequest<Payload>) {
        attempts += 1
        var operation: AsynchronousOperation?
        switch operationType {
        case .subscription(inProcess: let inProcess, completion: let completion):
            let wrappedCompletionListener: GraphQLSubscriptionOperation<Payload>.ResultListener = {
                if case let .failure(error) = $0, let nextRequest = self.requestFactory() {
                    print("error \(error)")
                    self.start(request: nextRequest)
                    return
                }
                completion($0)
            }
            operation = api.subscribe(request: request,
                                          valueListener: inProcess,
                                          completionListener: wrappedCompletionListener)
        case .mutation(completion: let completion):
            let wrappedCompletionListener: GraphQLOperation<Payload>.ResultListener = {
                if case let .failure(error) = $0, let nextRequest = self.requestFactory() {
                    self.start(request: nextRequest)
                    return
                }
                completion($0)
            }
            operation = api.mutate(request: request,
                                       listener: wrappedCompletionListener)
        case .query(completion: let completion):
            let wrappedCompletionListener: GraphQLOperation<Payload>.ResultListener = {
                if case .failure = $0, let nextRequest = self.requestFactory() {
                    self.start(request: nextRequest)
                    return
                }
                completion($0)
            }
            operation = api.query(request: request,
                                       listener: wrappedCompletionListener)
        }
        inFlightOperation(operation: operation)
    }

    public func cancel() {
        underlyingOperation?.cancel()
    }

    private func inFlightOperation(operation: AsynchronousOperation?) {
        // cancel()
        underlyingOperation = operation
    }
}
