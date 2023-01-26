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

extension AWSDataStoreLazyLoadProjectTeam2Tests {
    
    func testProjectSelectionSets() {
        setUpModelRegistrationOnly(withModels: ProjectTeam2Models())
        continueAfterFailure = true
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: project, modelSchema: Project.schema)
        let createDocument = """
        mutation CreateProject2($input: CreateProject2Input!) {
          createProject2(input: $input) {
            projectId
            name
            createdAt
            project2TeamName
            project2TeamTeamId
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
        mutation UpdateProject2($input: UpdateProject2Input!) {
          updateProject2(input: $input) {
            projectId
            name
            createdAt
            project2TeamName
            project2TeamTeamId
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
        mutation DeleteProject2($input: DeleteProject2Input!) {
          deleteProject2(input: $input) {
            projectId
            name
            createdAt
            project2TeamName
            project2TeamTeamId
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
        subscription OnCreateProject2 {
          onCreateProject2 {
            projectId
            name
            createdAt
            project2TeamName
            project2TeamTeamId
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
        subscription OnUpdateProject2 {
          onUpdateProject2 {
            projectId
            name
            createdAt
            project2TeamName
            project2TeamTeamId
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
        subscription OnDeleteProject2 {
          onDeleteProject2 {
            projectId
            name
            createdAt
            project2TeamName
            project2TeamTeamId
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
        query SyncProject2s($limit: Int) {
          syncProject2s(limit: $limit) {
            items {
              projectId
              name
              createdAt
              project2TeamName
              project2TeamTeamId
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
        setUpModelRegistrationOnly(withModels: ProjectTeam2Models())
        continueAfterFailure = true
        let team = Team(teamId: UUID().uuidString, name: "name")
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: team, modelSchema: Team.schema)
        let createDocument = """
        mutation CreateTeam2($input: CreateTeam2Input!) {
          createTeam2(input: $input) {
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
        mutation UpdateTeam2($input: UpdateTeam2Input!) {
          updateTeam2(input: $input) {
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
        mutation DeleteTeam2($input: DeleteTeam2Input!) {
          deleteTeam2(input: $input) {
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
        subscription OnCreateTeam2 {
          onCreateTeam2 {
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
        subscription OnUpdateTeam2 {
          onUpdateTeam2 {
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
        subscription OnDeleteTeam2 {
          onDeleteTeam2 {
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
        query SyncTeam2s($limit: Int) {
          syncTeam2s(limit: $limit) {
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
