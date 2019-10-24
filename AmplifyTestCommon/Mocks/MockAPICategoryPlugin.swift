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

    func graphql(apiName: String,
                 operationType: GraphQLOperationType,
                 document: String,
                 listener: GraphQLOperation.EventListener?) -> GraphQLOperation {
        notify("graphql")
        let options = GraphQLRequest.Options()
        let request = GraphQLRequest(apiName: apiName,
                                     operationType: operationType,
                                     document: document,
                                     options: options)
        let operation = MockGraphQLOperation(request: request)
        return operation
    }

    func get(apiName: String,
             path: String,
             listener: APIOperation.EventListener?) -> APIOperation {
        notify("get")
        let request = APIGetRequest(apiName: apiName,
                                    path: path,
                                    options: APIGetRequest.Options())
        let operation = MockAPIGetOperation(request: request)
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

class MockGraphQLOperation: AmplifyOperation<GraphQLRequest, Void, Codable, StorageError>,
GraphQLOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.graphql,
                   request: request)
    }
}

class MockAPIGetOperation: AmplifyOperation<APIGetRequest, Void, Data, APIError>, APIOperation {
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
