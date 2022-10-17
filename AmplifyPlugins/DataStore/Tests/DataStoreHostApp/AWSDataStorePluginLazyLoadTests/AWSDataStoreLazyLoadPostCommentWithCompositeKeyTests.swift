//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify

final class AWSDataStoreLazyLoadPostCommentWithCompositeKeyTests: AWSDataStoreLazyLoadBaseTest {

    func testLazyLoadPostFromComment() async throws {
        await setup(withModels: PostCommentWithCompositeKeyModels(), logLevel: .verbose, eagerLoad: false)
        
        // Save a comment with post
        let post = PostWithCompositeKey(title: "title")
        let comment = CommentWithCompositeKey(content: "content", post: post)
        let commentSynced = asyncExpectation(description: "comment was synced successfully")
        let mutationEvents = Amplify.DataStore.observe(CommentWithCompositeKey.self)
        Task {
            do {
                for try await mutationEvent in mutationEvents {
                    if mutationEvent.version == 1 && mutationEvent.modelId == comment.identifier {
                        await commentSynced.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        try await Amplify.DataStore.save(post)
        let savedComment = try await Amplify.DataStore.save(comment)
        await waitForExpectations([commentSynced], timeout: 10)

        switch savedComment._post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("The result from the save API should be a loaded post")
        case .loaded(let loadedPost):
            XCTAssertEqual(loadedPost?.id, post.id)
        }
        guard let loadedPost = try await savedComment.post else {
            XCTFail("Failed to retrieve the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.id, post.id)
        guard let queriedComment = try await Amplify.DataStore.query(CommentWithCompositeKey.self,
                                                                     byIdentifier: .identifier(
                                                                        id: comment.id,
                                                                        content: comment.content)) else {
            XCTFail("Failed to query comment")
            return
        }
        switch queriedComment._post.modelProvider.getState() {
        case .notLoaded(let identifiers):
            guard let identifier = identifiers.first else {
                XCTFail("missing identifiers")
                return
            }
            XCTAssertEqual(identifier.key, "@@primaryKey")
            XCTAssertEqual(identifier.value, post.identifier)
        case .loaded:
            XCTFail("Should be not loaded when queried")
        }
        guard let loadedPost2 = try await queriedComment.post else {
            XCTFail("Failed to retrieve the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost2.id, post.id)
    }
}


extension AWSDataStoreLazyLoadPostCommentWithCompositeKeyTests {
    struct PostCommentWithCompositeKeyModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PostWithCompositeKey.self)
            ModelRegistry.register(modelType: CommentWithCompositeKey.self)
        }
    }
}
