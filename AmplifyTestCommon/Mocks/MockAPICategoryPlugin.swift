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

    func mutate<R>(apiName: String,
                   document: String,
                   variables: [String: Any]?,
                   responseType: R,
                   listener: ((AsyncEvent<Void, GraphQLResponse<R.SerializedObject>, GraphQLError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R.SerializedObject>, GraphQLError> where R: ResponseType {

        notify("graphql")
        let options = GraphQLRequest.Options()
        let request = GraphQLRequest(apiName: apiName,
                                     operationType: .mutation,
                                     document: document,
                                     variables: variables,
                                     options: options)
        let operation = MockGraphQLOperation(request: request, responseType: responseType)
        return operation
    }

    func query<R>(apiName: String,
                  document: String,
                  variables: [String: Any]?,
                  responseType: R,
                  listener: ((AsyncEvent<Void, GraphQLResponse<R.SerializedObject>, GraphQLError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R.SerializedObject>, GraphQLError> where R: ResponseType {

        notify("graphql")
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
             listener: APIOperation.EventListener?) -> APIOperation {
        notify("get")
        let request = APIRequest(apiName: apiName,
                                 operationType: .get,
                                 path: path,
                                 options: APIRequest.Options())
        let operation = MockAPIGetOperation(request: request)
        return operation
    }

    func post(apiName: String,
              path: String,
              body: String?,
              listener: ((AsyncEvent<Void, Data, APIError>) -> Void)?) -> APIOperation {
        notify("post")
        let request = APIRequest(apiName: apiName,
                                 operationType: .post,
                                 path: path,
                                 body: body,
                                 options: APIRequest.Options())
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

class MockResponseType: ResponseType {
    typealias SerializedObject = Data
}

class MockGraphQLOperation<R>: AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R.SerializedObject>, GraphQLError> where R: ResponseType {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request, responseType: R) {
        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.mutate,
                   request: request)
    }
}

class MockAPIGetOperation: AmplifyOperation<APIRequest, Void, Data, APIError>, APIOperation {
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

class MockAPIPostOperation: AmplifyOperation<APIRequest, Void, Data, APIError>, APIOperation {
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
