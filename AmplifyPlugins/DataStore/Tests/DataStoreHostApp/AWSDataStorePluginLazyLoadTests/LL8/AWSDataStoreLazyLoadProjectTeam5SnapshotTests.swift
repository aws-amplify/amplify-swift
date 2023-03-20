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

extension AWSDataStoreLazyLoadProjectTeam5Tests {
    
    func testProjectSelectionSets() {
        setUpModelRegistrationOnly(withModels: ProjectTeam5Models())
        continueAfterFailure = true
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: project, modelSchema: Project.schema)
        let createDocument = """
        mutation CreateProject5($input: CreateProject5Input!) {
          createProject5(input: $input) {
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
        mutation UpdateProject5($input: UpdateProject5Input!) {
          updateProject5(input: $input) {
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
        mutation DeleteProject5($input: DeleteProject5Input!) {
          deleteProject5(input: $input) {
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
        subscription OnCreateProject5 {
          onCreateProject5 {
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
        subscription OnUpdateProject5 {
          onUpdateProject5 {
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
        subscription OnDeleteProject5 {
          onDeleteProject5 {
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
        query SyncProject5s($limit: Int) {
          syncProject5s(limit: $limit) {
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
        setUpModelRegistrationOnly(withModels: ProjectTeam5Models())
        continueAfterFailure = true
        let team = Team(teamId: UUID().uuidString, name: "name")
        
        // Create
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: team, modelSchema: Team.schema)
        let createDocument = """
        mutation CreateTeam5($input: CreateTeam5Input!) {
          createTeam5(input: $input) {
            teamId
            name
            createdAt
            updatedAt
            project {
              projectId
              name
              createdAt
              teamId
              teamName
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
        mutation UpdateTeam5($input: UpdateTeam5Input!) {
          updateTeam5(input: $input) {
            teamId
            name
            createdAt
            updatedAt
            project {
              projectId
              name
              createdAt
              teamId
              teamName
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
        mutation DeleteTeam5($input: DeleteTeam5Input!) {
          deleteTeam5(input: $input) {
            teamId
            name
            createdAt
            updatedAt
            project {
              projectId
              name
              createdAt
              teamId
              teamName
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
        subscription OnCreateTeam5 {
          onCreateTeam5 {
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
        subscription OnUpdateTeam5 {
          onUpdateTeam5 {
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
        subscription OnDeleteTeam5 {
          onDeleteTeam5 {
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
        query SyncTeam5s($limit: Int) {
          syncTeam5s(limit: $limit) {
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
