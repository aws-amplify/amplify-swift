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

extension AWSDataStoreLazyLoadPostComment8Tests {

    func testPostSelectionSets() {
        setUpModelRegistrationOnly(withModels: PostComment8Models())
        continueAfterFailure = true
        let post = Post(postId: UUID().uuidString, title: "title")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: post, modelSchema: Post.schema)
        let createDocument = """
        mutation CreatePost8($input: CreatePost8Input!) {
          createPost8(input: $input) {
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
        mutation UpdatePost8($input: UpdatePost8Input!) {
          updatePost8(input: $input) {
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
        mutation DeletePost8($input: DeletePost8Input!) {
          deletePost8(input: $input) {
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
        subscription OnCreatePost8 {
          onCreatePost8 {
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
        subscription OnUpdatePost8 {
          onUpdatePost8 {
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
        subscription OnDeletePost8 {
          onDeletePost8 {
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
        query SyncPost8s($limit: Int) {
          syncPost8s(limit: $limit) {
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
        setUpModelRegistrationOnly(withModels: PostComment8Models())
        continueAfterFailure = true
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: comment, modelSchema: Comment.schema)
        let createDocument = """
        mutation CreateComment8($input: CreateComment8Input!) {
          createComment8(input: $input) {
            commentId
            content
            createdAt
            postId
            postTitle
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
        mutation UpdateComment8($input: UpdateComment8Input!) {
          updateComment8(input: $input) {
            commentId
            content
            createdAt
            postId
            postTitle
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
        mutation DeleteComment8($input: DeleteComment8Input!) {
          deleteComment8(input: $input) {
            commentId
            content
            createdAt
            postId
            postTitle
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
        subscription OnCreateComment8 {
          onCreateComment8 {
            commentId
            content
            createdAt
            postId
            postTitle
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
        subscription OnUpdateComment8 {
          onUpdateComment8 {
            commentId
            content
            createdAt
            postId
            postTitle
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
        subscription OnDeleteComment8 {
          onDeleteComment8 {
            commentId
            content
            createdAt
            postId
            postTitle
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
        query SyncComment8s($limit: Int) {
          syncComment8s(limit: $limit) {
            items {
              commentId
              content
              createdAt
              postId
              postTitle
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
