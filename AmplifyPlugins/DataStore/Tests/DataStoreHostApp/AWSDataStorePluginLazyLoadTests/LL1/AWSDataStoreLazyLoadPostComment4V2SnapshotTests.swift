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

extension AWSDataStoreLazyLoadPostComment4V2Tests {
 
    func testPostSelectionSets() async throws {
        await setup(withModels: PostComment4V2Models(), eagerLoad: false, clearOnTearDown: false)
        continueAfterFailure = true
        let post = Post(title: "title")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: post, modelSchema: Post.schema)
        let createDocument = """
        mutation CreatePost4V2($input: CreatePost4V2Input!) {
          createPost4V2(input: $input) {
            id
            createdAt
            title
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
        mutation UpdatePost4V2($input: UpdatePost4V2Input!) {
          updatePost4V2(input: $input) {
            id
            createdAt
            title
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
        mutation DeletePost4V2($input: DeletePost4V2Input!) {
          deletePost4V2(input: $input) {
            id
            createdAt
            title
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
        subscription OnCreatePost4V2 {
          onCreatePost4V2 {
            id
            createdAt
            title
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
        subscription OnUpdatePost4V2 {
          onUpdatePost4V2 {
            id
            createdAt
            title
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
        subscription OnDeletePost4V2 {
          onDeletePost4V2 {
            id
            createdAt
            title
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
        query SyncPost4V2s($limit: Int) {
          syncPost4V2s(limit: $limit) {
            items {
              id
              createdAt
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
        XCTAssertEqual(syncRequest.document, syncDocument)
    }
    
    func testCommentSelectionSets() async throws {
        await setup(withModels: PostComment4V2Models(), eagerLoad: false, clearOnTearDown: false)
        continueAfterFailure = true
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: comment, modelSchema: Comment.schema)
        let createDocument = """
        mutation CreateComment4V2($input: CreateComment4V2Input!) {
          createComment4V2(input: $input) {
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
        mutation UpdateComment4V2($input: UpdateComment4V2Input!) {
          updateComment4V2(input: $input) {
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
        mutation DeleteComment4V2($input: DeleteComment4V2Input!) {
          deleteComment4V2(input: $input) {
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
        subscription OnCreateComment4V2 {
          onCreateComment4V2 {
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
        subscription OnUpdateComment4V2 {
          onUpdateComment4V2 {
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
        subscription OnDeleteComment4V2 {
          onDeleteComment4V2 {
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
        query SyncComment4V2s($limit: Int) {
          syncComment4V2s(limit: $limit) {
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
