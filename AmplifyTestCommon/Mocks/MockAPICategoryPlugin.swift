//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

class MockAPICategoryPlugin: MessageReporter,
                             APICategoryPlugin,
                             APICategoryReachabilityBehavior,
                             APICategoryGraphQLBehaviorExtended {

    var authProviderFactory: APIAuthProviderFactory?

    var responders = [ResponderKeys: Any]()

    private var _reachabilityPublisher: Any?

    private var oidcProvider: Any?

    init(reachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>) {
        self._reachabilityPublisher = reachabilityPublisher
        super.init()
    }

    // We're declaring this even though it's not strictly necessary to expose the no-arg initializer
    // to iOS 13+ test contexts.
    override init() {
        super.init()
    }

    // MARK: - Properties

    var key: String {
        return "MockAPICategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify("configure")
    }

    func reset() {
        notify("reset")
        listeners.set([])
    }

    // MARK: - Request-based GraphQL methods

    func mutate<R>(request: GraphQLRequest<R>,
                   listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        // This is a really weighty notification message, but needed for tests to be able to assert that a particular
        // model is being mutated
        notify("mutate(request) document: \(request.document); variables: \(String(describing: request.variables))")

        if let responder = responders[.mutateRequestListener] as? MutateRequestListenerResponder<R> {
            if let operation = responder.callback((request, listener)) {
                return operation
            }
        }
        let requestOptions = GraphQLOperationRequest<R>.Options(pluginOptions: nil)
        let request = GraphQLOperationRequest<R>(apiName: request.apiName,
                                                 operationType: .mutation,
                                                 document: request.document,
                                                 variables: request.variables,
                                                 responseType: request.responseType,
                                                 options: requestOptions)
        let operation = MockGraphQLOperation(request: request, responseType: request.responseType)

        return operation
    }
    
    func mutate<R>(request: GraphQLRequest<R>) async throws -> GraphQLTask<R>.Success {
        // This is a really weighty notification message, but needed for tests to be able to assert that a particular
        // model is being mutated
        notify("mutate(request) document: \(request.document); variables: \(String(describing: request.variables))")

        return .failure(.unknown("", "'", nil))
    }

    func query<R: Decodable>(request: GraphQLRequest<R>,
                             listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        notify("query(request:listener:) request: \(request)")

        if let responder = responders[.queryRequestListener] as? QueryRequestListenerResponder<R> {
            if let operation = responder.callback((request, listener)) {
                return operation
            }
        }

        let requestOptions = GraphQLOperationRequest<R>.Options(pluginOptions: nil)
        let request = GraphQLOperationRequest<R>(apiName: request.apiName,
                                                 operationType: .query,
                                                 document: request.document,
                                                 variables: request.variables,
                                                 responseType: request.responseType,
                                                 options: requestOptions)
        let operation = MockGraphQLOperation(request: request, responseType: request.responseType)

        return operation
    }

    func query<R: Decodable>(request: GraphQLRequest<R>) async throws -> GraphQLTask<R>.Success {
        notify("query(request:) request: \(request)")

        if let responder = responders[.queryRequestResponse] as? QueryRequestResponder<R> {
            
            let result = responder.callback(request)
            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw error
            }
        }
        return .failure(.unknown("", "", nil))        
    }
    
    func subscribe<R: Decodable>(request: GraphQLRequest<R>,
                                 valueListener: GraphQLSubscriptionOperation<R>.InProcessListener?,
                                 completionListener: GraphQLSubscriptionOperation<R>.ResultListener?)
        -> GraphQLSubscriptionOperation<R> {
            notify(
                """
                subscribe(request:listener:) document: \(request.document); \
                variables: \(String(describing: request.variables))
                """
            )

            if let responder = responders[.subscribeRequestListener] as? SubscribeRequestListenerResponder<R> {
                if let operation = responder.callback((request, valueListener, completionListener)) {
                    return operation
                }
            }

            let requestOptions = GraphQLOperationRequest<R>.Options(pluginOptions: nil)
            let request = GraphQLOperationRequest<R>(apiName: request.apiName,
                                                     operationType: .subscription,
                                                     document: request.document,
                                                     variables: request.variables,
                                                     responseType: request.responseType,
                                                     options: requestOptions)
            let operation = MockSubscriptionGraphQLOperation(request: request, responseType: request.responseType)
            return operation
    }

    func subscribe<R: Decodable>(request: GraphQLRequest<R>) -> AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<R>> {
        notify(
                """
                subscribe(request:listener:) document: \(request.document); \
                variables: \(String(describing: request.variables))
                """
        )
        
        let requestOptions = GraphQLOperationRequest<R>.Options(pluginOptions: nil)
        let request = GraphQLOperationRequest<R>(apiName: request.apiName,
                                                 operationType: .subscription,
                                                 document: request.document,
                                                 variables: request.variables,
                                                 responseType: request.responseType,
                                                 options: requestOptions)
        
        let taskRunner = MockAWSGraphQLSubscriptionTaskRunner(request: request)
        return taskRunner.sequence
    }
    
    public func reachabilityPublisher(for apiName: String?) -> AnyPublisher<ReachabilityUpdate, Never>? {
        reachabilityPublisher()
    }

    public func reachabilityPublisher() -> AnyPublisher<ReachabilityUpdate, Never>? {
        if let reachabilityPublisher = _reachabilityPublisher as? AnyPublisher<ReachabilityUpdate, Never> {
            return reachabilityPublisher
        } else {
            return Just(ReachabilityUpdate(isOnline: true)).eraseToAnyPublisher()
        }
    }

    // MARK: - REST methods

    func get(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        notify("get")
        let operationRequest = RESTOperationRequest(apiName: request.apiName,
                                                    operationType: .get,
                                                    path: request.path,
                                                    queryParameters: request.queryParameters,
                                                    body: request.body,
                                                    options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: operationRequest)
        return operation
    }
    
    func get(request: RESTRequest) async throws -> RESTTask.Success {
        notify("get")
        return Data()
    }

    func put(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        notify("put")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .put,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        return operation
    }
    
    func put(request: RESTRequest) async throws -> RESTTask.Success {
        notify("put")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .put,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        return try await taskAdapter.value
    }

    func post(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        notify("post")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .post,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        return operation
    }

    func post(request: RESTRequest) async throws -> RESTTask.Success {
        notify("post")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .post,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        return try await taskAdapter.value
    }
    
    func delete(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        notify("delete")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .delete,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        return operation
    }

    func delete(request: RESTRequest) async throws -> RESTTask.Success {
        notify("delete")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .delete,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        return try await taskAdapter.value
    }
    
    func patch(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        notify("patch")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .patch,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        return operation
    }
    
    func patch(request: RESTRequest) async throws -> RESTTask.Success {
        notify("patch")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .patch,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        return try await taskAdapter.value
    }

    func head(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        notify("head")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .head,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        return operation
    }
    
    func head(request: RESTRequest) async throws -> RESTTask.Success {
        notify("head")
        let request = RESTOperationRequest(apiName: request.apiName,
                                           operationType: .head,
                                           path: request.path,
                                           queryParameters: request.queryParameters,
                                           body: request.body,
                                           options: RESTOperationRequest.Options())
        let operation = MockAPIOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        return try await taskAdapter.value
    }
    

    func add(interceptor: URLRequestInterceptor, for apiName: String) {
        notify("addInterceptor")
    }

    // MARK: - APICategoryAuthProviderFactoryBehavior

    func apiAuthProviderFactory() -> APIAuthProviderFactory {
        if let authProviderFactory = authProviderFactory {
            return authProviderFactory
        } else {
            return APIAuthProviderFactory()
        }
    }
}

class MockSecondAPICategoryPlugin: MockAPICategoryPlugin {
    override var key: String {
        return "MockSecondAPICategoryPlugin"
    }
}

class MockGraphQLOperation<R: Decodable>: GraphQLOperation<R> {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request,
         responseType: R.Type) {
        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.mutate,
                   request: request)
    }
}

class MockSubscriptionGraphQLOperation<R: Decodable>: GraphQLSubscriptionOperation<R> {

    override func pause() {
    }

    override func resume() {
    }

    init(request: Request,
         responseType: R.Type) {
        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.subscribe,
                   request: request)
    }
}

class MockAPIOperation: AmplifyOperation<RESTOperationRequest, Data, APIError>, RESTOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .api,
                   eventName: request.operationType.hubEventName,
                   request: request)
    }
}

class MockAPIAuthProviderFactory: APIAuthProviderFactory {
    let oidcProvider: AmplifyOIDCAuthProvider?
    let functionProvider: AmplifyFunctionAuthProvider?

    init(oidcProvider: AmplifyOIDCAuthProvider? = nil,
         functionProvider: AmplifyFunctionAuthProvider? = nil) {
        self.oidcProvider = oidcProvider
        self.functionProvider = functionProvider
    }

    override func functionAuthProvider() -> AmplifyFunctionAuthProvider? {
        return functionProvider
    }

    override func oidcAuthProvider() -> AmplifyOIDCAuthProvider? {
        return oidcProvider
    }
}

class MockOIDCAuthProvider: AmplifyOIDCAuthProvider {
    var result: Result<AuthToken, Error>?
    
    func getLatestAuthToken() async throws -> String {
        if case let .success(token) = result {
            return token
        } else {
            return "token"
        }
    }
}

class MockFunctionAuthProvider: AmplifyFunctionAuthProvider {
    var result: Result<AuthToken, Error>?
    
    func getLatestAuthToken() async throws -> String {
        if case let .success(token) = result {
            return token
        } else {
            return "token"
        }
    }
}

class MockAWSGraphQLSubscriptionTaskRunner<R: Decodable & Sendable>: InternalTaskRunner, InternalTaskAsyncThrowingSequence, InternalTaskThrowingChannel {
    
    public typealias Request = GraphQLOperationRequest<R>
    public typealias InProcess = GraphQLSubscriptionEvent<R>
    public var request: GraphQLOperationRequest<R>
    public var context = InternalTaskAsyncThrowingSequenceContext<GraphQLSubscriptionEvent<R>>()
    func run() async throws {
        
    }
    
    init(request: GraphQLOperationRequest<R>) {
        self.request = request
    }
    
}
