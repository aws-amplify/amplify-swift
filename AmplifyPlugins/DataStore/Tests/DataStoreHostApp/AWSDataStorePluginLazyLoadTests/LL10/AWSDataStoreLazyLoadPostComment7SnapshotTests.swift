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

extension AWSDataStoreLazyLoadPostComment7Tests {

    func testPostSelectionSets() {
        setUpModelRegistrationOnly(withModels: PostComment7Models())
        continueAfterFailure = true
        let post = Post(postId: UUID().uuidString, title: "title")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: post, modelSchema: Post.schema)
        let createDocument = """
        mutation CreatePost7($input: CreatePost7Input!) {
          createPost7(input: $input) {
            postId
            title
            createdAt
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
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: post, modelSchema: Post.schema)
        let updateDocument = """
        mutation UpdatePost7($input: UpdatePost7Input!) {
          updatePost7(input: $input) {
            postId
            title
            createdAt
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
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: post, modelSchema: Post.schema)
        let deleteDocument = """
        mutation DeletePost7($input: DeletePost7Input!) {
          deletePost7(input: $input) {
            postId
            title
            createdAt
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
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Post.self, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreatePost7 {
          onCreatePost7 {
            postId
            title
            createdAt
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
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Post.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdatePost7 {
          onUpdatePost7 {
            postId
            title
            createdAt
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
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Post.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeletePost7 {
          onDeletePost7 {
            postId
            title
            createdAt
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
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Post.self)
        let syncDocument = """
        query SyncPost7s($limit: Int) {
          syncPost7s(limit: $limit) {
            items {
              postId
              title
              createdAt
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
    
    func testCommentSelectionSets() {
        setUpModelRegistrationOnly(withModels: PostComment7Models())
        continueAfterFailure = true
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post: post)
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: comment, modelSchema: Comment.schema)
        let createDocument = """
        mutation CreateComment7($input: CreateComment7Input!) {
          createComment7(input: $input) {
            commentId
            content
            createdAt
            updatedAt
            post {
              postId
              title
              createdAt
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
        mutation UpdateComment7($input: UpdateComment7Input!) {
          updateComment7(input: $input) {
            commentId
            content
            createdAt
            updatedAt
            post {
              postId
              title
              createdAt
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
        mutation DeleteComment7($input: DeleteComment7Input!) {
          deleteComment7(input: $input) {
            commentId
            content
            createdAt
            updatedAt
            post {
              postId
              title
              createdAt
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
        subscription OnCreateComment7 {
          onCreateComment7 {
            commentId
            content
            createdAt
            updatedAt
            post {
              postId
              title
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
        subscription OnUpdateComment7 {
          onUpdateComment7 {
            commentId
            content
            createdAt
            updatedAt
            post {
              postId
              title
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
        subscription OnDeleteComment7 {
          onDeleteComment7 {
            commentId
            content
            createdAt
            updatedAt
            post {
              postId
              title
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
        query SyncComment7s($limit: Int) {
          syncComment7s(limit: $limit) {
            items {
              commentId
              content
              createdAt
              updatedAt
              post {
                postId
                title
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
