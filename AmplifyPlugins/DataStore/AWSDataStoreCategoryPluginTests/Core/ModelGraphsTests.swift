//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPluginsCore
@testable import AmplifyTestCommon

@testable import AWSDataStoreCategoryPlugin

class ModelGraphsTests: XCTestCase {

    var modelList = [Model.Type]()
    var expectedRootNames = Set<String>()

    override func setUp() {
        ModelRegistry.register(modelType: Author.self)
        modelList.append(Author.self)
        expectedRootNames.insert(Author.modelName)

        ModelRegistry.register(modelType: Book.self)
        modelList.append(Book.self)
        expectedRootNames.insert(Book.modelName)

        ModelRegistry.register(modelType: BookAuthor.self)
        modelList.append(BookAuthor.self)

        ModelRegistry.register(modelType: UserAccount.self)
        modelList.append(UserAccount.self)
        expectedRootNames.insert(UserAccount.modelName)

        ModelRegistry.register(modelType: UserProfile.self)
        modelList.append(UserProfile.self)

        ModelRegistry.register(modelType: Post.self)
        modelList.append(Post.self)
        expectedRootNames.insert(Post.modelName)

        ModelRegistry.register(modelType: Comment.self)
        modelList.append(Comment.self)

        ModelRegistry.register(modelType: MockUnsynced.self)
        modelList.append(MockUnsynced.self)
        expectedRootNames.insert(MockUnsynced.modelName)
    }

    func testConstructor() {
        let graph = ModelGraphs(models: modelList)
        XCTAssertNotNil(graph.nodes)
    }

    func testConnectsOneToMany() {
        let graph = ModelGraphs(models: modelList)
        XCTAssertEqual(graph.nodes["Comment"]?.upstream.first?.displayName, "Post")
        XCTAssertEqual(graph.nodes["Post"]?.downstream.first?.displayName, "Comment")
    }

    func testRoots() {
        let graph = ModelGraphs(models: modelList)
        let rootNames = graph.roots.map { $0.displayName }
        let rootNamesSet = Set(rootNames)
        XCTAssertEqual(rootNamesSet, expectedRootNames)
    }
}
