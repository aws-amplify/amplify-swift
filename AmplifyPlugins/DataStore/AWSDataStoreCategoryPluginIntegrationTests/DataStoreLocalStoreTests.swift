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
    ///    - query with pagination input given a page number and limit 10
    /// - Then:
    ///    - first page returns the 10 (the defined limit) of 15 posts
    ///    - second page returns the remaining 5 posts
    ///    - the 15 retrieved posts have unique identifiers
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

        XCTAssertEqual(posts.count, 10)

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

        XCTAssertEqual(posts.count, 15)

        let idSet = Set(posts.map { $0.id })

        XCTAssertEqual(idSet.count, 15)
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
