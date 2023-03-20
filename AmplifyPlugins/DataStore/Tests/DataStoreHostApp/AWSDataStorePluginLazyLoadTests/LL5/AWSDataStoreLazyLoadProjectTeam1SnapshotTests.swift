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
@testable import AWSPluginsCore

extension AWSDataStoreLazyLoadProjectTeam1Tests {
    
    func testProjectSelectionSets() {
        setUpModelRegistrationOnly(withModels: ProjectTeam1Models())
        continueAfterFailure = true
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: project, modelSchema: Project.schema)
        let createDocument = """
        mutation CreateProject1($input: CreateProject1Input!) {
          createProject1(input: $input) {
            projectId
            name
            createdAt
            project1TeamName
            project1TeamTeamId
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
        mutation UpdateProject1($input: UpdateProject1Input!) {
          updateProject1(input: $input) {
            projectId
            name
            createdAt
            project1TeamName
            project1TeamTeamId
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
        mutation DeleteProject1($input: DeleteProject1Input!) {
          deleteProject1(input: $input) {
            projectId
            name
            createdAt
            project1TeamName
            project1TeamTeamId
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
        subscription OnCreateProject1 {
          onCreateProject1 {
            projectId
            name
            createdAt
            project1TeamName
            project1TeamTeamId
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
        subscription OnUpdateProject1 {
          onUpdateProject1 {
            projectId
            name
            createdAt
            project1TeamName
            project1TeamTeamId
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
        subscription OnDeleteProject1 {
          onDeleteProject1 {
            projectId
            name
            createdAt
            project1TeamName
            project1TeamTeamId
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
        query SyncProject1s($limit: Int) {
          syncProject1s(limit: $limit) {
            items {
              projectId
              name
              createdAt
              project1TeamName
              project1TeamTeamId
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
        setUpModelRegistrationOnly(withModels: ProjectTeam1Models())
        continueAfterFailure = true
        let team = Team(teamId: UUID().uuidString, name: "name")
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: team, modelSchema: Team.schema)
        let createDocument = """
        mutation CreateTeam1($input: CreateTeam1Input!) {
          createTeam1(input: $input) {
            teamId
            name
            createdAt
            updatedAt
            project {
              projectId
              name
              createdAt
              project1TeamName
              project1TeamTeamId
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
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(of: team, modelSchema: Team.schema)
        let updateDocument = """
        mutation UpdateTeam1($input: UpdateTeam1Input!) {
          updateTeam1(input: $input) {
            teamId
            name
            createdAt
            updatedAt
            project {
              projectId
              name
              createdAt
              project1TeamName
              project1TeamTeamId
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
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(of: team, modelSchema: Team.schema)
        let deleteDocument = """
        mutation DeleteTeam1($input: DeleteTeam1Input!) {
          deleteTeam1(input: $input) {
            teamId
            name
            createdAt
            updatedAt
            project {
              projectId
              name
              createdAt
              project1TeamName
              project1TeamTeamId
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
        let onCreateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Team.schema, subscriptionType: .onCreate)
        let onCreateDocument = """
        subscription OnCreateTeam1 {
          onCreateTeam1 {
            teamId
            name
            createdAt
            updatedAt
            project {
              projectId
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
        let onUpdateRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Team.self, subscriptionType: .onUpdate)
        let onUpdateDocument = """
        subscription OnUpdateTeam1 {
          onUpdateTeam1 {
            teamId
            name
            createdAt
            updatedAt
            project {
              projectId
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
        let onDeleteRequest = GraphQLRequest<MutationSyncResult>.subscription(to: Team.self, subscriptionType: .onDelete)
        let onDeleteDocument = """
        subscription OnDeleteTeam1 {
          onDeleteTeam1 {
            teamId
            name
            createdAt
            updatedAt
            project {
              projectId
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
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Team.self)
        let syncDocument = """
        query SyncTeam1s($limit: Int) {
          syncTeam1s(limit: $limit) {
            items {
              teamId
              name
              createdAt
              updatedAt
              project {
                projectId
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
}
