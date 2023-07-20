//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/** Model Schema
type Post19 @model {
    postId: ID! @primaryKey(sortKeyFields: ["sk"])
    sk: AWSIPAddress!
}
*/


import Foundation
import Combine
import XCTest
@testable import Amplify

fileprivate struct TestModels: AmplifyModelRegistration {
    func registerModels(registry: ModelRegistry.Type) {
        ModelRegistry.register(modelType: Post19.self)
    }

    public let version: String = "test"
}


class AWSDataStoreAWSIPAddressSortKeyTest: AWSDataStoreSortKeyBaseTest {
    func testCreateModel_withSortKeyInIPV4Type_success() async throws {
        try await setUp(models: TestModels())
        try await waitDataStoreReady()
        var requests: Set<AnyCancellable> = []

        let post = Post19(postId: UUID().uuidString, sk: "1.1.1.1/16")
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

    func testCreateModel_withSortKeyInIPV6Type_success() async throws {
        try await setUp(models: TestModels())
        try await waitDataStoreReady()
        var requests: Set<AnyCancellable> = []

        let post = Post19(postId: UUID().uuidString, sk: "1a2b:3c4b::1234:4567")
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

    func testQueryCreatedModel_withSortKeyInAWSIPAddressType_success() async throws {
        try await setUp(models: TestModels())
        try await waitDataStoreReady()
        var requests: Set<AnyCancellable> = []

        let post = Post19(postId: UUID().uuidString, sk: "1.1.1.1/16")
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
                Post19.self,
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
