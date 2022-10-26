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

class AWSDataStoreLazyLoadProjectTeam2Tests: AWSDataStoreLazyLoadBaseTest {
    
    func testStart() async throws {
        await setup(withModels: ProjectTeam2Models(), eagerLoad: false, clearOnTearDown: false)
        try await startAndWaitForReady()
        printDBPath()
    }
    
    func testAPISyncQuery() async throws {
        await setupAPIOnly(withModels: ProjectTeam2Models())
    
        // The selection set of project should include "hasOne" team, and no further
        let projectRequest = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: Project.self)
        let projectDocument = """
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
        
        // In this "Implicit Uni-directional Has One", only project hasOne team, team does not reference the project
        // So, the selection set of team does not include project
        let teamRequest = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: Team.self)
        let teamDocument = """
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
        XCTAssertEqual(teamRequest.document, teamDocument)
        // Making the actual requests and ensuring they can decode to the Model types.
        _ = try await Amplify.API.query(request: projectRequest)
        _ = try await Amplify.API.query(request: teamRequest)
    }
    
    func testSaveTeam() async throws {
        await setup(withModels: ProjectTeam2Models(), eagerLoad: false)
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        try await assertModelExists(savedTeam)
    }
    
    func testSaveProject() async throws {
        await setup(withModels: ProjectTeam2Models(), eagerLoad: false)
        
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        let savedProject = try await saveAndWaitForSync(project)
        try await assertModelExists(savedProject)
        assertLazyModel(savedProject._team, state: .notLoaded(identifiers: nil))
    }
    
    func testSaveProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam2Models(), eagerLoad: false)
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
    
//        let project = Project(projectId: UUID().uuidString,
//                              name: "name",
//                              team: team,
//                              project2TeamTeamId: team.teamId,
//                              project2TeamName: team.name)
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team)
        let savedProject = try await saveAndWaitForSync(project)
        switch savedProject._team.modelProvider.getState() {
        case .notLoaded:
            print("Not LOADED - should be loaded")
        case .loaded:
            print("LOADED")
        }
        printDBPath()
        // try await assertProject(savedProject, hasEagerLoaded: savedTeam)
        
//        let queriedProject = try await query(for: savedProject)
//        switch queriedProject._team.modelProvider.getState() {
//        case .notLoaded:
//            print("Not LOADED")
//        case .loaded:
//            print("LOADED")
//        }
        
        // TODO: why is this eager loaded?
        //try await assertProject(queriedProject, hasEagerLoaded: savedTeam)
        //try await assertProject(queriedProject, canLazyLoad: savedTeam)
    }
    
    func assertProject(_ project: Project, hasEagerLoaded team: Team) async throws {
        assertLazyModel(project._team,
                        state: .loaded(model: team))
    }
    
    func assertProject(_ project: Project, canLazyLoad team: Team) async throws {
        assertLazyModel(project._team,
                        state: .notLoaded(identifiers: ["@@primaryKey": team.identifier]))
//        guard let loadedTeam = try await project.team else {
//            XCTFail("Failed to load the team from the project")
//            return
//        }
//        XCTAssertEqual(loadedTeam.identifier, team.identifier)
//        assertLazyModel(project._team,
//                        state: .loaded(model: team))
    }
    
    func testSaveProjectWithTeamThenUpdate() async throws {
        await setup(withModels: ProjectTeam2Models(), eagerLoad: false)
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
    
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team)
        let savedProject = try await saveAndWaitForSync(project)
        let queriedProject = try await query(for: savedProject)
        let updatedProject = try await saveAndWaitForSync(project, assertVersion: 2)
        // TODO: why is this eager loaded?
        try await assertProject(queriedProject, hasEagerLoaded: savedTeam)
        //try await assertProject(queriedProject, canLazyLoad: savedTeam)
    }
    
    func testSaveProjectWithoutTeamUpdateProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam2Models(), eagerLoad: false)
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await saveAndWaitForSync(project)
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        var queriedProject = try await query(for: savedProject)
        queriedProject.setTeam(team)
        let savedProjectWithNewTeam = try await saveAndWaitForSync(project, assertVersion: 2)
        
        // TODO: why is this eager loaded?
        try await assertProject(queriedProject, hasEagerLoaded: savedTeam)
        //try await assertProject(queriedProject, canLazyLoad: savedTeam)
    }
    
    func testSaveTeamSaveProjectWithTeamUpdateProjectToNoTeam() async throws {
        await setup(withModels: ProjectTeam2Models(), eagerLoad: false)
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team)
        let savedProject = try await saveAndWaitForSync(project)
        var queriedProject = try await query(for: savedProject)
        queriedProject.setTeam(nil)
        let savedProjectWithNewTeam = try await saveAndWaitForSync(queriedProject, assertVersion: 2)
        assertLazyModel(project._team, state: .notLoaded(identifiers: nil))
    }
    
    func testSaveProjectWithTeamUpdateProjectToNewTeam() async throws {
        await setup(withModels: ProjectTeam2Models(), eagerLoad: false)
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team)
        let savedProject = try await saveAndWaitForSync(project)
        let newTeam = Team(teamId: UUID().uuidString, name: "name")
        let savedNewTeam = try await saveAndWaitForSync(newTeam)
        var queriedProject = try await query(for: savedProject)
        queriedProject.setTeam(newTeam)
        let savedProjectWithNewTeam = try await saveAndWaitForSync(queriedProject, assertVersion: 2)
        assertLazyModel(project._team, state: .notLoaded(identifiers: nil))
    }
    
    
}

extension AWSDataStoreLazyLoadProjectTeam2Tests {
    
    typealias Project = Project2
    typealias Team = Team2
    
    struct ProjectTeam2Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Project2.self)
            ModelRegistry.register(modelType: Team2.self)
        }
    }
}
