//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class GraphQLDocumentTests: XCTestCase {

    func testSelectionSetFieldsForNotSyncableModels() {
        ModelRegistry.register(modelType: CommentNoSync.self)
        ModelRegistry.register(modelType: PostNoSync.self)

        let document = GraphQLGetQuery(from: Post.self, id: "id")
        let expected = ["id",
                        "content",
                        "createdAt",
                        "draft",
                        "rating",
                        "title",
                        "updatedAt",
                        "__typename"]

        XCTAssertEqual(document.selectionSetFields, expected)
        ModelRegistry.reset()
    }

    func testSelectionSetFieldsForSyncableModels() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)

        let document = GraphQLGetQuery(from: Post.self, id: "id")
        let expected = ["id",
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

        XCTAssertEqual(document.selectionSetFields, expected)
        ModelRegistry.reset()
    }

}
