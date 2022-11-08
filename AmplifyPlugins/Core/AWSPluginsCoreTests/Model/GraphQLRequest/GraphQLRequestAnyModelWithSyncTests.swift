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
class GraphQLRequestAnyModelWithSyncTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)

    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testQueryGraphQLRequest() throws {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: post.modelName, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: post.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
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

        let request = GraphQLRequest<MutationSyncResult?>.query(modelName: post.modelName, byId: post.id)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult?.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, post.id)
    }

    func testCreateMutationGraphQLRequest() throws {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: post.modelName,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: post, mutationType: .create))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation CreatePost($input: CreatePostInput!) {
          createPost(input: $input) {
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
        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: post, modelSchema: post.schema)

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
        XCTAssert(input["title"] as? String == post.title)
        XCTAssert(input["content"] as? String == post.content)
    }

    func testUpdateMutationGraphQLRequest() throws {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: post.modelName,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: post, mutationType: .update))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
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
        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: post, modelSchema: post.schema)

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
        XCTAssert(input["title"] as? String == post.title)
        XCTAssert(input["content"] as? String == post.content)
    }

    func testDeleteMutationGraphQLRequest() throws {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: post.modelName,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(id: post.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
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

        let request = GraphQLRequest<MutationSyncResult>.deleteMutation(of: post, modelSchema: post.schema)

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
        XCTAssertEqual(input["id"] as? String, post.id)
    }

    func testCreateSubscriptionGraphQLRequest() throws {
        let modelType = Post.self as Model.Type
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
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
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onCreate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssertNil(request.variables)
    }

    func testSyncQueryGraphQLRequest() throws {
        let modelType = Post.self as Model.Type
        let nextToken = "nextToken"
        let limit = 100
        let lastSync = 123
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: PaginationDecorator(limit: limit, nextToken: nextToken))
        documentBuilder.add(decorator: ConflictResolutionDecorator(lastSync: lastSync))
        let document = documentBuilder.build()
        let documentStringValue = """
        query SyncPosts($lastSync: AWSTimestamp, $limit: Int, $nextToken: String) {
          syncPosts(lastSync: $lastSync, limit: $limit, nextToken: $nextToken) {
            items {
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

    func testOptimizedSyncQueryGraphQLRequestWithFilter() {
        let modelType = Post.self as Model.Type
        let nextToken = "nextToken"
        let limit = 100
        let lastSync = 123
        let postId = "123"
        let predicate = Post.CodingKeys.id.eq(postId)
        let request = GraphQLRequest<SyncQueryResult>.syncQuery(
            modelSchema: modelType.schema,
            where: predicate,
            limit: limit,
            nextToken: nextToken,
            lastSync: lastSync)

        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard variables["filter"] != nil, let filter = variables["filter"] as? [String: Any] else {
            XCTFail("The request doesn't contain a filter")
            return
        }

        XCTAssertEqual(variables["limit"] as? Int, limit)
        XCTAssertEqual(variables["nextToken"] as? String, nextToken)
        XCTAssertNotNil(filter)
        XCTAssertNotNil(filter["and"])
    }

    func testSyncQueryGraphQLRequestWithPredicateGroupFilter() {
        let modelType = Post.self as Model.Type
        let nextToken = "nextToken"
        let limit = 100
        let lastSync = 123
        let postId = "123"
        let altPostId = "456"
        let predicate = Post.CodingKeys.id.eq(postId) || Post.CodingKeys.id.eq(altPostId)
        let request = GraphQLRequest<SyncQueryResult>.syncQuery(
            modelSchema: modelType.schema,
            where: predicate,
            limit: limit,
            nextToken: nextToken,
            lastSync: lastSync)

        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard variables["filter"] != nil, let filter = variables["filter"] as? [String: Any] else {
            XCTFail("The request doesn't contain a filter")
            return
        }

        XCTAssertEqual(variables["limit"] as? Int, limit)
        XCTAssertEqual(variables["nextToken"] as? String, nextToken)
        XCTAssertNotNil(filter)
        XCTAssertNotNil(filter["or"])
    }

    func testUpdateMutationWithEmptyFilter() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        let documentStringValue = """
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

        let request = GraphQLRequest<Post>.updateMutation(of: post, where: [:])
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
        XCTAssert(input["title"] as? String == post.title)
        XCTAssert(input["content"] as? String == post.content)
    }

    func testUpdateMutationWithFilter() {
        let post = Post(title: "myTitle", content: "content", createdAt: .now())
        let documentStringValue = """
        mutation UpdatePost($condition: ModelPostConditionInput, $input: UpdatePostInput!) {
          updatePost(condition: $condition, input: $input) {
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
        let filter: [String: Any] = ["title": ["eq": "myTitle"]]
        let request = GraphQLRequest<Post>.updateMutation(of: post, where: filter)
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
        XCTAssert(input["title"] as? String == post.title)
        XCTAssert(input["content"] as? String == post.content)

        guard let condition = variables["condition"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid condition")
            return
        }
        guard let conditionValue = condition["title"] as? [String: String] else {
            XCTFail("Failed to get 'title' from the condition")
            return
        }
        XCTAssertEqual(conditionValue["eq"], "myTitle")
    }
}
