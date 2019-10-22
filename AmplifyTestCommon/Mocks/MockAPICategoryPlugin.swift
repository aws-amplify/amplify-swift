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

    func delete() {
        notify("delete")
    }

    func get() {
        notify("get")
    }

    func head() {
        notify("head")
    }

    func options() {
        notify("options")
    }

    func patch() {
        notify("patch")
    }

    func post() {
        notify("post")
    }

    func put() {
        notify("put")
    }

    func reset(onComplete: @escaping (() -> Void)) {
        notify("reset")
        onComplete()
    }

    func graphql<T>(apiName: String,
                    operationType: GraphQLOperationType,
                    document: String,
                    classToCast: T.Type,
                    callback: () -> Void) -> GraphQLOperation where T: Decodable, T: Encodable {
        notify("graphql")
        let request = GraphQLRequest(key: "foo", options: GraphQLRequest.Options())
        let operation = MockGraphQLOperation(request: request)
        return operation
    }

    func addInterceptor() {
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
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.getURL,
                   request: request)
    }
}
