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
class GraphQLResponseDecoderLazyPostComment4V2Tests: XCTestCase {

    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    override func setUp() async throws {
        await Amplify.reset()
        ModelRegistry.register(modelType: LazyParentPost4V2.self)
        ModelRegistry.register(modelType: LazyChildComment4V2.self)
        ModelListDecoderRegistry.registerDecoder(AppSyncListDecoder.self)
        ModelProviderRegistry.registerDecoder(AppSyncModelDecoder.self)

        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
    }
    
    /*
     This test will start to fail if we remove the optionality on the LazyModel type, from
     ```
     public struct LazyChildComment4V2: Model {
       public var post: LazyModel<LazyParentPost4V2>?
     ```
     to
     ```
     public struct LazyChildComment4V2: Model {
       public var post: LazyModel<LazyParentPost4V2>
     ```
     with the error
     ```
      "keyNotFound(CodingKeys(stringValue: "post", intValue: nil),
      Swift.DecodingError.Context(codingPath: [],
      debugDescription: "No value associated with key CodingKeys(stringValue: \"post\", intValue: nil)
       (\"post\").", underlyingError: nil))"
     ```
     */
    func testQueryComment() throws {
        let request = GraphQLRequest<LazyChildComment4V2>(document: "",
                                                          responseType: LazyChildComment4V2.self,
                                                          decodePath: "getLazyChildComment4V2")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "getLazyChildComment4V2": [
                "id": "id",
                "content": "content"
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(result.id, "id")
        XCTAssertEqual(result.content, "content")
    }
    
    func testQueryPost() throws {
        let request = GraphQLRequest<LazyParentPost4V2>(document: "",
                                                      responseType: LazyParentPost4V2.self,
                                                      decodePath: "getLazyParentPost4V2")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "getLazyParentPost4V2": [
                "id": "id",
                "title": "title"
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(result.id, "id")
        XCTAssertEqual(result.title, "title")
    }
     
    func testQueryListComments() throws {
        let request = GraphQLRequest<List<LazyChildComment4V2>>(document: "",
                                                            responseType: List<LazyChildComment4V2>.self,
                                                            decodePath: "listLazyChildComment4V2")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "listLazyChildComment4V2": [
                "items": [
                    [
                        "id": "id1",
                        "content": "content1"
                    ],
                    [
                        "id": "id2",
                        "content": "content2"
                    ]
                ]
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(result.count, 2)
        let comment1 = result.first { $0.id == "id1" }
        let comment2 = result.first { $0.id == "id2" }
        XCTAssertNotNil(comment1)
        XCTAssertNotNil(comment2)
    }
    
    func testQueryListPosts() throws {
        let request = GraphQLRequest<List<LazyParentPost4V2>>(document: "",
                                                              responseType: List<LazyParentPost4V2>.self,
                                                              decodePath: "listLazyParentPost4V2")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "listLazyParentPost4V2": [
                "items": [
                    [
                        "id": "id1",
                        "title": "title"
                    ],
                    [
                        "id": "id2",
                        "title": "title"
                    ]
                ]
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(result.count, 2)
        let post1 = result.first { $0.id == "id1" }
        let post2 = result.first { $0.id == "id2" }
        XCTAssertNotNil(post1)
        XCTAssertNotNil(post2)
    }
        
    func testPostHasLazyLoadedComments() throws {
        let request = GraphQLRequest<LazyParentPost4V2>.get(LazyParentPost4V2.self, byId: "id")
        let documentStringValue = """
        query GetLazyParentPost4V2($id: ID!) {
          getLazyParentPost4V2(id: $id) {
            id
            createdAt
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(request.document, documentStringValue)
        XCTAssertEqual(request.decodePath, "getLazyParentPost4V2")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "\(request.decodePath!)": [
                "id": "postId",
                "title": "title",
                "__typename": "LazyParentPost4V2"
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        guard let post = result else {
            XCTFail("Failed to decode to post")
            return
        }
        XCTAssertEqual(post.id, "postId")
        XCTAssertEqual(post.title, "title")
        guard let comments = post.comments else {
            XCTFail("Could not create list of comments")
            return
        }
        let state = comments.listProvider.getState()
        switch state {
        case .notLoaded(let associatedId, let associatedField):
            XCTAssertEqual(associatedId, "postId")
            XCTAssertEqual(associatedField, "post")
        case .loaded:
            XCTFail("Should be not loaded")
        }
    }
    
    func testPostHasEagerLoadedComments() throws {
        // Since we are mocking `graphQLData` below, it does not matter what selection set is contained
        // inside the `document` parameter, however for an integration level test, the custom selection set
        // should contain two levels, the post fields and the nested comment fields.
        let request = GraphQLRequest<LazyParentPost4V2?>(document: "",
                                                         responseType: LazyParentPost4V2?.self,
                                                         decodePath: "getLazyParentPost4V2")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "getLazyParentPost4V2": [
                "id": "postId",
                "title": "title",
                "__typename": "LazyParentPost4V2",
                "comments": [
                    [
                        "id": "id1",
                        "content": "content1"
                    ],
                    [
                        "id": "id2",
                        "content": "content2"
                    ]
                ]
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        guard let post = result else {
            XCTFail("Failed to decode to post")
            return
        }
        XCTAssertEqual(post.id, "postId")
        XCTAssertEqual(post.title, "title")
        guard let comments = post.comments else {
            XCTFail("Could not create list of comments")
            return
        }
        let state = comments.listProvider.getState()
        switch state {
        case .notLoaded:
            XCTFail("Should be loaded")
        case .loaded(let comments):
            XCTAssertEqual(comments.count, 2)
            let comment1 = comments.first { $0.id == "id1" }
            let comment2 = comments.first { $0.id == "id2" }
            XCTAssertNotNil(comment1)
            XCTAssertNotNil(comment2)
        }
    }
    
    func testCommentHasEagerLoadedPost() throws {
        // By default, the `.get` for a child model with belongs-to parent creates a nested selection set
        // as shown below by `documentStringValue`, so we mock the `graphQLData` with a nested object
        // comment containing a post
        let request = GraphQLRequest<LazyChildComment4V2>.get(LazyChildComment4V2.self, byId: "id")
        let documentStringValue = """
        query GetLazyChildComment4V2($id: ID!) {
          getLazyChildComment4V2(id: $id) {
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
        XCTAssertEqual(request.document, documentStringValue)
        XCTAssertEqual(request.decodePath, "getLazyChildComment4V2")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "getLazyChildComment4V2": [
                "id": "id",
                "content": "content",
                "post": [
                    "id": "postId",
                    "title": "title",
                    "__typename": "LazyParentPost4V2"
                ],
                "__typename": "LazyChildComment4V2"
            ]
        ]

        let comment = try decoder.decodeToResponseType(graphQLData)
        guard let comment = comment else {
            XCTFail("Could not load comment")
            return
        }
        
        XCTAssertEqual(comment.id, "id")
        XCTAssertEqual(comment.content, "content")
        guard let post = comment.post else {
            XCTFail("LazModel should be created")
            return
        }
        switch post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("Should have been loaded")
        case .loaded(let post):
            guard let post = post else {
                XCTFail("Loaded with no post")
                return
            }
            XCTAssertEqual(post.id, "postId")
            XCTAssertEqual(post.title, "title")
        }
    }
    
    func testCommentHasLazyLoadPostFromPartialPost() throws {
        let request = GraphQLRequest<LazyChildComment4V2>.get(LazyChildComment4V2.self, byId: "id")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        // The data used to seed the decoder contains the nested `post` that mimics an incomplete selection set
        // so it is missing some required fields such as `title` and still be successful in creating a "not loaded"
        // lazy model object.
        let graphQLData: [String: JSONValue] = [
            "getLazyChildComment4V2": [
                "id": "id",
                "content": "content",
                "post": [
                    "id": "postId",
                    "__typename": "LazyParentPost4V2"
                ],
                "__typename": "LazyChildComment4V2"
            ]
        ]

        let comment = try decoder.decodeToResponseType(graphQLData)
        guard let comment = comment else {
            XCTFail("Could not load comment")
            return
        }
        
        XCTAssertEqual(comment.id, "id")
        XCTAssertEqual(comment.content, "content")
        guard let post = comment.post else {
            XCTFail("LazModel should be created")
            return
        }
        switch post.modelProvider.getState() {
        case .notLoaded(let id):
            XCTAssertEqual(id, "postId")
        case .loaded:
            XCTFail("Should be not loaded")
        }
    }
    
    func testCommentHasLazyLoadPostFromNilPost() throws {
        let request = GraphQLRequest<LazyChildComment4V2>.get(LazyChildComment4V2.self, byId: "id")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        // The data used to seed the decoder contains the nested `post` that mimics an incomplete selection set
        // so it is missing some required fields such as `title` and still be successfully in creating a "not loaded"
        // lazy model. When the LazyModel decoder runs, it is responsible for attempting to decode to the right state
        // either loaded if the entire post object is there, or not loaded when the minimum required "not loaded"
        // information is there.
        let graphQLData: [String: JSONValue] = [
            "getLazyChildComment4V2": [
                "id": "commentId",
                "content": "content",
                "post": nil,
                "__typename": "LazyChildComment4V2"
            ]
        ]

        let comment = try decoder.decodeToResponseType(graphQLData)
        guard let comment = comment else {
            XCTFail("Could not load comment")
            return
        }
        
        XCTAssertEqual(comment.id, "commentId")
        XCTAssertEqual(comment.content, "content")
        guard comment.post == nil else {
            XCTFail("lazy model should be nil")
            return
        }
    }
    
    func testCommentHasLazyLoadPostFromEmptyPost() throws {
        let request = GraphQLRequest<LazyChildComment4V2>.get(LazyChildComment4V2.self, byId: "id")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "getLazyChildComment4V2": [
                "id": "id",
                "content": "content",
                "__typename": "LazyChildComment4V2"
            ]
        ]

        let comment = try decoder.decodeToResponseType(graphQLData)
        guard let comment = comment else {
            XCTFail("Could not load comment")
            return
        }
        
        XCTAssertEqual(comment.id, "id")
        XCTAssertEqual(comment.content, "content")
        guard comment.post == nil else {
            XCTFail("LazModel should not be nil")
            return
        }
    }
    
    func testListCommentHasEagerLoadedPost() throws {
        // By default, the `.list` for a list of children models with belongs-to parent creates a nested selection set
        // as shown below by `documentStringValue`, so we mock the `graphQLData` with a list of nested objects
        // comments, each containing a post
        let request = GraphQLRequest<List<LazyChildComment4V2>>.list(LazyChildComment4V2.self)
        let documentStringValue = """
        query ListLazyChildComment4V2s($limit: Int) {
          listLazyChildComment4V2s(limit: $limit) {
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
        XCTAssertEqual(request.document, documentStringValue)
        XCTAssertEqual(request.decodePath, "listLazyChildComment4V2s")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "listLazyChildComment4V2s": [
                "items": [
                    [
                        "id": "id1",
                        "content": "content1",
                        "__typename": "LazyChildComment4V2",
                        "post": [
                            "id": "postId1",
                            "title": "title1",
                            "__typename": "LazyParentPost4V2"
                        ]
                    ],
                    [
                        "id": "id2",
                        "content": "content2",
                        "__typename": "LazyChildComment4V2",
                        "post": [
                            "id": "postId2",
                            "title": "title2",
                            "__typename": "LazyParentPost4V2"
                        ]
                    ]
                ]
            ]
        ]
        
        let comments = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(comments.count, 2)
        guard let comment1 = comments.first(where: { $0.id == "id1" }) else {
            XCTFail("Couldn't find comment with `id1`")
            return
        }
        guard let comment2 = comments.first(where: { $0.id == "id2" }) else {
            XCTFail("Couldn't find comment with `id2`")
            return
        }
        guard let post1 = comment1.post else {
            XCTFail("missing post on comment1")
            return
        }
        guard let post2 = comment2.post else {
            XCTFail("missing post on comment2")
            return
        }
        
        switch post1.modelProvider.getState() {
        case .notLoaded:
            XCTFail("Should be loaded")
        case .loaded(let post):
            XCTAssertEqual(post!.id, "postId1")
            XCTAssertEqual(post!.title, "title1")
        }
        switch post2.modelProvider.getState() {
        case .notLoaded:
            XCTFail("Should be loaded")
        case .loaded(let post):
            XCTAssertEqual(post!.id, "postId2")
            XCTAssertEqual(post!.title, "title2")
        }
    }
    
    func testListCommentHasLazyLoadedPartialPost() throws {
        // By default, the `.list` for a list of children models with belongs-to parent creates a nested selection set
        // as shown below by `documentStringValue`, so we mock the `graphQLData` with a list of nested objects
        // comments, each containing a partial post, so that the post will be "not loaded" and requires lazy loading
        let request = GraphQLRequest<List<LazyChildComment4V2>>.list(LazyChildComment4V2.self)
        XCTAssertEqual(request.decodePath, "listLazyChildComment4V2s")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        
        let graphQLData: [String: JSONValue] = [
            "listLazyChildComment4V2s": [
                "items": [
                    [
                        "id": "id1",
                        "content": "content1",
                        "__typename": "LazyChildComment4V2",
                        "post": [
                            "id": "postId1",
                            "__typename": "LazyParentPost4V2"
                        ]
                    ],
                    [
                        "id": "id2",
                        "content": "content2",
                        "__typename": "LazyChildComment4V2",
                        "post": [
                            "id": "postId2",
                            "__typename": "LazyParentPost4V2"
                        ]
                    ]
                ]
            ]
        ]
        
        let comments = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(comments.count, 2)
        guard let comment1 = comments.first(where: { $0.id == "id1" }) else {
            XCTFail("Couldn't find comment with `id1`")
            return
        }
        guard let comment2 = comments.first(where: { $0.id == "id2" }) else {
            XCTFail("Couldn't find comment with `id2`")
            return
        }
        guard let post1 = comment1.post else {
            XCTFail("missing post on comment1")
            return
        }
        guard let post2 = comment2.post else {
            XCTFail("missing post on comment2")
            return
        }
        
        switch post1.modelProvider.getState() {
        case .notLoaded(let identifier):
            XCTAssertEqual(identifier, "postId1")
        case .loaded:
            XCTFail("Should be not loaded")
        }
        switch post2.modelProvider.getState() {
        case .notLoaded(let identifier):
            XCTAssertEqual(identifier, "postId2")
        case .loaded:
            XCTFail("Should be not loaded")
        }
    }
}


// MARK: - Models

public struct LazyParentPost4V2: Model {
  public let id: String
  public var title: String
  public var comments: List<LazyChildComment4V2>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      title: String,
      comments: List<LazyChildComment4V2>? = []) {
    self.init(id: id,
      title: title,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      comments: List<LazyChildComment4V2>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
extension LazyParentPost4V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post4V2 = Post4V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Post4V2s"

    model.fields(
      .id(),
      .field(post4V2.title, is: .required, ofType: .string),
      .hasMany(post4V2.comments, is: .optional, ofType: LazyChildComment4V2.self, associatedWith: LazyChildComment4V2.keys.post),
      .field(post4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

public struct LazyChildComment4V2: Model {
  public let id: String
  public var content: String
  public var post: LazyModel<LazyParentPost4V2>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      content: String,
      post: LazyParentPost4V2? = nil) {
    self.init(id: id,
      content: content,
      post: post,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String,
      post: LazyParentPost4V2? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.post = LazyModel(element: post)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

extension LazyChildComment4V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case post
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment4V2 = Comment4V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Comment4V2s"

    model.attributes(
      .index(fields: ["postID", "content"], name: "byPost4")
    )

    model.fields(
      .id(),
      .field(comment4V2.content, is: .required, ofType: .string),
      .belongsTo(comment4V2.post, is: .optional, ofType: LazyParentPost4V2.self, targetName: "postID"),
      .field(comment4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
