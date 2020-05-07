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
        let originalBlog = Blog(content: "content", createdAt: Date(), owner: nil)
        let anyBlog = try originalBlog.eraseToAnyModel()
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: anyBlog.modelName, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: anyBlog.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
        query GetBlog($id: ID!) {
          getBlog(id: $id) {
            id
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

        let request = GraphQLRequest<MutationSyncResult?>.query(modelName: anyBlog.modelName, byId: anyBlog.id)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult?.self)
        XCTAssert(request.variables != nil)
    }

    func testCreateMutationGraphQLRequest() throws {
        let originalBlog = Blog(content: "content", createdAt: Date(), owner: nil)
        let anyBlog = try originalBlog.eraseToAnyModel()
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: anyBlog.modelName,
                                                                    operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: anyBlog))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation CreateBlog($input: CreateBlogInput!) {
          createBlog(input: $input) {
            id
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
        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: anyBlog)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables != nil)
    }

    func testUpdateMutationGraphQLRequest() throws {
        let originalBlog = Blog(content: "content", createdAt: Date(), owner: nil)
        let anyBlog = try originalBlog.eraseToAnyModel()
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: anyBlog.modelName,
                                                                    operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: anyBlog))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation UpdateBlog($input: UpdateBlogInput!) {
          updateBlog(input: $input) {
            id
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
        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: anyBlog)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables != nil)
    }

    func testDeleteMutationGraphQLRequest() throws {
        let originalBlog = Blog(content: "content", createdAt: Date(), owner: nil)
        let anyBlog = try originalBlog.eraseToAnyModel()
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: anyBlog.modelName,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(id: anyBlog.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation DeleteBlog($input: DeleteBlogInput!) {
          deleteBlog(input: $input) {
            id
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

        let request = GraphQLRequest<MutationSyncResult>.deleteMutation(modelName: anyBlog.modelName, id: anyBlog.id)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables != nil)
    }

    func testOnCreateSubscriptionGraphQLRequest() throws {
        let modelType = Blog.self as Model.Type
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(subscriptionType: .onCreate, ownerId: "111"))
        let document = documentBuilder.build()
        let documentStringValue = """
        subscription OnCreateBlog($owner: String!) {
          onCreateBlog(owner: $owner) {
            id
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
                                                                      ownerId: "111")

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssertNil(request.variables)
    }

    func testOnUpdateSubscriptionGraphQLRequest() throws {
        let modelType = Blog.self as Model.Type
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(subscriptionType: .onUpdate, ownerId: "111"))
        let document = documentBuilder.build()
        let documentStringValue = """
        subscription OnUpdateBlog($owner: String!) {
          onUpdateBlog(owner: $owner) {
            id
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
        documentBuilder.add(decorator: AuthRuleDecorator(subscriptionType: .onDelete, ownerId: "111"))
        let document = documentBuilder.build()
        let documentStringValue = """
        subscription OnDeleteBlog($owner: String!) {
          onDeleteBlog(owner: $owner) {
            id
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
        documentBuilder.add(decorator: AuthRuleDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
        query SyncBlogs($lastSync: AWSTimestamp, $limit: Int, $nextToken: String) {
          syncBlogs(lastSync: $lastSync, limit: $limit, nextToken: $nextToken) {
            items {
              id
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
                                                                nextToken: nextToken,
                                                                lastSync: lastSync)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == SyncQueryResult.self)
        XCTAssert(request.variables != nil)
    }
}
