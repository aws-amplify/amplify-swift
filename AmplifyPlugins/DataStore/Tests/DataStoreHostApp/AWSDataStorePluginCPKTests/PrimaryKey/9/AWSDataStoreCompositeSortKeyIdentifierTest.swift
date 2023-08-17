//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import Combine
import AWSAPIPlugin
import AWSDataStorePlugin

@testable import Amplify
#if !os(watchOS)
@testable import DataStoreHostApp
#endif

fileprivate struct TestModels: AmplifyModelRegistration {
    func registerModels(registry: ModelRegistry.Type) {
        ModelRegistry.register(modelType: Post9.self)
        ModelRegistry.register(modelType: Comment9.self)
    }

    public let version: String = "test"
}

class AWSDataStoreCompositeSortKeyIdentifierTest: XCTestCase {
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

    func testCreateModel_withSortKeyInIdType_success() async throws {
        try await waitDataStoreReady()
        var requests: Set<AnyCancellable> = []
        let post = Post9(postId: UUID().uuidString)
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

        let comment = Comment9(commentId: UUID().uuidString, postId: post.postId)
        let commentCreated = expectation(description: "Comment is created")
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .compactMap { $0.data as? MutationEvent }
            .filter { $0.modelId == comment.identifier }
            .sink { _ in
                commentCreated.fulfill()
            }.store(in: &requests)

        try await Amplify.DataStore.save(comment)
        await fulfillment(of: [commentCreated], timeout: 5)
    }

    func testQueryCreatedModel_withSortKeyInIdType_success() async throws {
        try await waitDataStoreReady()
        var requests: Set<AnyCancellable> = []
        let post = Post9(postId: UUID().uuidString)
        try await Amplify.DataStore.save(post)
        let comment = Comment9(commentId: UUID().uuidString, postId: post.postId)

        let commentCreated = expectation(description: "Comment is created")
        commentCreated.assertForOverFulfill = false
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .compactMap { $0.data as? MutationEvent }
            .filter { $0.modelId == comment.identifier }
            .sink { _ in
                commentCreated.fulfill()
            }.store(in: &requests)
        try await Amplify.DataStore.save(comment)
        await fulfillment(of: [commentCreated], timeout: 5)

        let queryResult = try await Amplify.API.query(
            request: .get(
                Comment9.self,
                byIdentifier: .identifier(commentId: comment.commentId, postId: comment.postId)
            )
        )

        switch queryResult {
        case .success(let queriedComment):
            XCTAssertEqual(comment.identifier, queriedComment!.identifier)
        case .failure(let error):
            XCTFail("Failed to query comment \(error)")
        }
    }

}


