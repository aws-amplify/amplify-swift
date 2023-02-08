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
        await setup(withModels: ProjectTeam2Models())
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
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        try await assertModelExists(savedTeam)
    }
    
    func testSaveProject() async throws {
        await setup(withModels: ProjectTeam2Models())
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        let savedProject = try await saveAndWaitForSync(project)
        try await assertModelExists(savedProject)
        assertProjectDoesNotContainTeam(savedProject)
    }
    
    func testSaveProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        
        // Project initializer variation #1 (pass both team reference and fields in)
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team,
                              project2TeamTeamId: team.teamId,
                              project2TeamName: team.name)
        let savedProject = try await saveAndWaitForSync(project)
        let queriedProject = try await query(for: savedProject)
        assertProject(queriedProject, hasTeam: savedTeam)
        
        // Project initializer variation #2 (pass only team reference)
        let project2 = Project(projectId: UUID().uuidString,
                               name: "name",
                               team: team)
        let savedProject2 = try await saveAndWaitForSync(project2)
        let queriedProject2 = try await query(for: savedProject2)
        assertProjectDoesNotContainTeam(queriedProject2)
        
        // Project initializer variation #3 (pass fields in)
        let project3 = Project(projectId: UUID().uuidString,
                               name: "name",
                               project2TeamTeamId: team.teamId,
                               project2TeamName: team.name)
        let savedProject3 = try await saveAndWaitForSync(project3)
        let queriedProject3 = try await query(for: savedProject3)
        assertProject(queriedProject3, hasTeam: savedTeam)
    }
    
    // One-to-One relationships do not create a foreign key for the Team or Project table
    // So the LazyModel does not have the FK value to be instantiated as metadata for lazy loading.
    // We only assert the FK fields on the Project exist and are equal to the Team's PK.
    func assertProject(_ project: Project, hasTeam team: Team) {
        XCTAssertEqual(project.project2TeamTeamId, team.teamId)
        XCTAssertEqual(project.project2TeamName, team.name)
    }
    
    func assertProjectDoesNotContainTeam(_ project: Project) {
        XCTAssertNil(project.project2TeamTeamId)
        XCTAssertNil(project.project2TeamName)
    }
    
    func testSaveProjectWithTeamThenUpdate() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
    
        let project = initializeProjectWithTeam(team)
        let savedProject = try await saveAndWaitForSync(project)
        assertProject(savedProject, hasTeam: savedTeam)
        let queriedProject = try await query(for: savedProject)
        assertProject(queriedProject, hasTeam: savedTeam)
        let updatedProject = try await saveAndWaitForSync(project, assertVersion: 2)
        assertProject(updatedProject, hasTeam: savedTeam)
    }
    
    func testSaveProjectWithoutTeamUpdateProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await saveAndWaitForSync(project)
        assertProjectDoesNotContainTeam(savedProject)
        
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        var queriedProject = try await query(for: savedProject)
        queriedProject.project2TeamTeamId = team.teamId
        queriedProject.project2TeamName = team.name
        let savedProjectWithNewTeam = try await saveAndWaitForSync(queriedProject, assertVersion: 2)
        assertProject(savedProjectWithNewTeam, hasTeam: savedTeam)
    }
    
    func testSaveTeamSaveProjectWithTeamUpdateProjectToNoTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = initializeProjectWithTeam(team)
        let savedProject = try await saveAndWaitForSync(project)
        var queriedProject = try await query(for: savedProject)
        assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.project2TeamTeamId = nil
        queriedProject.project2TeamName = nil
        let savedProjectWithNoTeam = try await saveAndWaitForSync(queriedProject, assertVersion: 2)
        assertProjectDoesNotContainTeam(savedProjectWithNoTeam)
    }
    
    func testSaveProjectWithTeamUpdateProjectToNewTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = initializeProjectWithTeam(team)
        let savedProject = try await saveAndWaitForSync(project)
        let newTeam = Team(teamId: UUID().uuidString, name: "name")
        let savedNewTeam = try await saveAndWaitForSync(newTeam)
        var queriedProject = try await query(for: savedProject)
        assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.project2TeamTeamId = newTeam.teamId
        queriedProject.project2TeamName = newTeam.name
        let savedProjectWithNewTeam = try await saveAndWaitForSync(queriedProject, assertVersion: 2)
        assertProject(queriedProject, hasTeam: savedNewTeam)
    }
    
    func testDeleteTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        try await assertModelExists(savedTeam)
        try await deleteAndWaitForSync(savedTeam)
        try await assertModelDoesNotExist(savedTeam)
    }
    
    func testDeleteProject() async throws {
        await setup(withModels: ProjectTeam2Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await saveAndWaitForSync(project)
        try await assertModelExists(savedProject)
        try await deleteAndWaitForSync(savedProject)
        try await assertModelDoesNotExist(savedProject)
    }
    
    func testDeleteProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = initializeProjectWithTeam(team)
        let savedProject = try await saveAndWaitForSync(project)
        
        try await assertModelExists(savedProject)
        try await assertModelExists(savedTeam)
        
        try await deleteAndWaitForSync(savedProject)
        
        try await assertModelDoesNotExist(savedProject)
        try await assertModelExists(savedTeam)
        
        try await deleteAndWaitForSync(savedTeam)
        try await assertModelDoesNotExist(savedTeam)
    }
    
    func testObserveProject() async throws {
        await setup(withModels: ProjectTeam2Models())
        try await startAndWaitForReady()
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = initializeProjectWithTeam(team)
        
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Project.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedProject = try? mutationEvent.decodeModel(as: Project.self),
                   receivedProject.projectId == project.projectId {
                    assertProject(receivedProject, hasTeam: savedTeam)
                    await mutationEventReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: project, modelSchema: Project.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        try await startAndWaitForReady()
        let team = Team(teamId: UUID().uuidString, name: "name")
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Team.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedTeam = try? mutationEvent.decodeModel(as: Team.self),
                   receivedTeam.teamId == team.teamId {
                        
                    await mutationEventReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: team, modelSchema: Team.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
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
    
    func initializeProjectWithTeam(_ team: Team) -> Project {
        return Project(projectId: UUID().uuidString,
                       name: "name",
                       team: team,
                       project2TeamTeamId: team.teamId,
                       project2TeamName: team.name)
    }
}
