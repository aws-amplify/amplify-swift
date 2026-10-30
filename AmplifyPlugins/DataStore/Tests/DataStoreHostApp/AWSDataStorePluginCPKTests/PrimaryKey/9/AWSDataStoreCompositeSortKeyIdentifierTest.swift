//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSAPIPlugin
import AWSDataStorePlugin
import Combine
import XCTest

@testable import Amplify
#if !os(watchOS)
@testable import DataStoreHostApp
#endif

private struct TestModels: AmplifyModelRegistration {
    func registerModels(registry: ModelRegistry.Type) {
        ModelRegistry.register(modelType: Post9.self)
        ModelRegistry.register(modelType: Comment9.self)
    }

    let version: String = "test"
}

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSDataStoreCompositeSortKeyIdentifierTest: XCTestCase, @unchecked Sendable {
    let configFile = "testconfiguration/AWSDataStoreCategoryPluginPrimaryKeyIntegrationTests-amplifyconfiguration"

    override func setUp() async throws {
        continueAfterFailure = true
        let config = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: configFile)
        try Amplify.add(plugin: AWSAPIPlugin(
            sessionFactory: AmplifyURLSessionFactory())
        )
        #if os(watchOS)
        try Amplify.add(plugin: AWSDataStorePlugin(
            modelRegistration: TestModels(),
            configuration: .custom(syncMaxRecords: 100, disableSubscriptions: { false })
        ))
        #else
        try Amplify.add(plugin: AWSDataStorePlugin(
            modelRegistration: TestModels(),
            configuration: .custom(syncMaxRecords: 100)
        ))
        #endif
        Amplify.Logging.logLevel = .verbose
        try Amplify.configure(config)
    }

    override func tearDown() async throws {
        var teardownError: Error?
        do {
            try await Amplify.DataStore.stop()
            try await Amplify.DataStore.clear()
        } catch {
            teardownError = error
        }
        try? await Task.sleep(seconds: 1)
        // Reset even if stop or clear threw, so the next test can configure Amplify.
        await Amplify.reset()
        if let teardownError {
            throw teardownError
        }
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

    /// Query a synced model whose sort key is an `ID`.
    ///
    /// - Given: a `Post9` and its `Comment9` saved to DataStore, and the comment synced to the cloud
    /// - When:
    ///    - the comment is fetched through the API by its `commentId` and `postId`
    /// - Then:
    ///    - the API returns the comment with the same identifier
    ///
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
            let queriedComment = try XCTUnwrap(queriedComment)
            XCTAssertEqual(comment.identifier, queriedComment.identifier)
        case .failure(let error):
            XCTFail("Failed to query comment \(error)")
        }
    }

}


