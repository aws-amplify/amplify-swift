//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class DataStoreLocalStoreTests: LocalStoreIntegrationTestBase {

    /// - Given: 15 posts that has been saved
    /// - When:
    ///    - attempt to query existing posts with offset and limit
    /// - Then:
    ///    - the existing data that matches offset and limit will be returned
    func testQueryWithPaginationInput() throws {
        _ = setUpLocalStore(numberOfPosts: 15)
        var posts = [Post]()
        let queryFirstTimeSuccess = expectation(description: "Query post completed")

        Amplify.DataStore.query(Post.self,
                                paginate: .page(0, limit: 10)) { result in
            switch result {
            case .success(let returnPosts):
                posts.append(contentsOf: returnPosts)
                queryFirstTimeSuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [queryFirstTimeSuccess], timeout: 10)

        XCTAssertTrue(posts.count == 10)

        let querySecondTimeSuccess = expectation(description: "Query post completed")
        Amplify.DataStore.query(Post.self,
                                paginate: .page(1, limit: 10)) { result in
            switch result {
            case .success(let returnPosts):
                posts.append(contentsOf: returnPosts)
                querySecondTimeSuccess.fulfill()
            case .failure(let error):
                XCTFail("Error querying posts: \(error)")
            }
        }
        wait(for: [querySecondTimeSuccess], timeout: 10)

        XCTAssertTrue(posts.count == 15)

        let idArray = posts.map { $0.id }
        let idSet = Set(idArray)
        
        XCTAssertTrue(idSet.count == 15)
    }

    func setUpLocalStore(numberOfPosts: Int) -> [Post] {
        var savedPosts = [Post]()
        for _ in 0 ..< numberOfPosts {
            let saveSuccess = expectation(description: "Save post completed")
            let post = Post(title: "title\(Int.random(in: 0 ... 5))",
                            content: "content",
                            createdAt: .now(),
                            rating: Double(Int.random(in: 0 ... 5)))
            savedPosts.append(post)
            Amplify.DataStore.save(post) { result in
                switch result {
                case .success:
                    saveSuccess.fulfill()
                case .failure(let error):
                    XCTFail("Error saving post, \(error)")
                }
            }
            wait(for: [saveSuccess], timeout: 10)
        }
        return savedPosts
    }
}
