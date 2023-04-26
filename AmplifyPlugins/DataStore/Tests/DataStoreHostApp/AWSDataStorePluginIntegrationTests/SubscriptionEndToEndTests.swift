//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore

@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

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

        let createReceived = asyncExpectation(description: "createReceived")
        let updateReceived = asyncExpectation(description: "updateReceived")
        let deleteReceived = asyncExpectation(description: "deleteReceived")

        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Can't cast payload as mutation event")
                return
            }
            guard mutationEvent.modelId == id else {
                print("Received unrelated mutation, skipping \(mutationEvent)")
                return
            }
            switch mutationEvent.mutationType {
            case GraphQLMutationType.create.rawValue:
                Task { await createReceived.fulfill() }
            case GraphQLMutationType.update.rawValue:
                Task { await updateReceived.fulfill() }
            case GraphQLMutationType.delete.rawValue:
                Task { await deleteReceived.fulfill() }
            default:
                break
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // Act: send create mutation
        try await sendCreateRequest(withId: id, content: originalContent)
        await waitForExpectations([createReceived], timeout: networkTimeout)
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
        await waitForExpectations([updateReceived], timeout: networkTimeout)
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
        await waitForExpectations([deleteReceived], timeout: networkTimeout)
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

        var postFromQuery: Post?
        let result = storageAdapter.query(
            Post.self,
            modelSchema: Post.schema,
            condition: Post.keys.id == id,
            sort: nil,
            paginationInput: nil,
            eagerLoad: true
        )

        switch result {
        case .failure(let error):
            XCTFail(String(describing: error))
        case .success(let posts):
            // swiftlint:disable:next force_try
            postFromQuery = try! posts.unique()
        }

        guard let post = postFromQuery else {
            return nil
        }

        let mutationSync = try? storageAdapter.queryMutationSync(for: [post], modelName: Post.modelName).first

        return mutationSync
    }

}
