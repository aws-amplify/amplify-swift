//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class GraphQLDocumentTests: XCTestCase {

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testSelectionSetFieldsForNotSyncableModels() {
        ModelRegistry.register(modelType: MockUnsynced.self)

        let document = GraphQLGetQuery(from: MockUnsynced.self, id: "id")
        let expectedSelectionSet = ["id",
                                    "__typename"]

        XCTAssertEqual(document.selectionSetFields, expectedSelectionSet)
    }

    func testSelectionSetFieldsForSyncableModels() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)

        let document = GraphQLGetQuery(from: Post.self, id: "id")
        let expectedSelectionSet = ["id",
                                    "content",
                                    "createdAt",
                                    "draft",
                                    "rating",
                                    "title",
                                    "updatedAt",
                                    "__typename",
                                    "_version",
                                    "_deleted",
                                    "_lastChangedAt"]

        XCTAssertEqual(document.selectionSetFields, expectedSelectionSet)
    }
}
