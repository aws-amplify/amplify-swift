//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

class MockAPICategoryPlugin: MessageReporter, APICategoryPlugin {
    var responders = [ResponderKeys: Any]()

    // MARK: - Properties

    var key: String {
        return "MockAPICategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify("configure")
    }

    func reset(onComplete: @escaping BasicClosure) {
        notify("reset")
        listeners = []
        onComplete()
    }

    // MARK: - Model-based GraphQL methods

    func query<M>(from modelType: M.Type,
                  byId id: String,
                  listener: GraphQLOperation<M?>.ResultListener?) -> GraphQLOperation<M?> {
        fatalError("Not yet implemented")
    }

    func query<M>(from modelType: M.Type,
                  where predicate: QueryPredicate?,
                  listener: GraphQLOperation<[M]>.ResultListener?) -> GraphQLOperation<[M]> {
        fatalError("Not yet implemented")
    }

    func mutate<M: Model>(of model: M,
                          type: GraphQLMutationType,
                          listener: GraphQLOperation<M>.ResultListener?) -> GraphQLOperation<M> {
        notify("mutate(of:\(model.modelName)-\(model.id),type:\(type),listener:)")
        let options = GraphQLOperationRequest<M>.Options()
        let request = GraphQLOperationRequest<M>(apiName: nil,
                                                 operationType: .subscription,
                                                 document: "",
                                                 variables: nil,
                                                 responseType: M.self,
                                                 options: options)
        let operation = MockGraphQLOperation(request: request, responseType: M.self)
        return operation
    }

    func mutate(ofAnyModel anyModel: AnyModel,
                type: GraphQLMutationType,
                listener: GraphQLOperation<AnyModel>.ResultListener?) -> GraphQLOperation<AnyModel> {
        notify("mutate(ofAnyModel:\(anyModel.modelName)-\(anyModel.id),type:\(type),listener:)")

        let options = GraphQLOperationRequest<AnyModel>.Options()
        let request = GraphQLOperationRequest<AnyModel>(apiName: nil,
                                                        operationType: .subscription,
                                                        document: "",
                                                        variables: nil,
                                                        responseType: AnyModel.self,
                                                        options: options)
        let operation = MockGraphQLOperation(request: request, responseType: AnyModel.self)
        return operation
    }

    func subscribe<M: Model>(from modelType: M.Type,
                             type: GraphQLSubscriptionType,
                             valueListener: GraphQLSubscriptionOperation<M>.InProcessListener?,
                             completionListener: GraphQLSubscriptionOperation<M>.ResultListener?
    ) -> GraphQLSubscriptionOperation<M> {
        notify("subscribe(from:\(modelType),type:\(type),listener:)")

        let options = GraphQLOperationRequest<M>.Options()
        let request = GraphQLOperationRequest<M>(apiName: nil,
                                                 operationType: .subscription,
                                                 document: "",
                                                 variables: nil,
                                                 responseType: M.self,
                                                 options: options)
        let operation = MockSubscriptionGraphQLOperation(request: request, responseType: M.self)
        return operation
    }

    func subscribe(toAnyModelType modelType: Model.Type,
                   subscriptionType: GraphQLSubscriptionType,
                   valueListener: GraphQLSubscriptionOperation<AnyModel>.InProcessListener?,
                   completionListener: GraphQLSubscriptionOperation<AnyModel>.ResultListener?
    ) -> GraphQLSubscriptionOperation<AnyModel> {
            notify("subscribe(toAnyModelType:\(modelType),subscriptionType:\(subscriptionType),listener:)")
            let options = GraphQLOperationRequest<AnyModel>.Options()
            let request = GraphQLOperationRequest<AnyModel>(apiName: nil,
                                                            operationType: .subscription,
                                                            document: "",
                                                            variables: nil,
                                                            responseType: AnyModel.self,
                                                            options: options)
            let operation = MockSubscriptionGraphQLOperation(request: request, responseType: request.responseType)
            return operation
    }

    func subscribe<R: Decodable>(request: GraphQLRequest<R>,
                                 valueListener: GraphQLSubscriptionOperation<R>.InProcessListener?,
                                 completionListener: GraphQLSubscriptionOperation<R>.ResultListener?)
        -> GraphQLSubscriptionOperation<R> {
        fatalError("Not implemented")
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
        let options = GraphQLOperationRequest<R>.Options()
        let request = GraphQLOperationRequest<R>(apiName: request.apiName,
                                                 operationType: .mutation,
                                                 document: request.document,
                                                 variables: request.variables,
                                                 responseType: request.responseType,
                                                 options: options)
        let operation = MockGraphQLOperation(request: request, responseType: request.responseType)
        return operation
    }

    func query<R: Decodable>(request: GraphQLRequest<R>,
                             listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        notify("query(request:listener:) request: \(request)")

        if let responder = responders[.queryRequestListener] as? QueryRequestListenerResponder<R> {
            if let operation = responder.callback((request, listener)) {
                return operation
            }
        }

        let options = GraphQLOperationRequest<R>.Options()
        let request = GraphQLOperationRequest<R>(apiName: request.apiName,
                                                 operationType: .query,
                                                 document: request.document,
                                                 variables: request.variables,
                                                 responseType: request.responseType,
                                                 options: options)
        let operation = MockGraphQLOperation(request: request, responseType: request.responseType)

        return operation
    }

    func subscribe<R: Decodable>(request: GraphQLRequest<R>,
                                 listener: GraphQLSubscriptionOperation<R>.ResultListener?) ->
        GraphQLSubscriptionOperation<R> {
            notify(
                """
                subscribe(request:listener:) document: \(request.document); \
                variables: \(String(describing: request.variables))
                """
            )

            if let responder = responders[.subscribeRequestListener] as? SubscribeRequestListenerResponder<R> {
                if let operation = responder.callback((request, listener)) {
                    return operation
                }
            }

            let options = GraphQLOperationRequest<R>.Options()
            let request = GraphQLOperationRequest<R>(apiName: request.apiName,
                                                     operationType: .subscription,
                                                     document: request.document,
                                                     variables: request.variables,
                                                     responseType: request.responseType,
                                                     options: options)
            let operation = MockSubscriptionGraphQLOperation(request: request, responseType: request.responseType)
            return operation
    }

    @available(iOS 13.0, *)
    public func reachabilityPublisher(for apiName: String?) -> AnyPublisher<ReachabilityUpdate, Never>? {
        return nil
    }

    @available(iOS 13.0, *)
    public func reachabilityPublisher() -> AnyPublisher<ReachabilityUpdate, Never>? {
        return nil
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

    func add(interceptor: URLRequestInterceptor, for apiName: String) {
        notify("addInterceptor")
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
