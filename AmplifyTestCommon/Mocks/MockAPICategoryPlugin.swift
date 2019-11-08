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

    func mutate<R: Decodable>(apiName: String,
                              document: String,
                              variables: [String: Any]?,
                              responseType: R.Type,
                              listener: ((AsyncEvent<Void, GraphQLResponse<R>, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError> {

            notify("mutate")
            let options = GraphQLRequest.Options()
            let request = GraphQLRequest(apiName: apiName,
                                         operationType: .mutation,
                                         document: document,
                                         variables: variables,
                                         options: options)
            let operation = MockGraphQLOperation(request: request, responseType: responseType)
            return operation
    }

    func query<R: Decodable>(apiName: String,
                             document: String,
                             variables: [String: Any]?,
                             responseType: R.Type,
                             listener: ((AsyncEvent<Void, GraphQLResponse<R>, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError> {

            notify("query")
            let options = GraphQLRequest.Options()
            let request = GraphQLRequest(apiName: apiName,
                                         operationType: .query,
                                         document: document,
                                         variables: variables,
                                         options: options)
            let operation = MockGraphQLOperation(request: request, responseType: responseType)
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

class MockGraphQLOperation<R: Decodable>: AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError> {
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
