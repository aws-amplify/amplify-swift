//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class GraphQLDeleteMutationTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no required associations
    ///   - the mutation is of type `.delete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `deletePost`
    ///     - it contains an `input` of type `ID!`
    ///     - it has a list of fields with no nested models
    func testDeleteGraphQLMutationFromSimpleModel() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(id: post.id))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation DeletePost($input: DeletePostInput!) {
          deletePost(input: $input) {
            id
            content
            createdAt
            draft
            rating
            status
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "deletePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "deletePost")
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssert(variables["input"] != nil)
        guard let input = variables["input"] as? [String: String] else {
            XCTFail("Could not get object at `input`")
            return
        }
        XCTAssertEqual(input["id"], post.id)
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no required associations
    ///   - the mutation is of type `.delete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `deletePost`
    ///     - it contains an `input` of type `ID!`
    ///     - it has a list of fields with no nested models
    func testDeleteGraphQLMutationFromSimpleModelWithVersion() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(id: post.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: 5, graphQLType: .mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation DeletePost($input: DeletePostInput!) {
          deletePost(input: $input) {
            id
            content
            createdAt
            draft
            rating
            status
            title
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.name, "deletePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "deletePost")
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssert(variables["input"] != nil)
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("Could not get object at `input`")
            return
        }
        XCTAssert(input["id"] as? String == post.id)
        XCTAssert(input["_version"] as? Int == 5)
    }

    func testDeleteGraphQLMutationModelWithReadOnlyFields() {
        let recordCover = RecordCover(artist: "artist")
        let record = Record(name: "name", description: "description", cover: recordCover)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Record.schema,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelDecorator(model: record))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation DeleteRecord($input: DeleteRecordInput!) {
          deleteRecord(input: $input) {
            id
            coverId
            createdAt
            description
            name
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.name, "deleteRecord")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? GraphQLInput else {
            XCTFail("Variables should contain a valid input")
            return
        }
        XCTAssertEqual(input["id"] as? String, record.id)
        XCTAssertEqual(input["name"] as? String, record.name)
        XCTAssertEqual(input["description"] as? String, record.description)
        XCTAssertNil(input["createdAt"] as? Temporal.DateTime)
        XCTAssertNil(input["updatedAt"] as? Temporal.DateTime)
        XCTAssertNil(input["cover"] as? RecordCover)
    }
}
