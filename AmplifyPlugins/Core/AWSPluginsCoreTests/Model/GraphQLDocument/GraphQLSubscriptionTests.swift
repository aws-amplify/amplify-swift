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

// swiftlint:disable type_body_length
class GraphQLSubscriptionTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    // MARK: - Subscriptions

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded associations
    ///   - the subscription is of type `.onCreate`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnCreateGraphQLSubscriptionFromSimpleModel() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreatePost {
          onCreatePost {
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
        XCTAssertEqual(document.name, "onCreatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNil(document.variables)
    }

    func testOnCreateGraphQLSubscriptionFromSimpleModelWithSyncEnabled() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreatePost {
          onCreatePost {
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
        XCTAssertEqual(document.name, "onCreatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNil(document.variables)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Comment`
    ///   - the model has required associations
    ///   - the subscription is of type `.onCreate`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnCreateGraphQLSubscriptionFromModelWithAssociation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Comment.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateComment {
          onCreateComment {
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
        XCTAssertEqual(document.name, "onCreateComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNil(document.variables)
    }

    func testOnCreateGraphQLSubscriptionFromModelWithAssociationWithSyncEnabled() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Comment.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateComment {
          onCreateComment {
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
        XCTAssertEqual(document.name, "onCreateComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNil(document.variables)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded associations
    ///   - the subscription is of type `.onUpdate`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnUpdateGraphQLSubscriptionFromSimpleModel() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        let document = documentBuilder.build()

        let expectedQueryDocument = """
        subscription OnUpdatePost {
          onUpdatePost {
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
        XCTAssertEqual(document.name, "onUpdatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNil(document.variables)
    }

    func testOnUpdateGraphQLSubscriptionFromSimpleModelWithSyncEnabled() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnUpdatePost {
          onUpdatePost {
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
        XCTAssertEqual(document.name, "onUpdatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNil(document.variables)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded associations
    ///   - the subscription is of type `.onDelete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnDeleteGraphQLSubscriptionFromSimpleModel() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnDeletePost {
          onDeletePost {
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
        XCTAssertEqual(document.name, "onDeletePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNil(document.variables)
    }

    func testOnDeleteGraphQLSubscriptionFromSimpleModelWithSyncEnabled() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnDeletePost {
          onDeletePost {
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
        XCTAssertEqual(document.name, "onDeletePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNil(document.variables)
    }
}
