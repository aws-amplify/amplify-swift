//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class SortedListTests: XCTestCase {

    func testSortedListSetAndReset() {
        let posts = [createPost(id: "1", rating: 5.0),
                     createPost(id: "2", rating: 5.0),
                     createPost(id: "3", rating: 5.0),
                     createPost(id: "4", rating: 5.0)]

        let list = SortedList<Post>(sortInput: [QuerySortBy.ascending(Post.keys.rating).sortDescriptor],
                                    modelSchema: Post.schema)
        list.set(sortedModels: posts)

        assertPosts(list.sortedModels, expectedIds: ["1", "2", "3", "4"])
        XCTAssertEqual(list.modelIds.count, 4)

        list.reset()
        XCTAssertTrue(list.sortedModels.isEmpty)
        XCTAssertTrue(list.modelIds.isEmpty)
    }

    func testSortedListSingleSort() {
        let posts = [createPost(id: "1"),
                     createPost(id: "2"),
                     createPost(id: "5"),
                     createPost(id: "6")]
        let sortInput = [QuerySortBy.ascending(Post.keys.id).sortDescriptor]
        let list = SortedList<Post>(sortInput: sortInput,
                                    modelSchema: Post.schema)

        list.set(sortedModels: posts)

        // insert into the middle of the sorted list
        list.add(model: createPost(id: "3"), sortInputs: sortInput)
        assertPosts(list.sortedModels, expectedIds: ["1", "2", "3", "5", "6"])
        XCTAssertEqual(list.modelIds.count, 5)

        // insert into the middle
        list.add(model: createPost(id: "4"), sortInputs: sortInput)
        assertPosts(list.sortedModels, expectedIds: ["1", "2", "3", "4", "5", "6"])
        XCTAssertEqual(list.modelIds.count, 6)

        // insert at the beginning
        list.add(model: createPost(id: "0"), sortInputs: sortInput)
        assertPosts(list.sortedModels, expectedIds: ["0", "1", "2", "3", "4", "5", "6"])

        // insert at the end
        list.add(model: createPost(id: "7"), sortInputs: sortInput)
        assertPosts(list.sortedModels, expectedIds: ["0", "1", "2", "3", "4", "5", "6", "7"])

        // insert into where the equal model is found, at the beginning
        list.add(model: createPost(id: "0", draft: true), sortInputs: sortInput)
        XCTAssertEqual(list.sortedModels[0].id, "0")
        XCTAssertEqual(list.sortedModels[0].draft, true)
        XCTAssertEqual(list.sortedModels[1].id, "0")
        XCTAssertEqual(list.sortedModels[1].draft, false)
        assertPosts(list.sortedModels, expectedIds: ["0", "0", "1", "2", "3", "4", "5", "6", "7"])

        // insert into where the equal model is found, at the end
        list.add(model: createPost(id: "7", draft: true), sortInputs: sortInput)
        assertPosts(list.sortedModels, expectedIds: ["0", "0", "1", "2", "3", "4", "5", "6", "7", "7"])
        XCTAssertEqual(list.sortedModels[8].id, "7")
        XCTAssertEqual(list.sortedModels[8].draft, true)
        XCTAssertEqual(list.sortedModels[9].id, "7")
        XCTAssertEqual(list.sortedModels[9].draft, false)
    }

    func testSortedListMultipleSort() {
        let posts = [createPost(id: "1", rating: 5.0),
                     createPost(id: "2", rating: 10.0),
                     createPost(id: "6", rating: 10.0),
                     createPost(id: "5", rating: 20.0)]
        let sortInput = [QuerySortBy.ascending(Post.keys.rating).sortDescriptor,
                         QuerySortBy.ascending(Post.keys.id).sortDescriptor]
        let list = SortedList<Post>(sortInput: sortInput,
                                    modelSchema: Post.schema)
        list.set(sortedModels: posts)

        // After id: "1", rating: 5.0
        list.add(model: createPost(id: "1", rating: 10.0), sortInputs: sortInput)
        assertPost(list.sortedModels[0], id: "1", rating: 5.0)
        assertPost(list.sortedModels[1], id: "1", rating: 10.0)
        assertPost(list.sortedModels[2], id: "2", rating: 10.0)
        assertPost(list.sortedModels[3], id: "6", rating: 10.0)
        assertPost(list.sortedModels[4], id: "5", rating: 20.0)

        // Before id: "1", rating: 5.0
        list.add(model: createPost(id: "1", rating: 1.0), sortInputs: sortInput)
        assertPost(list.sortedModels[0], id: "1", rating: 1.0)
        assertPost(list.sortedModels[1], id: "1", rating: 5.0)
        assertPost(list.sortedModels[2], id: "1", rating: 10.0)
        assertPost(list.sortedModels[3], id: "2", rating: 10.0)
        assertPost(list.sortedModels[4], id: "6", rating: 10.0)
        assertPost(list.sortedModels[5], id: "5", rating: 20.0)

        // Since it is sorted by rating then id, the highest rating with lowest id is still places at the end.
        list.add(model: createPost(id: "1", rating: 30.0), sortInputs: sortInput)
        assertPost(list.sortedModels[0], id: "1", rating: 1.0)
        assertPost(list.sortedModels[1], id: "1", rating: 5.0)
        assertPost(list.sortedModels[2], id: "1", rating: 10.0)
        assertPost(list.sortedModels[3], id: "2", rating: 10.0)
        assertPost(list.sortedModels[4], id: "6", rating: 10.0)
        assertPost(list.sortedModels[5], id: "5", rating: 20.0)
        assertPost(list.sortedModels[6], id: "1", rating: 30.0)
    }

    func testSortedListAllEqual() {
        let posts = [createPost(id: "1", rating: 5.0),
                     createPost(id: "2", rating: 5.0),
                     createPost(id: "3", rating: 5.0),
                     createPost(id: "4", rating: 5.0)]

        let sortInput = [QuerySortBy.ascending(Post.keys.rating).sortDescriptor]
        let list = SortedList<Post>(sortInput: [QuerySortBy.ascending(Post.keys.rating).sortDescriptor],
                                    modelSchema: Post.schema)
        list.set(sortedModels: posts)

        // Since this is a binary search, the first index where the predicate returns `nil` is the middle index
        list.add(model: createPost(id: "5", rating: 5.0), sortInputs: sortInput)
        assertPosts(list.sortedModels, expectedIds: ["1", "2", "5", "3", "4"])
    }

    // MARK: - Helpers

    func assertPosts(_ posts: [Post], expectedIds: [String]) {
        for (index, id) in expectedIds.enumerated() {
            let post = posts[index]
            XCTAssertEqual(post.id, id)
        }
    }

    func assertPost(_ post: Post, id: String, rating: Double) {
        XCTAssertEqual(post.id, id)
        XCTAssertEqual(post.rating, rating)
    }

    func createPost(id: String = UUID().uuidString,
                    draft: Bool = false,
                    rating: Double = 1.0,
                    createdAt: Temporal.DateTime = .now(),
                    status: PostStatus? = .draft) -> Post {
        Post(id: id,
             title: "A",
             content: "content",
             createdAt: createdAt,
             updatedAt: .now(),
             draft: draft,
             rating: rating,
             status: status,
             comments: nil)
    }
}
