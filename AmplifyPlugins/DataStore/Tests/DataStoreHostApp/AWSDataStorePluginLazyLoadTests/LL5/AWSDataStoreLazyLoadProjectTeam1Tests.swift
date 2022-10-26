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

class AWSDataStoreLazyLoadProjectTeam1Tests: AWSDataStoreLazyLoadBaseTest {
    
    func testAPISyncQuery() async throws {
        await setupAPIOnly(withModels: ProjectTeam1Models())
    
        // The selection set of project should include "hasOne" team, and no further
        let projectRequest = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: Project.self)
        let projectDocument = """
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
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(projectRequest.document, projectDocument)
        
        // The selection set of team should include "belongsTo" project, and no further.
        let teamRequest = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: Team.self)
        let teamDocument = """
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
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(teamRequest.document, teamDocument)
        // Making the actual requests and ensuring they can decode to the Model types.
        _ = try await Amplify.API.query(request: projectRequest)
        _ = try await Amplify.API.query(request: teamRequest)
    }
    
    func testSaveTeam() async throws {
        await setup(withModels: ProjectTeam1Models(), eagerLoad: false)
        let team = Team1(teamId: UUID().uuidString, name: "name")
        let project = Project1(projectId: UUID().uuidString,
                               name: "name",
                               team: team,
                               project1TeamTeamId: team.teamId,
                               project1TeamName: team.name)
        
        let savedTeam = try await saveAndWaitForSync(team)
        let savedProject = try await saveAndWaitForSync(project)
    }
}

extension AWSDataStoreLazyLoadProjectTeam1Tests {
    typealias Project = Project1
    typealias Team = Team1
    
    struct ProjectTeam1Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Project1.self)
            ModelRegistry.register(modelType: Team1.self)
        }
    }
}
