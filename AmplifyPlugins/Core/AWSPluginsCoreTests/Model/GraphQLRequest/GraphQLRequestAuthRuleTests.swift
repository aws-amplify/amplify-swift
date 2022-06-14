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

class GraphQLRequestAuthRuleTests: XCTestCase {

    override func setUp() async throws {
        ModelRegistry.register(modelType: Article.self)
    }

    override func tearDown() async throws {
        ModelRegistry.reset()
    }

    func testQueryGraphQLRequest() throws {
        let article = Article(content: "content", createdAt: .now(), owner: nil, authorNotes: nil)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: article.modelName, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: article.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let documentStringValue = """
        query GetArticle($id: ID!) {
          getArticle(id: $id) {
            id
            authorNotes
            content
            createdAt
            owner
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """

        let request = GraphQLRequest<MutationSyncResult?>.query(modelName: article.modelName, byId: article.id)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult?.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, article.id)
    }

    func testCreateMutationGraphQLRequest() throws {
        let article = Article(content: "content", createdAt: .now(), owner: nil, authorNotes: nil)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: article.modelName, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: article))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation CreateArticle($input: CreateArticleInput!) {
          createArticle(input: $input) {
            id
            authorNotes
            content
            createdAt
            owner
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: article, modelSchema: article.schema)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables != nil)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssert(input["content"] as? String == article.content)
        XCTAssertFalse(input.keys.contains("owner"))
    }

    func testUpdateMutationGraphQLRequest() throws {
        let article = Article(content: "content", createdAt: .now(), owner: nil, authorNotes: nil)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: article.modelName, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: article))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation UpdateArticle($input: UpdateArticleInput!) {
          updateArticle(input: $input) {
            id
            authorNotes
            content
            createdAt
            owner
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: article, modelSchema: article.schema)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssert(input["content"] as? String == article.content)
        XCTAssertFalse(input.keys.contains("owner"))
    }

    func testDeleteMutationGraphQLRequest() throws {
        let article = Article(content: "content", createdAt: .now(), owner: nil, authorNotes: nil)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: article.modelName, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(id: article.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation DeleteArticle($input: DeleteArticleInput!) {
          deleteArticle(input: $input) {
            id
            authorNotes
            content
            createdAt
            owner
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """

        let request = GraphQLRequest<MutationSyncResult>.deleteMutation(of: article, modelSchema: article.schema)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input["id"] as? String, article.id)
        XCTAssertFalse(input.keys.contains("owner"))
        XCTAssertFalse(input.keys.contains("authorNotes"))
    }

    func testOnCreateSubscriptionGraphQLRequest() throws {
        let modelType = Article.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let documentStringValue = """
        subscription OnCreateArticle($owner: String!) {
          onCreateArticle(owner: $owner) {
            id
            authorNotes
            content
            createdAt
            owner
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onCreate,
                                                                      claims: claims)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["owner"] as? String else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input, "user1")
    }

    func testOnUpdateSubscriptionGraphQLRequest() throws {
        let modelType = Article.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onUpdate, claims)))
        let document = documentBuilder.build()
        let documentStringValue = """
        subscription OnUpdateArticle($owner: String!) {
          onUpdateArticle(owner: $owner) {
            id
            authorNotes
            content
            createdAt
            owner
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onUpdate,
                                                                      claims: claims)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String, "user1")
    }

    func testOnDeleteSubscriptionGraphQLRequest() throws {
        let modelType = Article.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onDelete, claims)))
        let document = documentBuilder.build()
        let documentStringValue = """
        subscription OnDeleteArticle($owner: String!) {
          onDeleteArticle(owner: $owner) {
            id
            authorNotes
            content
            createdAt
            owner
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onDelete,
                                                                      claims: claims)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String, "user1")
    }

    func testSyncQueryGraphQLRequest() throws {
        let modelType = Article.self as Model.Type
        let nextToken = "nextToken"
        let limit = 100
        let lastSync = 123
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: PaginationDecorator(limit: limit, nextToken: nextToken))
        documentBuilder.add(decorator: ConflictResolutionDecorator(lastSync: lastSync))
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let documentStringValue = """
        query SyncArticles($lastSync: AWSTimestamp, $limit: Int, $nextToken: String) {
          syncArticles(lastSync: $lastSync, limit: $limit, nextToken: $nextToken) {
            items {
              id
              authorNotes
              content
              createdAt
              owner
              __typename
              _version
              _deleted
              _lastChangedAt
            }
            nextToken
            startedAt
          }
        }
        """

        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelSchema: modelType.schema,
                                                                limit: limit,
                                                                nextToken: nextToken,
                                                                lastSync: lastSync)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == SyncQueryResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["limit"])
        XCTAssertEqual(variables["limit"] as? Int, limit)
        XCTAssertNotNil(variables["nextToken"])
        XCTAssertEqual(variables["nextToken"] as? String, nextToken)
        XCTAssertNotNil(variables["lastSync"])
        XCTAssertEqual(variables["lastSync"] as? Int, lastSync)
    }
}
