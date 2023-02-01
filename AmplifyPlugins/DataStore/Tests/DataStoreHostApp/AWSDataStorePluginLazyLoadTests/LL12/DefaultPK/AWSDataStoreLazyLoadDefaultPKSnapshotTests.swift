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

extension AWSDataStoreLazyLoadDefaultPKTests {
    
    func testParentSelectionSets() {
        setUpModelRegistrationOnly(withModels: DefaultPKModels())
        continueAfterFailure = true
        let parent = Parent()
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: parent, modelSchema: Parent.schema)
        let createDocument = """
        mutation CreateDefaultPKParent($input: CreateDefaultPKParentInput!) {
          createDefaultPKParent(input: $input) {
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
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: parent, modelSchema: Parent.schema)
        let updateDocument = """
        mutation UpdateDefaultPKParent($input: UpdateDefaultPKParentInput!) {
          updateDefaultPKParent(input: $input) {
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
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: parent, modelSchema: Parent.schema)
        let deleteDocument = """
        mutation DeleteDefaultPKParent($input: DeleteDefaultPKParentInput!) {
          deleteDefaultPKParent(input: $input) {
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
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Parent.self, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateDefaultPKParent {
          onCreateDefaultPKParent {
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
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Parent.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateDefaultPKParent {
          onUpdateDefaultPKParent {
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
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Parent.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteDefaultPKParent {
          onDeleteDefaultPKParent {
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
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Parent.self)
        let syncDocument = """
        query SyncDefaultPKParents($limit: Int) {
          syncDefaultPKParents(limit: $limit) {
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
    
    func testChildSelectionSets() {
        setUpModelRegistrationOnly(withModels: DefaultPKModels())
        continueAfterFailure = true
        let parent = Parent()
        let child = Child(parent: parent)
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: child, modelSchema: Child.schema)
        let createDocument = """
        mutation CreateDefaultPKChild($input: CreateDefaultPKChildInput!) {
          createDefaultPKChild(input: $input) {
            id
            content
            createdAt
            updatedAt
            parent {
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
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: child, modelSchema: Child.schema)
        let updateDocument = """
        mutation UpdateDefaultPKChild($input: UpdateDefaultPKChildInput!) {
          updateDefaultPKChild(input: $input) {
            id
            content
            createdAt
            updatedAt
            parent {
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
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: child, modelSchema: Child.schema)
        let deleteDocument = """
        mutation DeleteDefaultPKChild($input: DeleteDefaultPKChildInput!) {
          deleteDefaultPKChild(input: $input) {
            id
            content
            createdAt
            updatedAt
            parent {
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
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Child.schema, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateDefaultPKChild {
          onCreateDefaultPKChild {
            id
            content
            createdAt
            updatedAt
            parent {
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
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Child.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateDefaultPKChild {
          onUpdateDefaultPKChild {
            id
            content
            createdAt
            updatedAt
            parent {
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
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Child.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteDefaultPKChild {
          onDeleteDefaultPKChild {
            id
            content
            createdAt
            updatedAt
            parent {
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
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Child.self)
        let syncDocument = """
        query SyncDefaultPKChildren($limit: Int) {
          syncDefaultPKChildren(limit: $limit) {
            items {
              id
              content
              createdAt
              updatedAt
              parent {
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

