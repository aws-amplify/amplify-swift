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

    override func setUp() {
         ModelRegistry.register(modelType: Comment.self)
         ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testDefaultGraphQLDocument() {
        let document = MockGraphQLDocument(documentType: .mutation,
                                           name: "name",
                                           modelType: Post.self)

        let expectedQueryDocument = """
        mutation Name {
          name {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """

        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
        XCTAssertEqual(document.documentType, .mutation)
        XCTAssertEqual(document.name, "name")
        XCTAssertNil(document.inputTypes)
        XCTAssertNil(document.inputParameters)
    }

    func testDefaultGraphQLDocumentWithInput() {
        let document = MockGraphQLDocument(documentType: .mutation,
                                           name: "name",
                                           inputTypes: "$input: InputType, $id: ID!",
                                           inputParameters: "input: $input, id: $id!",
                                           modelType: Post.self)

        let expectedQueryDocument = """
        mutation Name($input: InputType, $id: ID!) {
          name(input: $input, id: $id!) {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """

        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
        XCTAssertEqual(document.documentType, .mutation)
        XCTAssertEqual(document.name, "name")
        XCTAssertEqual(document.inputTypes, "$input: InputType, $id: ID!")
        XCTAssertEqual(document.inputParameters, "input: $input, id: $id!")
    }
}
