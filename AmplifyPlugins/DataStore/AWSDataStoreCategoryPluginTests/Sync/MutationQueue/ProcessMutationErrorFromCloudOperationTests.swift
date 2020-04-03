//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStoreCategoryPlugin

@available(iOS 13.0, *)
class ProcessMutationErrorFromCloudOperationTests: XCTestCase {
    let defaultAsyncWaitTimeout = 10.0
    override func setUp() {
        tryOrFail {
            try setUpWithAPI()
        }
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
    }

    func testProcessMutationErrorFromCloudOperationSuccess() throws {
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let expectHubEvent = expectation(description: "Hub is notified")

        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.conditionalSaveFailed" {
                expectHubEvent.fulfill()
            }
        }

        let completion: (Result<Void, Error>) -> Void = { result in
            expectCompletion.fulfill()
        }
        let post1 = Post(title: "post1", content: "content1", createdAt: Date())
        let mutationEvent = try MutationEvent(model: post1, mutationType: .create)
        let graphQLError = GraphQLError(message: "conditional request failed",
                                  locations: nil,
                                  path: nil,
                                  extensions: nil)
        let graphQLResponseError = GraphQLResponseError<MutationSync<AnyModel>>.error([graphQLError])

        let operation = ProcessMutationErrorFromCloudOperation(mutationEvent: mutationEvent,
                                                               error: graphQLResponseError,
                                                               completion: completion)

        let queue = OperationQueue()
        queue.addOperation(operation)

        wait(for: [expectHubEvent], timeout: defaultAsyncWaitTimeout)

        Amplify.Hub.removeListener(hubListener)

        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }
}

extension ProcessMutationErrorFromCloudOperationTests {
    private func setUpCore() throws -> AmplifyConfiguration {
        Amplify.reset()

        let storageEngine = MockStorageEngineBehavior()
        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngine: storageEngine,
                                                 dataStorePublisher: dataStorePublisher)
        try Amplify.add(plugin: dataStorePlugin)
        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        return amplifyConfig
    }

    private func setUpWithAPI() throws {
        try Amplify.configure(try setUpCore())
    }
}
