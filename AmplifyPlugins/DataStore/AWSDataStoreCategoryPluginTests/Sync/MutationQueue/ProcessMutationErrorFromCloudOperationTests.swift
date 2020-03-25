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
    var mockAPIPlugin: MockAPICategoryPlugin!
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    override func setUp() {
        tryOrFail {
            try setUpWithAPI()
        }
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)

        storageAdapter = MockSQLiteStorageEngineAdapter()
    }

    func testProcessMutationErrorFromCloudOperationSuccess() throws {
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let expectAPIQuery = expectation(description: "call to API.query")
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

        var listenerForApiRequestOptional: GraphQLOperation<MutationSync<AnyModel>?>.EventListener?
        let responder = QueryRequestListenerResponder<MutationSync<AnyModel>?> { _, eventListener in

            listenerForApiRequestOptional = eventListener
            expectAPIQuery.fulfill()
            return nil
        }

        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(id: model.id,
                                                      deleted: false,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: 2)
        let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)

        mockAPIPlugin.responders[.queryRequestListener] = responder

        storageAdapter.returnOnSave(dataStoreResult: .success(anyModel))
        storageAdapter.shouldReturnErrorOnSaveMetadata = false

        let operation = ProcessMutationErrorFromCloudOperation(mutationEvent: mutationEvent,
                                                               storageAdapter: storageAdapter,
                                                               error: graphQLResponseError,
                                                               api: mockAPIPlugin,
                                                               completion: completion)

        let queue = OperationQueue()
        queue.addOperation(operation)

        wait(for: [expectAPIQuery], timeout: defaultAsyncWaitTimeout)

        guard let listenerForApiRequest = listenerForApiRequestOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }

        listenerForApiRequest(.completed(.success(remoteMutationSync)))

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

    private func setUpAPICategory(config: AmplifyConfiguration) throws -> AmplifyConfiguration {
        mockAPIPlugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: mockAPIPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: config.dataStore)
        return amplifyConfig
    }

    private func setUpWithAPI() throws {
        let configWithoutAPI = try setUpCore()
        let configWithAPI = try setUpAPICategory(config: configWithoutAPI)
        try Amplify.configure(configWithAPI)
    }
}
