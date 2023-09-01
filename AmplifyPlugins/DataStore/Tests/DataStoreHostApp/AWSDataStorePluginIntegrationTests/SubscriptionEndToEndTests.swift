//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine
import AWSPluginsCore

@testable import Amplify
@testable import AWSDataStorePlugin
#if !os(watchOS)
@testable import DataStoreHostApp
#endif

class SubscriptionEndToEndTests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post.self)
            registry.register(modelType: Comment.self)
        }

        let version: String = "1"
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I start Amplify
    /// - Then:
    ///    - I receive subscriptions from other systems for syncable models
    func testSubscribeReceivesCreateMutateDelete() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        // Filter all events to ensure they have this ID. This prevents us from overfulfilling on
        // unrelated subscriptions
        let id = UUID().uuidString

        let originalContent = "Original content from SubscriptionTests at \(Date())"
        let updatedContent = "UPDATED CONTENT from SubscriptionTests at \(Date())"

        let createReceived = expectation(description: "createReceived")
        let updateReceived = expectation(description: "updateReceived")
        let deleteReceived = expectation(description: "deleteReceived")

        var cancellables = Set<AnyCancellable>()
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .compactMap { $0.data as? MutationEvent }
            .filter { $0.modelId == id }
            .map(\.mutationType)
            .sink {
                switch $0 {
                case GraphQLMutationType.create.rawValue:
                    createReceived.fulfill()
                case GraphQLMutationType.update.rawValue:
                    updateReceived.fulfill()
                case GraphQLMutationType.delete.rawValue:
                    deleteReceived.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Act: send create mutation
        try await sendCreateRequest(withId: id, content: originalContent)
        await fulfillment(of: [createReceived], timeout: 10)
        // Assert
        let createSyncData = await getMutationSync(forPostWithId: id)
        XCTAssertNotNil(createSyncData)
        let createdPost = createSyncData?.model.instance as? Post
        XCTAssertNotNil(createdPost)
        XCTAssertEqual(createdPost?.content, originalContent)
        XCTAssertEqual(createSyncData?.syncMetadata.version, 1)
        XCTAssertEqual(createSyncData?.syncMetadata.deleted, false)
        
        // Act: send update mutation
        try await sendUpdateRequest(forId: id, content: updatedContent, version: 1)
        await fulfillment(of: [updateReceived], timeout: 10)
        // Assert
        let updateSyncData = await getMutationSync(forPostWithId: id)
        XCTAssertNotNil(updateSyncData)
        let updatedPost = updateSyncData?.model.instance as? Post
        XCTAssertNotNil(updatedPost)
        XCTAssertEqual(updatedPost?.content, updatedContent)
        XCTAssertEqual(updateSyncData?.syncMetadata.version, 2)
        XCTAssertEqual(updateSyncData?.syncMetadata.deleted, false)
        
        // Act: send delete mutation
        try await sendDeleteRequest(forId: id, version: 2)
        await fulfillment(of: [deleteReceived], timeout: 10)
        // Assert
        let deleteSyncData = await getMutationSync(forPostWithId: id)
        XCTAssertNil(deleteSyncData)
    }

    // MARK: - Utilities

    func sendCreateRequest(withId id: Model.Identifier, content: String) async throws {
        // Note: The hand-written documents must include the sync/conflict resolution fields in order for the
        // subscription to get them
        let document = """
        mutation CreatePost($input: CreatePostInput!) { createPost(input: $input) {id content createdAt draft rating
        title updatedAt __typename _version _deleted _lastChangedAt } }
        """

        let input: [String: Any] = ["input":
            [
                "id": id,
                "title": Optional("This is a new post I created"),
                "content": content,
                "createdAt": Temporal.DateTime.now().iso8601String,
                "draft": nil,
                "rating": nil,
                "updatedAt": nil
            ]
        ]

        let request = GraphQLRequest(document: document,
                                     variables: input,
                                     responseType: Post.self,
                                     decodePath: "createPost")

        let graphQLResult = try await Amplify.API.mutate(request: request)
        switch graphQLResult {
        case .success(let post):
            XCTAssertNotNil(post)
        case .failure(let errors):
            XCTFail(String(describing: errors))
        }
    }

    func sendUpdateRequest(forId id: String, content: String, version: Int) async throws {
        // Note: The hand-written documents must include the sync/conflict resolution fields in order for the
        // subscription to get them
        let document = """
        mutation UpdatePost($input: UpdatePostInput!) { updatePost(input: $input) {id content createdAt draft rating
        title updatedAt __typename _version _deleted _lastChangedAt } }
        """

        let input: [String: Any] = ["input":
            [
                "id": id,
                "content": content,
                "_version": version
            ]
        ]

        let request = GraphQLRequest(document: document,
                                     variables: input,
                                     responseType: Post.self,
                                     decodePath: "updatePost")

        let graphQLResult = try await Amplify.API.mutate(request: request)
        switch graphQLResult {
        case .success(let post):
            XCTAssertNotNil(post)
        case .failure(let errors):
            XCTFail(String(describing: errors))
        }
    }

    func sendDeleteRequest(forId id: String, version: Int) async throws {
        // Note: The hand-written documents must include the sync/conflict resolution fields in order for the
        // subscription to get them
        let document = """
        mutation DeletePost($input: DeletePostInput!) { deletePost(input: $input) {id content createdAt draft rating
        title updatedAt __typename _version _deleted _lastChangedAt } }
        """

        let input: [String: Any] = ["input":
            [
                "id": id,
                "_version": version
            ]
        ]

        let request = GraphQLRequest(document: document,
                                     variables: input,
                                     responseType: Post.self,
                                     decodePath: "deletePost")

        let graphQLResult = try await Amplify.API.mutate(request: request)
        switch graphQLResult {
        case .success(let post):
            XCTAssertNotNil(post)
        case .failure(let errors):
            XCTFail(String(describing: errors))
        }
    }

    func getMutationSync(forPostWithId id: String) async -> MutationSync<AnyModel>? {
        let queryComplete = expectation(description: "Query completed")
        var postFromQuery: Post?
        storageAdapter.query(Post.self, predicate: Post.keys.id == id) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let posts):
                // swiftlint:disable:next force_try
                postFromQuery = try! posts.unique()
            }
            queryComplete.fulfill()
        }
        await fulfillment(of: [queryComplete], timeout: networkTimeout)
        guard let post = postFromQuery else {
            return nil
        }

        let mutationSync = try? storageAdapter.queryMutationSync(for: [post], modelName: Post.modelName).first

        return mutationSync
    }

}
