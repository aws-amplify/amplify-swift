//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/** Model Schema
type Post17 @model {
    postId: ID! @primaryKey(sortKeyFields: ["sk"])
    sk: AWSEmail!
}
*/


import Foundation
import Combine
import XCTest
@testable import Amplify

fileprivate struct TestModels: AmplifyModelRegistration {
    func registerModels(registry: ModelRegistry.Type) {
        ModelRegistry.register(modelType: Post17.self)
    }

    public let version: String = "test"
}


class AWSDataStoreAWSEmailSortKeyTest: AWSDataStoreSortKeyBaseTest {
    func testCreateModel_withSortKeyInAWSEmailType_success() async throws {
        try await setUp(models: TestModels())
        try await waitDataStoreReady()
        var requests: Set<AnyCancellable> = []

        let post = Post17(postId: UUID().uuidString, sk: "test@example.com")
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

    func testQueryCreatedModel_withSortKeyInAWSEmailType_success() async throws {
        try await setUp(models: TestModels())
        try await waitDataStoreReady()
        var requests: Set<AnyCancellable> = []

        let post = Post17(postId: UUID().uuidString, sk: "test@example.com")
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
                Post17.self,
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
