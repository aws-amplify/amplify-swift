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

class GraphQLGetQueryTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no eager loaded connections
    ///   - the query is of type `.get`
    /// - Then:
    ///   - check if the generated GraphQL document is valid query:
    ///     - it contains an `id` argument of type `ID!`
    ///     - it is named `getPost`
    ///     - it has a list of fields with no nested models
    ///     - it has variables containing `id`
    func testGetGraphQLQueryFromSimpleModel() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetPost($id: ID!) {
          getPost(id: $id) {
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
        XCTAssertEqual(document.name, "getPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, "id")
    }

    func testGetGraphQLQueryFromSimpleModelWithSyncEnabled() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetPost($id: ID!) {
          getPost(id: $id) {
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
        XCTAssertEqual(document.name, "getPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, "id")
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Comment`
    ///   - the model has eager loaded associations
    ///   - the query is of type `.get`
    ///   - primaryKeysOnly true in selection set
    /// - Then:
    ///   - check if the generated GraphQL document is valid query:
    ///     - it contains an `id` argument of type `ID!`
    ///     - it is named `getComment`
    ///     - it has a list of fields with a nested `post`
    func testGetGraphQLQueryFromModelWithAssociationPrimaryKeysOnly() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Comment.schema, operationType: .query, primaryKeysOnly: true)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetComment($id: ID!) {
          getComment(id: $id) {
            id
            content
            createdAt
            post {
              id
              __typename
            }
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "getComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, "id")
    }
    
    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Comment`
    ///   - the model has eager loaded associations
    ///   - the query is of type `.get`
    ///   - primaryKeysOnly false in selection set
    /// - Then:
    ///   - check if the generated GraphQL document is valid query:
    ///     - it contains an `id` argument of type `ID!`
    ///     - it is named `getComment`
    ///     - it has a list of fields with a nested `post`
    func testGetGraphQLQueryFromModelWithAssociation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Comment.schema, operationType: .query, primaryKeysOnly: false)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetComment($id: ID!) {
          getComment(id: $id) {
            id
            content
            createdAt
            post {
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
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "getComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, "id")
    }

    func testGetGraphQLQueryFromModelWithAssociationAndSyncEnabledPrimaryKeysOnly() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Comment.schema, operationType: .query, primaryKeysOnly: true)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetComment($id: ID!) {
          getComment(id: $id) {
            id
            content
            createdAt
            post {
              id
              __typename
              _deleted
            }
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.name, "getComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, "id")
    }
    
    func testGetGraphQLQueryFromModelWithAssociationAndSyncEnabled() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Comment.schema, operationType: .query, primaryKeysOnly: false)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .query, primaryKeysOnly: false))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetComment($id: ID!) {
          getComment(id: $id) {
            id
            content
            createdAt
            post {
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
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.name, "getComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, "id")
    }

    /// - Given: a `model` type
    /// - When:
    ///   - the model has read-only fields
    /// - Then:
    ///   - the generated query contains read-only fields if requested in selection set
    ///
    func testGetGraphQLQueryModelWithReadOnlyFields() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Record.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetRecord($id: ID!) {
          getRecord(id: $id) {
            id
            coverId
            createdAt
            description
            name
            updatedAt
            cover
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "getRecord")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, "id")
        XCTAssertNil(variables["createdAt"] as? Temporal.DateTime)
        XCTAssertNil(variables["updatedAt"] as? Temporal.DateTime)

        guard let selectionSet = document.selectionSet else {
            XCTFail("The document doesn't contain a selection set")
            return
        }
        let fields = selectionSet.children.map { $0.value.name! }
        XCTAssertTrue(fields.contains("createdAt"))
        XCTAssertTrue(fields.contains("updatedAt"))
    }
}
