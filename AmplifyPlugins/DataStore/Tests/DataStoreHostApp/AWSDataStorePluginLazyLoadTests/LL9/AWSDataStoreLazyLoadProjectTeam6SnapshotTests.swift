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

extension AWSDataStoreLazyLoadProjectTeam6Tests {
    
    func testProjectSelectionSets() {
        setUpModelRegistrationOnly(withModels: ProjectTeam6Models())
        continueAfterFailure = true
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: project, modelSchema: Project.schema)
        let createDocument = """
        mutation CreateProject6($input: CreateProject6Input!) {
          createProject6(input: $input) {
            projectId
            name
            createdAt
            teamId
            teamName
            updatedAt
            team {
              teamId
              name
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
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: project, modelSchema: Project.schema)
        let updateDocument = """
        mutation UpdateProject6($input: UpdateProject6Input!) {
          updateProject6(input: $input) {
            projectId
            name
            createdAt
            teamId
            teamName
            updatedAt
            team {
              teamId
              name
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
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: project, modelSchema: Project.schema)
        let deleteDocument = """
        mutation DeleteProject6($input: DeleteProject6Input!) {
          deleteProject6(input: $input) {
            projectId
            name
            createdAt
            teamId
            teamName
            updatedAt
            team {
              teamId
              name
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
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Project.self, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateProject6 {
          onCreateProject6 {
            projectId
            name
            createdAt
            teamId
            teamName
            updatedAt
            team {
              teamId
              name
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
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Project.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateProject6 {
          onUpdateProject6 {
            projectId
            name
            createdAt
            teamId
            teamName
            updatedAt
            team {
              teamId
              name
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
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Project.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteProject6 {
          onDeleteProject6 {
            projectId
            name
            createdAt
            teamId
            teamName
            updatedAt
            team {
              teamId
              name
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
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Project.self)
        let syncDocument = """
        query SyncProject6s($limit: Int) {
          syncProject6s(limit: $limit) {
            items {
              projectId
              name
              createdAt
              teamId
              teamName
              updatedAt
              team {
                teamId
                name
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
    
    func testTeamSelectionSets() {
        setUpModelRegistrationOnly(withModels: ProjectTeam6Models())
        continueAfterFailure = true
        let team = Team(teamId: UUID().uuidString, name: "name")
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: team, modelSchema: Team.schema)
        let createDocument = """
        mutation CreateTeam6($input: CreateTeam6Input!) {
          createTeam6(input: $input) {
            teamId
            name
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
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: team, modelSchema: Team.schema)
        let updateDocument = """
        mutation UpdateTeam6($input: UpdateTeam6Input!) {
          updateTeam6(input: $input) {
            teamId
            name
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
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: team, modelSchema: Team.schema)
        let deleteDocument = """
        mutation DeleteTeam6($input: DeleteTeam6Input!) {
          deleteTeam6(input: $input) {
            teamId
            name
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
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Team.schema, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateTeam6 {
          onCreateTeam6 {
            teamId
            name
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
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Team.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateTeam6 {
          onUpdateTeam6 {
            teamId
            name
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
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Team.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteTeam6 {
          onDeleteTeam6 {
            teamId
            name
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
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Team.self)
        let syncDocument = """
        query SyncTeam6s($limit: Int) {
          syncTeam6s(limit: $limit) {
            items {
              teamId
              name
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
