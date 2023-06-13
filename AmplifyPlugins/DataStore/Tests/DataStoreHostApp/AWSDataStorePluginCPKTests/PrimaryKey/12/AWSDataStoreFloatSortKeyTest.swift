//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/** Model Schema
type Post12 @model {
  postId: ID! @primaryKey(sortKeyFields: ["sk"])
  sk: Float!
}
*/

import Foundation
import Combine
import XCTest
import AWSAPIPlugin
import AWSDataStorePlugin

@testable import Amplify
@testable import DataStoreHostApp

fileprivate struct TestModels: AmplifyModelRegistration {
    func registerModels(registry: ModelRegistry.Type) {
        ModelRegistry.register(modelType: Post12.self)
    }

    var version: String = "test"
}

class AWSDataStoreFloatSortKeyTest: XCTestCase {
    let configFile = "testconfiguration/AWSDataStoreCategoryPluginPrimaryKeyIntegrationTests-amplifyconfiguration"

    override func setUp() async throws {
        continueAfterFailure = true
        let config = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: configFile)
        try Amplify.add(plugin: AWSAPIPlugin(
            sessionFactory: AmplifyURLSessionFactory())
        )
        try Amplify.add(plugin: AWSDataStorePlugin(
            modelRegistration: TestModels(),
            configuration: .custom(syncMaxRecords: 100)
        ))
        Amplify.Logging.logLevel = .verbose
        try Amplify.configure(config)
    }

    override func tearDown() async throws {
        try await Amplify.DataStore.clear()
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    func waitDataStoreReady() async throws {
        let ready = expectation(description: "DataStore is ready")
        var requests: Set<AnyCancellable> = []
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.ready }
            .sink { _ in
                ready.fulfill()
            }
            .store(in: &requests)

        try await Amplify.DataStore.start()
        await fulfillment(of: [ready], timeout: 60)
    }

    func testCreateModel_withSortKeyInDoubleType_success() async throws {
        try await waitDataStoreReady()
        var requests: Set<AnyCancellable> = []
        let post = Post12(postId: UUID().uuidString, sk: 3.1415)
        let postCreated = expectation(description: "Post is created")
        postCreated.assertForOverFulfill = false
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .compactMap { $0.data as? MutationEvent }
            .filter { $0.modelId == post.identifier }
            .sink { _ in
                postCreated.fulfill()
            }.store(in: &requests)

        try await Amplify.DataStore.save(post)
        await fulfillment(of: [postCreated], timeout: 5)
    }

    func testQueryCreatedModel_withSortKeyInDoubleType_success() async throws {
        try await waitDataStoreReady()
        var requests: Set<AnyCancellable> = []
        let post = Post12(postId: UUID().uuidString, sk: 3.1415)
        let postCreated = expectation(description: "Post is created")
        postCreated.assertForOverFulfill = false
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .compactMap { $0.data as? MutationEvent }
            .filter { $0.modelId == post.identifier }
            .sink { _ in
                postCreated.fulfill()
            }.store(in: &requests)

        try await Amplify.DataStore.save(post)
        await fulfillment(of: [postCreated], timeout: 5)

        let queryResult = try await Amplify.API.query(
            request: .get(
                Post12.self,
                byIdentifier: .identifier(postId: post.postId, sk: post.sk)
            )
        )

        switch queryResult {
        case .success(let queriedPost):
            XCTAssertEqual(post.identifier, queriedPost!.identifier)
        case .failure(let error):
            XCTFail("Failed to query comment \(error)")
        }
    }

}


