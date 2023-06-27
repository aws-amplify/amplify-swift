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

class GraphQLUpdateMutationTests: XCTestCase {

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
    ///   - the mutation is of type `.update`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `updatePost`
    ///     - it contains an `input` of type `UpdatePostInput`
    ///     - it has a list of fields with no nested models
    func testUpdateGraphQLMutationFromSimpleModel() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation UpdatePost($input: UpdatePostInput!) {
          updatePost(input: $input) {
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
        XCTAssertEqual(document.name, "updatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "updatePost")
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["input"])
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssert(input["title"] as? String == post.title)
        XCTAssert(input["content"] as? String == post.content)
        XCTAssertFalse(input.keys.contains("comments"))
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no required associations
    ///   - the mutation is of type `.update`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `updatePost`
    ///     - it contains an `input` of type `UpdatePostInput`
    ///     - it has a list of fields with no nested models
    func testUpdateGraphQLMutationFromSimpleModelWithVersion() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: 5, graphQLType: .mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation UpdatePost($input: UpdatePostInput!) {
          updatePost(input: $input) {
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
        XCTAssertEqual(document.name, "updatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "updatePost")
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["input"])
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssert(input["title"] as? String == post.title)
        XCTAssert(input["content"] as? String == post.content)
        XCTAssert(input["_version"] as? Int == 5)
        XCTAssertFalse(input.keys.contains("comments"))
    }

    func testUpdateGraphQLMutationModelWithReadOnlyFields() {
        let recordCover = RecordCover(artist: "artist")
        let record = Record(name: "name", description: "description", cover: recordCover)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Record.schema,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: record))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation UpdateRecord($input: UpdateRecordInput!) {
          updateRecord(input: $input) {
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
        XCTAssertEqual(document.name, "updateRecord")
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
