//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
import AWSPluginsCore

extension AWSDataStoreLazyLoadBlogPostComment8V2Tests {

    func testBlogSelectionSets() async throws {
        await setup(withModels: BlogPostComment8V2Models(), eagerLoad: false, clearOnTearDown: false)
        continueAfterFailure = true
        let blog = Blog(name: "name")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: blog, modelSchema: Blog.schema)
        let createDocument = """
        mutation CreateBlog8V2($input: CreateBlog8V2Input!) {
          createBlog8V2(input: $input) {
            id
            createdAt
            customs {
              children {
                id
                nestedName
                notes
                __typename
              }
              desc
              id
              name
              __typename
            }
            name
            notes
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(createRequest.document, createDocument)
        
        // Update
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: blog, modelSchema: Blog.schema)
        let updateDocument = """
        mutation UpdateBlog8V2($input: UpdateBlog8V2Input!) {
          updateBlog8V2(input: $input) {
            id
            createdAt
            customs {
              children {
                id
                nestedName
                notes
                __typename
              }
              desc
              id
              name
              __typename
            }
            name
            notes
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(updateRequest.document, updateDocument)
        
        // Delete
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: blog, modelSchema: Blog.schema)
        let deleteDocument = """
        mutation DeleteBlog8V2($input: DeleteBlog8V2Input!) {
          deleteBlog8V2(input: $input) {
            id
            createdAt
            customs {
              children {
                id
                nestedName
                notes
                __typename
              }
              desc
              id
              name
              __typename
            }
            name
            notes
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(deleteRequest.document, deleteDocument)
        
        // onCreate
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Blog.self, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateBlog8V2 {
          onCreateBlog8V2 {
            id
            createdAt
            customs {
              children {
                id
                nestedName
                notes
                __typename
              }
              desc
              id
              name
              __typename
            }
            name
            notes
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(onCreateRequest.document, onCreateDocument)
        
        // onUpdate
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Blog.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateBlog8V2 {
          onUpdateBlog8V2 {
            id
            createdAt
            customs {
              children {
                id
                nestedName
                notes
                __typename
              }
              desc
              id
              name
              __typename
            }
            name
            notes
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(onUpdateRequest.document, onUpdateDocument)
        
        // onDelete
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Blog.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteBlog8V2 {
          onDeleteBlog8V2 {
            id
            createdAt
            customs {
              children {
                id
                nestedName
                notes
                __typename
              }
              desc
              id
              name
              __typename
            }
            name
            notes
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(onDeleteRequest.document, onDeleteDocument)
        
        // SyncQuery
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Blog.self)
        let syncDocument = """
        query SyncBlog8V2s($limit: Int) {
          syncBlog8V2s(limit: $limit) {
            items {
              id
              createdAt
              customs {
                children {
                  id
                  nestedName
                  notes
                  __typename
                }
                desc
                id
                name
                __typename
              }
              name
              notes
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
        XCTAssertEqual(syncRequest.document, syncDocument)
    }
    
    func testPostSelectionSets() async throws {
        await setup(withModels: BlogPostComment8V2Models(), eagerLoad: false, clearOnTearDown: false)
        continueAfterFailure = true
        let post = Post(name: "name")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: post, modelSchema: Post.schema)
        let createDocument = """
        mutation CreatePost8V2($input: CreatePost8V2Input!) {
          createPost8V2(input: $input) {
            id
            createdAt
            name
            randomId
            updatedAt
            blog {
              id
              createdAt
              customs {
                children {
                  id
                  nestedName
                  notes
                  __typename
                }
                desc
                id
                name
                __typename
              }
              name
              notes
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
        XCTAssertEqual(createRequest.document, createDocument)
        
        // Update
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: post, modelSchema: Post.schema)
        let updateDocument = """
        mutation UpdatePost8V2($input: UpdatePost8V2Input!) {
          updatePost8V2(input: $input) {
            id
            createdAt
            name
            randomId
            updatedAt
            blog {
              id
              createdAt
              customs {
                children {
                  id
                  nestedName
                  notes
                  __typename
                }
                desc
                id
                name
                __typename
              }
              name
              notes
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
        XCTAssertEqual(updateRequest.document, updateDocument)
        
        // Delete
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: post, modelSchema: Post.schema)
        let deleteDocument = """
        mutation DeletePost8V2($input: DeletePost8V2Input!) {
          deletePost8V2(input: $input) {
            id
            createdAt
            name
            randomId
            updatedAt
            blog {
              id
              createdAt
              customs {
                children {
                  id
                  nestedName
                  notes
                  __typename
                }
                desc
                id
                name
                __typename
              }
              name
              notes
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
        XCTAssertEqual(deleteRequest.document, deleteDocument)
        
        // onCreate
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Post.self, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreatePost8V2 {
          onCreatePost8V2 {
            id
            createdAt
            name
            randomId
            updatedAt
            blog {
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
        XCTAssertEqual(onCreateRequest.document, onCreateDocument)
        
        // onUpdate
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Post.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdatePost8V2 {
          onUpdatePost8V2 {
            id
            createdAt
            name
            randomId
            updatedAt
            blog {
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
        XCTAssertEqual(onUpdateRequest.document, onUpdateDocument)
        
        // onDelete
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Post.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeletePost8V2 {
          onDeletePost8V2 {
            id
            createdAt
            name
            randomId
            updatedAt
            blog {
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
        XCTAssertEqual(onDeleteRequest.document, onDeleteDocument)
        
        // SyncQuery
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Post.self)
        let syncDocument = """
        query SyncPost8V2s($limit: Int) {
          syncPost8V2s(limit: $limit) {
            items {
              id
              createdAt
              name
              randomId
              updatedAt
              blog {
                id
                __typename
                _deleted
              }
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
        XCTAssertEqual(syncRequest.document, syncDocument)
    }
    
    func testCommentSelectionSets() async throws {
        await setup(withModels: BlogPostComment8V2Models(), eagerLoad: false, clearOnTearDown: false)
        continueAfterFailure = true
        let post = Post(name: "name")
        let comment = Comment(content: "content", post: post)
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: comment, modelSchema: Comment.schema)
        let createDocument = """
        mutation CreateComment8V2($input: CreateComment8V2Input!) {
          createComment8V2(input: $input) {
            id
            content
            createdAt
            updatedAt
            post {
              id
              createdAt
              name
              randomId
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
        XCTAssertEqual(createRequest.document, createDocument)
        
        // Update
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: comment, modelSchema: Comment.schema)
        let updateDocument = """
        mutation UpdateComment8V2($input: UpdateComment8V2Input!) {
          updateComment8V2(input: $input) {
            id
            content
            createdAt
            updatedAt
            post {
              id
              createdAt
              name
              randomId
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
        XCTAssertEqual(updateRequest.document, updateDocument)
        
        // Delete
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: comment, modelSchema: Comment.schema)
        let deleteDocument = """
        mutation DeleteComment8V2($input: DeleteComment8V2Input!) {
          deleteComment8V2(input: $input) {
            id
            content
            createdAt
            updatedAt
            post {
              id
              createdAt
              name
              randomId
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
        XCTAssertEqual(deleteRequest.document, deleteDocument)
        
        // onCreate
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Comment.schema, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateComment8V2 {
          onCreateComment8V2 {
            id
            content
            createdAt
            updatedAt
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
        XCTAssertEqual(onCreateRequest.document, onCreateDocument)
        
        // onUpdate
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Comment.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateComment8V2 {
          onUpdateComment8V2 {
            id
            content
            createdAt
            updatedAt
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
        XCTAssertEqual(onUpdateRequest.document, onUpdateDocument)
        
        // onDelete
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Comment.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteComment8V2 {
          onDeleteComment8V2 {
            id
            content
            createdAt
            updatedAt
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
        XCTAssertEqual(onDeleteRequest.document, onDeleteDocument)
        
        // SyncQuery
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Comment.self)
        let syncDocument = """
        query SyncComment8V2s($limit: Int) {
          syncComment8V2s(limit: $limit) {
            items {
              id
              content
              createdAt
              updatedAt
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
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(syncRequest.document, syncDocument)
    }
}
