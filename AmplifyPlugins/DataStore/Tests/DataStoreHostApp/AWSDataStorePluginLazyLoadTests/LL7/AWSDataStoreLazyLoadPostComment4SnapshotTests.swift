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

extension AWSDataStoreLazyLoadPostComment4Tests {
    
    func testPostSelectionSets() {
        setUpModelRegistrationOnly(withModels: PostComment4Models())
        continueAfterFailure = true
        let post = Post(postId: UUID().uuidString, title: "title")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: post, modelSchema: Post.schema)
        let createDocument = """
        mutation CreatePost4($input: CreatePost4Input!) {
          createPost4(input: $input) {
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
        mutation UpdatePost4($input: UpdatePost4Input!) {
          updatePost4(input: $input) {
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
        mutation DeletePost4($input: DeletePost4Input!) {
          deletePost4(input: $input) {
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
        subscription OnCreatePost4 {
          onCreatePost4 {
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
        subscription OnUpdatePost4 {
          onUpdatePost4 {
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
        subscription OnDeletePost4 {
          onDeletePost4 {
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
        query SyncPost4s($limit: Int) {
          syncPost4s(limit: $limit) {
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
        setUpModelRegistrationOnly(withModels: PostComment4Models())
        continueAfterFailure = true
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: comment, modelSchema: Comment.schema)
        let createDocument = """
        mutation CreateComment4($input: CreateComment4Input!) {
          createComment4(input: $input) {
            commentId
            content
            createdAt
            post4CommentsPostId
            post4CommentsTitle
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
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: comment, modelSchema: Comment.schema)
        let updateDocument = """
        mutation UpdateComment4($input: UpdateComment4Input!) {
          updateComment4(input: $input) {
            commentId
            content
            createdAt
            post4CommentsPostId
            post4CommentsTitle
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
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: comment, modelSchema: Comment.schema)
        let deleteDocument = """
        mutation DeleteComment4($input: DeleteComment4Input!) {
          deleteComment4(input: $input) {
            commentId
            content
            createdAt
            post4CommentsPostId
            post4CommentsTitle
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
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Comment.schema, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateComment4 {
          onCreateComment4 {
            commentId
            content
            createdAt
            post4CommentsPostId
            post4CommentsTitle
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
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Comment.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateComment4 {
          onUpdateComment4 {
            commentId
            content
            createdAt
            post4CommentsPostId
            post4CommentsTitle
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
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Comment.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteComment4 {
          onDeleteComment4 {
            commentId
            content
            createdAt
            post4CommentsPostId
            post4CommentsTitle
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
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Comment.self)
        let syncDocument = """
        query SyncComment4s($limit: Int) {
          syncComment4s(limit: $limit) {
            items {
              commentId
              content
              createdAt
              post4CommentsPostId
              post4CommentsTitle
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
}
