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

class GraphQLRequestAuthRuleTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Blog.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testQueryGraphQLRequest() throws {
        let blog = Blog(content: "content", createdAt: .now(), owner: nil, authorNotes: nil)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: blog.modelName, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: blog.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let documentStringValue = """
        query GetBlog($id: ID!) {
          getBlog(id: $id) {
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

        let request = GraphQLRequest<MutationSyncResult?>.query(modelName: blog.modelName, byId: blog.id)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult?.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["id"] as? String, blog.id)
    }

    func testCreateMutationGraphQLRequest() throws {
        let blog = Blog(content: "content", createdAt: .now(), owner: nil, authorNotes: nil)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: blog.modelName, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: blog))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation CreateBlog($input: CreateBlogInput!) {
          createBlog(input: $input) {
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
        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: blog)

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
        XCTAssert(input["content"] as? String == blog.content)
        XCTAssertFalse(input.keys.contains("owner"))
    }

    func testUpdateMutationGraphQLRequest() throws {
        let blog = Blog(content: "content", createdAt: .now(), owner: nil, authorNotes: nil)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: blog.modelName, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: blog))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation UpdateBlog($input: UpdateBlogInput!) {
          updateBlog(input: $input) {
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
        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: blog)

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
        XCTAssert(input["content"] as? String == blog.content)
        XCTAssertFalse(input.keys.contains("owner"))
    }

    func testDeleteMutationGraphQLRequest() throws {
        let blog = Blog(content: "content", createdAt: .now(), owner: nil, authorNotes: nil)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: blog.modelName, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(id: blog.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation DeleteBlog($input: DeleteBlogInput!) {
          deleteBlog(input: $input) {
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

        let request = GraphQLRequest<MutationSyncResult>.deleteMutation(modelName: blog.modelName, id: blog.id)

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
        XCTAssertEqual(input["id"] as? String, blog.id)
        XCTAssertFalse(input.keys.contains("owner"))
        XCTAssertFalse(input.keys.contains("authorNotes"))
    }

    func testOnCreateSubscriptionGraphQLRequest() throws {
        let modelType = Blog.self as Model.Type
        let ownerId = "111"
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, ownerId)))
        let document = documentBuilder.build()
        let documentStringValue = """
        subscription OnCreateBlog($owner: String!) {
          onCreateBlog(owner: $owner) {
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
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType,
                                                                      subscriptionType: .onCreate,
                                                                      ownerId: ownerId)

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
        XCTAssertEqual(input, ownerId)
    }

    func testOnUpdateSubscriptionGraphQLRequest() throws {
        let modelType = Blog.self as Model.Type
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onUpdate, "111")))
        let document = documentBuilder.build()
        let documentStringValue = """
        subscription OnUpdateBlog {
          onUpdateBlog {
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
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType,
                                                                      subscriptionType: .onUpdate,
                                                                      ownerId: "111")

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssertNil(request.variables)
    }

    func testOnDeleteSubscriptionGraphQLRequest() throws {
        let modelType = Blog.self as Model.Type
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onDelete, "111")))
        let document = documentBuilder.build()
        let documentStringValue = """
        subscription OnDeleteBlog {
          onDeleteBlog {
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
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType,
                                                                      subscriptionType: .onDelete,
                                                                      ownerId: "111")

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssertNil(request.variables)
    }

    func testSyncQueryGraphQLRequest() throws {
        let modelType = Blog.self as Model.Type
        let nextToken = "nextToken"
        let limit = 100
        let lastSync = 123
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: PaginationDecorator(limit: limit, nextToken: nextToken))
        documentBuilder.add(decorator: ConflictResolutionDecorator(lastSync: lastSync))
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let documentStringValue = """
        query SyncBlogs($lastSync: AWSTimestamp, $limit: Int, $nextToken: String) {
          syncBlogs(lastSync: $lastSync, limit: $limit, nextToken: $nextToken) {
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

        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: modelType,
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
