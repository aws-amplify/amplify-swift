//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public protocol AnyGraphQLOperation {
    associatedtype Success
    associatedtype Failure: Error
    typealias ResultListener = (Result<Success, Failure>) -> Void
}

public protocol RetryableGraphQLOperationBehavior: Operation {
    associatedtype Payload: Decodable
    associatedtype OperationType: AnyGraphQLOperation

    typealias RequestFactory = () -> GraphQLRequest<Payload>
    typealias OperationFactory = (GraphQLRequest<Payload>, @escaping OperationResultListener) -> OperationType
    typealias OperationResultListener = OperationType.ResultListener

    var id: UUID { get }
    var attempts: Int { get set }
    var underlyingOperation: OperationType? { get set }

    var maxRetries: Int { get }
    var requestFactory: RequestFactory { get }
    var resultListener: OperationResultListener { get }
    var operationFactory: OperationFactory { get }

    init(requestFactory: @escaping RequestFactory,
         maxRetries: Int,
         resultListener: @escaping OperationResultListener,
         _ operationFactory: @escaping OperationFactory)

    func start(request: GraphQLRequest<Payload>)
}

// MARK: RetryableGraphQLOperation + default implementation
extension RetryableGraphQLOperationBehavior {
    public func start(request: GraphQLRequest<Payload>) {
        self.attempts += 1
        print("[Operation \(self.id)] - Try [\(self.attempts)/\(self.maxRetries)]")
        let wrappedResultListener: OperationResultListener = { result in
            if case let .failure(error) = result, self.attempts < self.maxRetries {
                self.start(request: self.requestFactory())
                return
            }
            
            if case let .failure(error) = result {
                print("[Operation \(self.id)] - Failed")
            }
            
            if case .success = result {
                print("[Operation \(self.id)] - Success")
            }
            // print("[Operation \(self.id)] Succeeded [\(self.attempts)/\(self.maxRetries)]")
            self.resultListener(result)
        }
        underlyingOperation = operationFactory(request, wrappedResultListener)
    }
}

// MARK: RetryableGraphQLOperation + DefaultLogger
extension RetryableGraphQLOperation: DefaultLogger {}

public final class RetryableGraphQLOperation<Payload: Decodable>: Operation, RetryableGraphQLOperationBehavior {
    public typealias Payload = Payload
    public typealias OperationType = GraphQLOperation<Payload>

    public var id: UUID
    public var maxRetries: Int
    public var attempts: Int = 0
    public var requestFactory: RequestFactory
    public var underlyingOperation: GraphQLOperation<Payload>?
    public var resultListener: OperationResultListener
    public var operationFactory: OperationFactory

    public init(requestFactory: @escaping () -> GraphQLRequest<Payload>,
                maxRetries: Int,
                resultListener: @escaping OperationResultListener,
                _ operationFactory: @escaping OperationFactory) {
        self.id = UUID()
        self.maxRetries = max(1, maxRetries)
        self.requestFactory = requestFactory
        self.operationFactory = operationFactory
        self.resultListener = resultListener
    }
    public override func main() {
        start(request: requestFactory())
    }
    
    public override func cancel() {
        self.underlyingOperation?.cancel()
    }
}

public final class RetryableGraphQLSubscriptionOperation<Payload: Decodable>: Operation, RetryableGraphQLOperationBehavior {
    public typealias OperationType = GraphQLSubscriptionOperation<Payload>
    
    public typealias Payload = Payload

    public var id: UUID
    public var maxRetries: Int
    public var attempts: Int = 0
    public var underlyingOperation: GraphQLSubscriptionOperation<Payload>?
    public var requestFactory: RequestFactory
    public var resultListener: OperationResultListener
    public var operationFactory: OperationFactory

    public init(requestFactory: @escaping RequestFactory,
                maxRetries: Int,
                resultListener: @escaping OperationResultListener,
                _ operationFactory: @escaping OperationFactory) {
        self.id = UUID()
        self.maxRetries = max(1, maxRetries)
        self.requestFactory = requestFactory
        self.operationFactory = operationFactory
        self.resultListener = resultListener
    }
    public override func main() {
        start(request: requestFactory())
    }
    
    public override func cancel() {
        self.underlyingOperation?.cancel()
    }
    
}


// MARK: GraphQLOperation - GraphQLSubscriptionOperation + AnyGraphQLOperation
extension GraphQLOperation: AnyGraphQLOperation {}
extension GraphQLSubscriptionOperation: AnyGraphQLOperation {}
