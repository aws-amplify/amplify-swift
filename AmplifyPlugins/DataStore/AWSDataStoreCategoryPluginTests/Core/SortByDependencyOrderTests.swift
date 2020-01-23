//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class SortByDependencyOrderTests: XCTestCase {

    var modelList = [Model.Type]()

    override func setUp() {
        modelList = [
            Author.self,
            MockUnsynced.self,
            BookAuthor.self,
            Book.self,
            UserProfile.self,
            UserAccount.self,
            Comment.self,
            Post.self
        ]
        modelList.forEach { ModelRegistry.register(modelType: $0) }
    }

    /// - Given: a list of `Model` types
    /// - When:
    ///   - the list is not in the correct order: `[Comment, Post]`
    /// - Then:
    ///   - check if `sortByDependencyOrder()` sorts the list to `[Post, Comment]`
    func testModelDependencySortOrder() {
        let models: [Model.Type] = [Comment.self, Post.self]

        let sorted = models.sortByDependencyOrder()

        let sortedModelNames = sorted.map { $0.modelName }
        XCTAssertEqual(sortedModelNames, ["Post", "Comment"])
    }

    /// - Given: A list of `Model` types
    /// - When:
    ///    - not all models are connected: `[Comment, MockSynced, Post]`
    /// - Then:
    ///    - the sorted list should include unconnected models at the end
    func testModelDependencySortForUnconnectedModels() {
        let models: [Model.Type] = [Comment.self, MockSynced.self, Post.self]

        let sorted = models.sortByDependencyOrder()

        let sortedModelNames = sorted.map { $0.modelName }
        XCTAssertEqual(sortedModelNames, ["Post", "Comment", "MockSynced"])
    }

    /// - Given: a list of Model types
    /// - When:
    ///    - the list includes members of two diffrently-connected dependency graphs
    /// - Then:
    ///    - the sorted list should include both graphs in order
    func testMultipleConnectedModels() {
        let models: [Model.Type] = [Comment.self, UserProfile.self, Post.self, UserAccount.self]

        let sorted = models.sortByDependencyOrder()

        let sortedModelNames = sorted.map { $0.modelName }
        XCTAssertEqual(sortedModelNames, ["Post", "Comment", "UserAccount", "UserProfile"])
    }

    /// - Given: a list of Model types
    /// - When:
    ///    - the list includes a many-to-many connection
    /// - Then:
    ///    - the sorted list should include both leaf models before the join model
    func testManyToManyConnections() {
        let models: [Model.Type] = [Author.self, BookAuthor.self, Book.self]

        let sorted = models.sortByDependencyOrder()

        let sortedModelNames = sorted.map { $0.modelName }
        XCTAssertEqual(sortedModelNames, ["Author", "Book", "BookAuthor"])
    }

    /// - Given: a list of Model types
    /// - When:
    ///   - the list is randomly shuffled
    /// - Then:
    ///   - the ordered list is deterministically sorted, although not necessarily predictable
    func testSortsDeterministically() {
        let expectedModelNames = ["Author", "Book", "BookAuthor", "Post", "Comment", "MockUnsynced",
                                  "UserAccount", "UserProfile"]

        for _ in 0 ..< 10 {
            let models = modelList.shuffled()
            let sorted = models.sortByDependencyOrder()
            let sortedModelNames = sorted.map { $0.modelName }
            XCTAssertEqual(sortedModelNames, expectedModelNames)
        }
    }
}
