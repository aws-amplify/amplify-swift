//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

// Decoder tests for ParentPost4V2 and ChildComment4V2
class GraphQLResponseDecoderPostComment4V2Tests: XCTestCase, SharedTestCasesPostComment4V2 {

    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    override func setUp() async throws {
        await Amplify.reset()
        ModelRegistry.register(modelType: ParentPost4V2.self)
        ModelRegistry.register(modelType: ChildComment4V2.self)
        ModelListDecoderRegistry.registerDecoder(AppSyncListDecoder.self)
        ModelProviderRegistry.registerDecoder(AppSyncModelDecoder.self)

        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
    }
    
    func testSaveCommentThenQueryComment() async throws {
        let comment = ChildComment4V2(content: "content")
        // Create request
        let request = GraphQLRequest<ChildComment4V2>.create(comment)
        var documentString = """
        mutation CreateChildComment4V2($input: CreateChildComment4V2Input!) {
          createChildComment4V2(input: $input) {
            id
            content
            createdAt
            updatedAt
            post {
              id
              createdAt
              title
              updatedAt
              __typename
            }
            __typename
          }
        }
        """
        XCTAssertEqual(request.document, documentString)
        guard let variables = request.variables,
              let input = variables["input"] as? [String: Any] else {
            XCTFail("Missing request.variables input")
            return
        }
        XCTAssertEqual(input["id"] as? String, comment.id)
        XCTAssertEqual(input["content"] as? String, comment.content)
        
        // Get request
        let getRequest = GraphQLRequest<ChildComment4V2>.get(ChildComment4V2.self, byId: comment.id)
        documentString = """
        query GetChildComment4V2($id: ID!) {
          getChildComment4V2(id: $id) {
            id
            content
            createdAt
            updatedAt
            post {
              id
              createdAt
              title
              updatedAt
              __typename
            }
            __typename
          }
        }
        """
        XCTAssertEqual(getRequest.document, documentString)
        guard let variables = getRequest.variables,
              let id = variables["id"] as? String else {
            XCTFail("Missing request.variables id")
            return
        }
        XCTAssertEqual(id, comment.id)
        
        // Decode data
        let decoder = GraphQLResponseDecoder(request: getRequest.toOperationRequest(operationType: .mutation))
        let graphQLData: [String: JSONValue] = [
            "\(getRequest.decodePath!)": [
                "id": "id",
                "content": "content",
                "createdAt": nil,
                "updatedAt": nil,
                "post": nil,
                "__typename": "ChildComment4V2"
            ]
        ]

        guard let savedComment = try decoder.decodeToResponseType(graphQLData) else {
            XCTFail("Could not decode to comment")
            return
        }
        XCTAssertEqual(savedComment.id, "id")
        XCTAssertEqual(savedComment.content, "content")
        XCTAssertNil(savedComment.post)
    }
    
    func testSavePostThenQueryPost() async throws {
        let post = ParentPost4V2(title: "title")
        
        // Create request
        let request = GraphQLRequest<ParentPost4V2>.create(post)
        var documentString = """
        mutation CreateParentPost4V2($input: CreateParentPost4V2Input!) {
          createParentPost4V2(input: $input) {
            id
            createdAt
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(request.document, documentString)
        guard let variables = request.variables,
              let input = variables["input"] as? [String: Any] else {
            XCTFail("Missing request.variables input")
            return
        }
        XCTAssertEqual(input["id"] as? String, post.id)
        XCTAssertEqual(input["title"] as? String, post.title)
        
        // Get request
        let getRequest = GraphQLRequest<ParentPost4V2>.get(ParentPost4V2.self, byId: post.id)
        documentString = """
        query GetParentPost4V2($id: ID!) {
          getParentPost4V2(id: $id) {
            id
            createdAt
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(getRequest.document, documentString)
        guard let variables = getRequest.variables,
              let id = variables["id"] as? String else {
            XCTFail("Missing request.variables id")
            return
        }
        XCTAssertEqual(id, post.id)
        
        // Decode data
        let decoder = GraphQLResponseDecoder(request: getRequest.toOperationRequest(operationType: .mutation))
        let graphQLData: [String: JSONValue] = [
            "\(getRequest.decodePath!)": [
                "id": "postId",
                "title": "title",
                "createdAt": nil,
                "updatedAt": nil,
                "__typename": "ParentPost4V2"
            ]
        ]

        guard let decodedPost = try decoder.decodeToResponseType(graphQLData) else {
            XCTFail("Failed to decode to post")
            return
        }
        XCTAssertEqual(decodedPost.id, "postId")
        XCTAssertEqual(decodedPost.title, "title")
        guard let comments = decodedPost.comments else {
            XCTFail("Failed to create  list of comments")
            return
        }
        switch comments.listProvider.getState() {
        case .notLoaded(let associatedIdentifiers, let associatedField):
            XCTAssertEqual(associatedIdentifiers, ["postId"])
            XCTAssertEqual(associatedField, ChildComment4V2.CodingKeys.post.stringValue)
        case .loaded:
            XCTFail("Should be not loaded with post data")
        }
    }
    
    func testSaveMultipleThenQueryComments() async throws {
        let request = GraphQLRequest<ChildComment4V2>.list(ChildComment4V2.self)
        let documentString = """
        query ListChildComment4V2s($limit: Int) {
          listChildComment4V2s(limit: $limit) {
            items {
              id
              content
              createdAt
              updatedAt
              post {
                id
                createdAt
                title
                updatedAt
                __typename
              }
              __typename
            }
            nextToken
          }
        }
        """
        XCTAssertEqual(request.document, documentString)
        guard let variables = request.variables,
              let limit = variables["limit"] as? Int else {
            XCTFail("Missing request.variables input")
            return
        }
        XCTAssertEqual(limit, 1000)
        let decoder = GraphQLResponseDecoder<List<ChildComment4V2>>(
            request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "\(request.decodePath!)": [
                "items": [
                    [
                        "id": "id1",
                        "content": "content1",
                        "__typename": "ChildComment4V2",
                        "post": nil
                    ],
                    [
                        "id": "id2",
                        "content": "content2",
                        "__typename": "ChildComment4V2",
                        "post": nil
                    ],
                ],
                "nextToken": "nextToken"
            ]
        ]

        let queriedList = try decoder.decodeToResponseType(graphQLData)
        switch queriedList.listProvider.getState() {
        case .notLoaded:
            XCTFail("A direct query should have a loaded list")
        case .loaded:
            break
        }
        XCTAssertEqual(queriedList.count, 2)
        let comment1 = queriedList.first { $0.id == "id1" }
        let comment2 = queriedList.first { $0.id == "id2" }
        XCTAssertNotNil(comment1)
        XCTAssertNotNil(comment2)
        XCTAssertTrue(queriedList.hasNextPage())
    }
    
    func testSaveMultipleThenQueryPosts() async throws {
        let request = GraphQLRequest<ParentPost4V2>.list(ParentPost4V2.self)
        let documentString = """
        query ListParentPost4V2s($limit: Int) {
          listParentPost4V2s(limit: $limit) {
            items {
              id
              createdAt
              title
              updatedAt
              __typename
            }
            nextToken
          }
        }
        """
        XCTAssertEqual(request.document, documentString)
        guard let variables = request.variables,
              let limit = variables["limit"] as? Int else {
            XCTFail("Missing request.variables input")
            return
        }
        XCTAssertEqual(limit, 1000)
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "\(request.decodePath!)": [
                "items": [
                    [
                        "id": "id1",
                        "title": "title",
                        "__typename": "ParentPost4V2",
                    ],
                    [
                        "id": "id2",
                        "title": "title",
                        "__typename": "ParentPost4V2",
                    ]
                ],
                "nextToken": "nextToken"
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(result.count, 2)
        let post1 = result.first { $0.id == "id1" }
        let post2 = result.first { $0.id == "id2" }
        XCTAssertNotNil(post1)
        XCTAssertNotNil(post2)
    }
    
    func testSaveCommentWithPostThenQueryCommentAndAccessPost() async throws {
        let post = ParentPost4V2(title: "title")
        let comment = ChildComment4V2(content: "content", post: post)
        
        let request = GraphQLRequest<ChildComment4V2>.create(comment)
        guard let variables = request.variables,
              let input = variables["input"] as? [String: Any] else {
            XCTFail("Missing request.variables input")
            return
        }
        XCTAssertEqual(input["id"] as? String, comment.id)
        XCTAssertEqual(input["content"] as? String, comment.content)
        XCTAssertEqual(input["postID"] as? String, post.id)
        
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        var graphQLData: [String: JSONValue] = [
            "\(request.decodePath!)": [
                "id": "id",
                "content": "content",
                "createdAt": nil,
                "updatedAt": nil,
                "post": [
                    "id": .string("\(post.id)"),
                    "title": "title",
                    "updatedAt": nil,
                    "createdAt": nil,
                    "__typename": "ParentPost4V2"
                ],
                "__typename": "ChildComment4V2"
            ]
        ]

        let commentWithEagerLoadedPost = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(commentWithEagerLoadedPost.id, "id")
        XCTAssertEqual(commentWithEagerLoadedPost.content, "content")
        XCTAssertEqual(commentWithEagerLoadedPost.post?.id, post.id)
    }
    
    func testSaveCommentWithPostThenQueryPostAndAccessComments() async throws {
        let post = ParentPost4V2(title: "title")
        
        let request = GraphQLRequest<ParentPost4V2>.create(post)
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "\(request.decodePath!)": [
                "id": "postId",
                "title": "title",
                "createdAt": nil,
                "updatedAt": nil,
                "__typename": "ParentPost4V2"
            ]
        ]

        let decodedPost = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(decodedPost.id, "postId")
        XCTAssertEqual(decodedPost.title, "title")
        guard let comments = decodedPost.comments else {
            XCTFail("Failed to create  list of comments")
            return
        }
        switch comments.listProvider.getState() {
        case .notLoaded(let associatedIdentifiers, let associatedField):
            XCTAssertEqual(associatedIdentifiers, ["postId"])
            XCTAssertEqual(associatedField, ChildComment4V2.CodingKeys.post.stringValue)
        case .loaded:
            XCTFail("Should be not loaded with post data")
        }
    }
    
    func testSaveMultipleCommentWithPostThenQueryCommentsAndAccessPost() async throws {
        let post = ParentPost4V2(title: "title")
        let request = GraphQLRequest<ChildComment4V2>.list(ChildComment4V2.self)
        let decoder = GraphQLResponseDecoder<List<ChildComment4V2>>(
            request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "\(request.decodePath!)": [
                "items": [
                    [
                        "id": "id1",
                        "content": "content1",
                        "__typename": "ChildComment4V2",
                        "post": [
                            "id": .string("\(post.id)"),
                            "title": "title",
                            "updatedAt": nil,
                            "createdAt": nil,
                            "__typename": "ParentPost4V2"
                        ],
                    ],
                ],
                "nextToken": "nextToken"
            ]
        ]
        let queriedList = try decoder.decodeToResponseType(graphQLData)
        guard let comment = queriedList.first else {
            XCTFail("Failed to decode to comment")
            return
        }
        XCTAssertEqual(comment.post?.id, post.id)
    }
    
    func testSaveMultipleCommentWithPostThenQueryPostAndAccessComments() async throws {
        let request = GraphQLRequest<ParentPost4V2>.list(ParentPost4V2.self)
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "\(request.decodePath!)": [
                "items": [
                    [
                        "id": "id1",
                        "title": "title",
                        "__typename": "ParentPost4V2",
                    ]
                ],
                "nextToken": "nextToken"
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(result.count, 1)
        guard let post = result.first,
              let comments = post.comments else {
            XCTFail("Failed to decode to one post, with containing comments")
            return
        }
        switch comments.listProvider.getState() {
        case .notLoaded(let associatedIdentifiers, let associatedField):
            XCTAssertEqual(associatedIdentifiers, ["id1"])
            XCTAssertEqual(associatedField, "post")
        case .loaded:
            XCTFail("Should be in not loaded state")
        }
    }
}

