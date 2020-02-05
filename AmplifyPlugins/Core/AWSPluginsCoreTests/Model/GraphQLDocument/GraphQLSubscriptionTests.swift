//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

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
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveDecorator(type: .onCreate))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreatePost {
          onCreatePost {
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
        XCTAssertEqual(document.name, "onCreatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.variables.count, 0)
    }

    func testOnCreateGraphQLSubscriptionFromSimpleModelWithSyncEnabled() {
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreatePost {
          onCreatePost {
            id
            content
            createdAt
            draft
            rating
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
        XCTAssertEqual(document.variables.count, 0)
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
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelType: Comment.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveDecorator(type: .onCreate))
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
        XCTAssertEqual(document.variables.count, 0)
    }

    func testOnCreateGraphQLSubscriptionFromModelWithAssociationWithSyncEnabled() {
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelType: Comment.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
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
        XCTAssertEqual(document.variables.count, 0)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded associations
    ///   - the subscription is of type `.onUpdate`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnUpdateGraphQLSubscriptionFromSimpleModel() {
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveDecorator(type: .onUpdate))
        let document = documentBuilder.build()

        let expectedQueryDocument = """
        subscription OnUpdatePost {
          onUpdatePost {
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
        XCTAssertEqual(document.name, "onUpdatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.variables.count, 0)
    }

    func testOnUpdateGraphQLSubscriptionFromSimpleModelWithSyncEnabled() {
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveDecorator(type: .onUpdate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnUpdatePost {
          onUpdatePost {
            id
            content
            createdAt
            draft
            rating
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
        XCTAssertEqual(document.variables.count, 0)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded associations
    ///   - the subscription is of type `.onDelete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnDeleteGraphQLSubscriptionFromSimpleModel() {
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveDecorator(type: .onDelete))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnDeletePost {
          onDeletePost {
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
        XCTAssertEqual(document.name, "onDeletePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.variables.count, 0)
    }

    func testOnDeleteGraphQLSubscriptionFromSimpleModelWithSyncEnabled() {
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveDecorator(type: .onDelete))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnDeletePost {
          onDeletePost {
            id
            content
            createdAt
            draft
            rating
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
        XCTAssertEqual(document.variables.count, 0)
    }
}
