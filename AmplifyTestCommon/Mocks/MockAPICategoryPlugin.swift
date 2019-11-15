//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockAPICategoryPlugin: MessageReporter, APICategoryPlugin {

    var key: String {
        return "MockAPICategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify("configure")
    }

    func reset(onComplete: @escaping BasicClosure) {
        notify("reset")
        onComplete()
    }

    func mutate<R>(request: GraphQLRequest<R>,
                   listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {

        notify("mutate")
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
                             listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {

        notify("query")
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
                                 listener: GraphQLSubscriptionOperation<R>.EventListener?) ->
        GraphQLSubscriptionOperation<R> {
            notify("subscribe")
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

    func get(apiName: String,
             path: String,
             listener: RESTOperation.EventListener?) -> RESTOperation {
        notify("get")
        let request = RESTRequest(apiName: apiName,
                                  operationType: .get,
                                  path: path,
                                  options: RESTRequest.Options())
        let operation = MockAPIGetOperation(request: request)
        return operation
    }

    func post(apiName: String,
              path: String,
              body: Data?,
              listener: ((AsyncEvent<Void, Data, APIError>) -> Void)?) -> RESTOperation {
        notify("post")
        let request = RESTRequest(apiName: apiName,
                                  operationType: .post,
                                  path: path,
                                  body: body,
                                  options: RESTRequest.Options())
        let operation = MockAPIPostOperation(request: request)
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

class MockAPIGetOperation: AmplifyOperation<RESTRequest, Void, Data, APIError>, RESTOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.get,
                   request: request)
    }
}

class MockAPIPostOperation: AmplifyOperation<RESTRequest, Void, Data, APIError>, RESTOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.post,
                   request: request)
    }
}
