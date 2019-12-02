//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// TODO: Delete mutation events from the database so that this can be run multiple times without having to remove the
// app from the device/simulator
@available(iOS 13.0, *)
class SubscriptionTests: SyncEngineIntegrationTestBase {

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I start Amplify
    /// - Then:
    ///    - I receive subscriptions from other systems for syncable models
    func testSubscribeAtStartup() throws {
        try startAmplifyAndWaitForSync()

        let createdMutationReceived = expectation(description: "Created mutation received")
        let updatedMutationReceived = expectation(description: "Updated mutation received")
        let deletedMutationReceived = expectation(description: "Deleted mutation received")

        // TODO: this fails until we link up DataStorePublisher to the ReconcileAndLocalSaveOperation
        let sub = Amplify.DataStore.publisher(for: Post.self)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            }, receiveValue: { mutationEvent in
                guard let model = try? mutationEvent.decodeModel(as: Post.self) else {
                    XCTFail("Couldn't decode model")
                    return
                }
                print("Mutation event received: \(mutationEvent)")
            })

            // Simulate another system by creating, updating, and deleting a model directly via the API
//            let newPost = Post(title: "Post title",
//                               content: "Post content")
//            _ = Amplify.API.mutate(of: newPost, type: .create) { event in
//                print("Created event received: \(event)")
//            }

//            let updatedPost = Post(id: newPost.id,
//                                   title: newPost.title,
//                                   content: "Updated post content",
//                                   createdAt: newPost.createdAt,
//                                   updatedAt: newPost.updatedAt,
//                                   rating: newPost.rating,
//                                   draft: newPost.draft,
//                                   _version: 1)
//            _ = Amplify.API.mutate(of: updatedPost, type: .update, listener: nil)
//
//            let deletedPost = Post(id: updatedPost.id,
//                                   title: updatedPost.title,
//                                   content: "Updated post content",
//                                   createdAt: updatedPost.createdAt,
//                                   updatedAt: updatedPost.updatedAt,
//                                   rating: updatedPost.rating,
//                                   draft: updatedPost.draft,
//                                   _version: 2)
//            _ = Amplify.API.mutate(of: deletedPost, type: .delete, listener: nil)

        wait(for: [createdMutationReceived, updatedMutationReceived, deletedMutationReceived],
             timeout: networkTimeout * 10) //TODO: Remove this extra time

        sub.cancel()
    }

}
