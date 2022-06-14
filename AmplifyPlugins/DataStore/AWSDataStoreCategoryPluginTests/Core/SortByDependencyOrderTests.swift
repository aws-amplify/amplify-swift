//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class SortByDependencyOrderTests: XCTestCase {

    var modelList = [Model.Type]()

    override func setUp() async throws {
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

    /// - Given: a list of `ModelSchema` types
    /// - When:
    ///   - the list is not in the correct order: `[Comment, Post]`
    /// - Then:
    ///   - check if `sortByDependencyOrder()` sorts the list to `[Post, Comment]`
    func testModelDependencySortOrder() {
        let modelSchemas: [ModelSchema] = [Comment.schema, Post.schema]

        let sorted = modelSchemas.sortByDependencyOrder()

        let sortedModelNames = sorted.map { $0.name }
        XCTAssertEqual(sortedModelNames, ["Post", "Comment"])
    }

    /// - Given: A list of `ModelSchema` types
    /// - When:
    ///    - not all models are connected: `[Comment, MockSynced, Post]`
    /// - Then:
    ///    - the sorted list should include unconnected models at the end
    func testModelDependencySortForUnconnectedModels() {
        let modelSchemas: [ModelSchema] = [Comment.schema, MockSynced.schema, Post.schema]

        let sorted = modelSchemas.sortByDependencyOrder()

        let sortedModelNames = sorted.map { $0.name }
        XCTAssertEqual(sortedModelNames, ["Post", "Comment", "MockSynced"])
    }

    /// - Given: a list of `ModelSchema` types
    /// - When:
    ///    - the list includes members of two diffrently-connected dependency graphs
    /// - Then:
    ///    - the sorted list should include both graphs in order
    func testMultipleConnectedModels() {
        let modelSchemas: [ModelSchema] = [Comment.schema, UserProfile.schema, Post.schema, UserAccount.schema]

        let sorted = modelSchemas.sortByDependencyOrder()

        let sortedModelNames = sorted.map { $0.name }
        XCTAssertEqual(sortedModelNames, ["Post", "Comment", "UserAccount", "UserProfile"])
    }

    /// - Given: a list of `ModelSchema` types
    /// - When:
    ///    - the list includes a many-to-many connection
    /// - Then:
    ///    - the sorted list should include both leaf models before the join model
    func testManyToManyConnections() {
        let modelSchemas: [ModelSchema] = [Author.schema, BookAuthor.schema, Book.schema]

        let sorted = modelSchemas.sortByDependencyOrder()

        let sortedModelNames = sorted.map { $0.name }
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
            let modelSchemas = modelList.shuffled().map { (modelType) -> ModelSchema in
                modelType.schema
            }
            let sorted = modelSchemas.sortByDependencyOrder()
            let sortedModelNames = sorted.map { $0.name }
            XCTAssertEqual(sortedModelNames, expectedModelNames)
        }
    }
}
