//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class StorageEngineTestsManyToMany: StorageEngineTestsBase {

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .warn

        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            syncEngine = MockRemoteSyncEngine()
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
            ModelRegistry.register(modelType: M2MPost.self)
            ModelRegistry.register(modelType: M2MPostEditor.self)
            ModelRegistry.register(modelType: M2MUser.self)
            do {
                try storageEngine.setUp(modelSchemas: [M2MPost.schema])
                try storageEngine.setUp(modelSchemas: [M2MPostEditor.schema])
                try storageEngine.setUp(modelSchemas: [M2MUser.schema])

            } catch {
                XCTFail("Failed to setup storage engine")
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testDeletePostAndPostEditor() async {
        var post1 = M2MPost(title: "Post1")
        var user1 = M2MUser(username: "User1")
        let postEditors1 = M2MPostEditor(post: post1, editor: user1)
        post1.editors = [postEditors1]
        user1.posts = [postEditors1]

        var post2 = M2MPost(title: "Post2")
        var user2 = M2MUser(username: "User2")
        let postEditors2 = M2MPostEditor(post: post2, editor: user2)
        post2.editors = [postEditors2]
        user2.posts = [postEditors2]

        guard case .success = await saveModel(model: user1),
            case .success = await saveModel(model: post1),
            case .success = await saveModel(model: postEditors1),
            case .success = await saveModel(model: user2),
            case .success = await saveModel(model: post2),
            case .success = await saveModel(model: postEditors2) else {
                XCTFail("Failed to save hierachy")
                return
        }

        guard case .success =
            querySingleModel(modelType: M2MPost.self,
                                        predicate: M2MPost.keys.id == post1.id) else {
                                            XCTFail("Failed to query M2MPost")
                                            return
        }
        guard case .success =
            querySingleModel(modelType: M2MPostEditor.self,
                                        predicate: M2MPostEditor.keys.id == postEditors1.id) else {
                                            XCTFail("Failed to query M2MPostEditor")
                                            return
        }
        guard case .success =
            querySingleModel(modelType: M2MUser.self,
                                        predicate: M2MUser.keys.id == user1.id) else {
                                            XCTFail("Failed to query M2MUser")
                                            return
        }

        let mutationEvents = expectation(description: "Mutation Events submitted to sync engine")
        mutationEvents.expectedFulfillmentCount = 2

        syncEngine.setCallbackOnSubmit { submittedMutationEvent in
            mutationEvents.fulfill()
            return .success(submittedMutationEvent)
        }
        if case .failure(let error) = await deleteModelOrFailOtherwise(modelType: M2MPost.self,
                                                                    withId: post1.id) {
            XCTFail("Failed to delete post1 \(error.debugDescription)")
            return
        }
        await fulfillment(of: [mutationEvents], timeout: defaultTimeout)
    }

    func testDeleteUserAndPostEditor() async {
        var post1 = M2MPost(title: "Post1")
        var user1 = M2MUser(username: "User1")
        let postEditors1 = M2MPostEditor(post: post1, editor: user1)
        post1.editors = [postEditors1]
        user1.posts = [postEditors1]

        var post2 = M2MPost(title: "Post2")
        var user2 = M2MUser(username: "User2")
        let postEditors2 = M2MPostEditor(post: post2, editor: user2)
        post2.editors = [postEditors2]
        user2.posts = [postEditors2]

        guard case .success = await saveModel(model: user1),
            case .success = await saveModel(model: post1),
            case .success = await saveModel(model: postEditors1),
            case .success = await saveModel(model: user2),
            case .success = await saveModel(model: post2),
            case .success = await saveModel(model: postEditors2) else {
                XCTFail("Failed to save hierachy")
                return
        }

        guard case .success =
            querySingleModel(modelType: M2MPost.self,
                                        predicate: M2MPost.keys.id == post1.id) else {
                                            XCTFail("Failed to query M2MPost")
                                            return
        }
        guard case .success =
            querySingleModel(modelType: M2MPostEditor.self,
                                        predicate: M2MPostEditor.keys.id == postEditors1.id) else {
                                            XCTFail("Failed to query M2MPostEditor")
                                            return
        }
        guard case .success =
            querySingleModel(modelType: M2MUser.self,
                                        predicate: M2MUser.keys.id == user1.id) else {
                                            XCTFail("Failed to query M2MUser")
                                            return
        }

        let mutationEvents = expectation(description: "Mutation Events submitted to sync engine")
        mutationEvents.expectedFulfillmentCount = 2

        syncEngine.setCallbackOnSubmit { submittedMutationEvent in
            mutationEvents.fulfill()
            return .success(submittedMutationEvent)
        }
        guard case .success = await deleteModelOrFailOtherwise(modelType: M2MUser.self,
                                                                    withId: user1.id) else {
            XCTFail("Failed to delete post1")
            return
        }
        wait(for: [mutationEvents], timeout: defaultTimeout)
    }
}
