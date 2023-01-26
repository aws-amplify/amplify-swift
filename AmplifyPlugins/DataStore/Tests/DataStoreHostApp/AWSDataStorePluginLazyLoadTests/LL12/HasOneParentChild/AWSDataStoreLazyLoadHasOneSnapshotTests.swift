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

extension AWSDataStoreLazyLoadHasOneTests {
    
    func testHasOneParentSelectionSets() {
        setUpModelRegistrationOnly(withModels: HasOneModels())
        continueAfterFailure = true
        let child = HasOneChild()
        let parent = HasOneParent(child: child, hasOneParentChildId: child.id)
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: parent, modelSchema: HasOneParent.schema)
        let createDocument = """
        mutation CreateHasOneParent($input: CreateHasOneParentInput!) {
          createHasOneParent(input: $input) {
            id
            createdAt
            hasOneParentChildId
            updatedAt
            child {
              id
              content
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
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: parent, modelSchema: HasOneParent.schema)
        let updateDocument = """
        mutation UpdateHasOneParent($input: UpdateHasOneParentInput!) {
          updateHasOneParent(input: $input) {
            id
            createdAt
            hasOneParentChildId
            updatedAt
            child {
              id
              content
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
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: parent, modelSchema: HasOneParent.schema)
        let deleteDocument = """
        mutation DeleteHasOneParent($input: DeleteHasOneParentInput!) {
          deleteHasOneParent(input: $input) {
            id
            createdAt
            hasOneParentChildId
            updatedAt
            child {
              id
              content
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
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: HasOneParent.self, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateHasOneParent {
          onCreateHasOneParent {
            id
            createdAt
            hasOneParentChildId
            updatedAt
            child {
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
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: HasOneParent.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateHasOneParent {
          onUpdateHasOneParent {
            id
            createdAt
            hasOneParentChildId
            updatedAt
            child {
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
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: HasOneParent.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteHasOneParent {
          onDeleteHasOneParent {
            id
            createdAt
            hasOneParentChildId
            updatedAt
            child {
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
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: HasOneParent.self)
        let syncDocument = """
        query SyncHasOneParents($limit: Int) {
          syncHasOneParents(limit: $limit) {
            items {
              id
              createdAt
              hasOneParentChildId
              updatedAt
              child {
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
    
    func testHasOneChildSelectionSets() {
        setUpModelRegistrationOnly(withModels: HasOneModels())
        continueAfterFailure = true
        let child = HasOneChild()
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: child, modelSchema: HasOneChild.schema)
        let createDocument = """
        mutation CreateHasOneChild($input: CreateHasOneChildInput!) {
          createHasOneChild(input: $input) {
            id
            content
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
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: child, modelSchema: HasOneChild.schema)
        let updateDocument = """
        mutation UpdateHasOneChild($input: UpdateHasOneChildInput!) {
          updateHasOneChild(input: $input) {
            id
            content
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
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: child, modelSchema: HasOneChild.schema)
        let deleteDocument = """
        mutation DeleteHasOneChild($input: DeleteHasOneChildInput!) {
          deleteHasOneChild(input: $input) {
            id
            content
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
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: HasOneChild.schema, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateHasOneChild {
          onCreateHasOneChild {
            id
            content
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
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: HasOneChild.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateHasOneChild {
          onUpdateHasOneChild {
            id
            content
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
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: HasOneChild.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteHasOneChild {
          onDeleteHasOneChild {
            id
            content
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
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: HasOneChild.self)
        let syncDocument = """
        query SyncHasOneChildren($limit: Int) {
          syncHasOneChildren(limit: $limit) {
            items {
              id
              content
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
}
