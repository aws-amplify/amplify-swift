//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class ListTests: BaseDataStoreTests {

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed asynchronously with a callback
    /// - Then:
    ///   - the list should be correctly loaded and populated
    func testAsynchronousLazyLoadWithCallback() async throws {
        let expect = expectation(description: "a lazy list should return the correct results")

        let postId = preparePostDataForTest()

        func checkComments(_ comments: List<Comment>) async throws {
            guard case .notLoaded = comments.loadedState else {
                XCTFail("Should not be loaded")
                return
            }
            try await comments.fetch()
            guard case .loaded = comments.loadedState else {
                XCTFail("Should be loaded")
                return
            }
            XCTAssertEqual(comments.count, 2)
            expect.fulfill()
        }
        
        do {
            let result = try await Amplify.DataStore.query(Post.self, byId: postId)
            if let post = result, let comments = post.comments {
                try await checkComments(comments)
            } else {
                XCTFail("Failed to query recently saved post by id")
            }
        } catch {
            XCTFail("\(error)")
        }
    
        await waitForExpectations(timeout: 1)
    }

    // MARK: - Helpers

    func preparePostDataForTest() -> String {
        let post = Post(title: "title", content: "content", createdAt: .now())
        populateData([post])
        populateData([
            Comment(content: "Comment 1", createdAt: .now(), post: post),
            Comment(content: "Comment 2", createdAt: .now(), post: post)
        ])
        return post.id
    }
}
