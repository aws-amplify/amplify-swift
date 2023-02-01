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

class AWSDataStoreLazyLoadProjectTeam5Tests: AWSDataStoreLazyLoadBaseTest {
    
    func testStart() async throws {
        await setup(withModels: ProjectTeam5Models())
        try await startAndWaitForReady()
        printDBPath()
    }
    
    func testSaveTeam() async throws {
        await setup(withModels: ProjectTeam5Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        try await assertModelExists(savedTeam)
    }
    
    func testSaveProject() async throws {
        await setup(withModels: ProjectTeam5Models())
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        let savedProject = try await saveAndWaitForSync(project)
        try await assertModelExists(savedProject)
        assertProjectDoesNotContainTeam(savedProject)
    }
    
    func testSaveProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam5Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        
        // Project initializer variation #1 (pass both team reference and fields in)
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team,
                              teamId: team.teamId,
                              teamName: team.name)
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
                               teamId: team.teamId,
                               teamName: team.name)
        let savedProject3 = try await saveAndWaitForSync(project3)
        let queriedProject3 = try await query(for: savedProject3)
        assertProject(queriedProject3, hasTeam: savedTeam)
    }
    
    // One-to-One relationships do not create a foreign key for the Team or Project table
    // So the LazyModel does not have the FK value to be instantiated as metadata for lazy loading.
    // We only assert the FK fields on the Project exist and are equal to the Team's PK.
    func assertProject(_ project: Project, hasTeam team: Team) {
        XCTAssertEqual(project.teamId, team.teamId)
        XCTAssertEqual(project.teamName, team.name)
    }
    
    func assertProjectDoesNotContainTeam(_ project: Project) {
        XCTAssertNil(project.teamId)
        XCTAssertNil(project.teamName)
    }
    
    func testSaveProjectWithTeamThenUpdate() async throws {
        await setup(withModels: ProjectTeam5Models())
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
        await setup(withModels: ProjectTeam5Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await saveAndWaitForSync(project)
        assertProjectDoesNotContainTeam(savedProject)
        
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        var queriedProject = try await query(for: savedProject)
        queriedProject.teamId = team.teamId
        queriedProject.teamName = team.name
        let savedProjectWithNewTeam = try await saveAndWaitForSync(queriedProject, assertVersion: 2)
        assertProject(savedProjectWithNewTeam, hasTeam: savedTeam)
    }
    
    func testSaveTeamSaveProjectWithTeamUpdateProjectToNoTeam() async throws {
        await setup(withModels: ProjectTeam5Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = initializeProjectWithTeam(team)
        let savedProject = try await saveAndWaitForSync(project)
        var queriedProject = try await query(for: savedProject)
        assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.teamId = nil
        queriedProject.teamName = nil
        let savedProjectWithNoTeam = try await saveAndWaitForSync(queriedProject, assertVersion: 2)
        assertProjectDoesNotContainTeam(savedProjectWithNoTeam)
    }
    
    func testSaveProjectWithTeamUpdateProjectToNewTeam() async throws {
        await setup(withModels: ProjectTeam5Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = initializeProjectWithTeam(team)
        let savedProject = try await saveAndWaitForSync(project)
        let newTeam = Team(teamId: UUID().uuidString, name: "name")
        let savedNewTeam = try await saveAndWaitForSync(newTeam)
        var queriedProject = try await query(for: savedProject)
        assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.teamId = newTeam.teamId
        queriedProject.teamName = newTeam.name
        let savedProjectWithNewTeam = try await saveAndWaitForSync(queriedProject, assertVersion: 2)
        assertProject(queriedProject, hasTeam: savedNewTeam)
    }
    
    func testDeleteTeam() async throws {
        await setup(withModels: ProjectTeam5Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        try await assertModelExists(savedTeam)
        try await deleteAndWaitForSync(savedTeam)
        try await assertModelDoesNotExist(savedTeam)
    }
    
    func testDeleteProject() async throws {
        await setup(withModels: ProjectTeam5Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await saveAndWaitForSync(project)
        try await assertModelExists(savedProject)
        try await deleteAndWaitForSync(savedProject)
        try await assertModelDoesNotExist(savedProject)
    }
    
    func testDeleteProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam5Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team,
                              teamId: team.teamId,
                              teamName: team.name)
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
        await setup(withModels: ProjectTeam5Models())
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
        await setup(withModels: ProjectTeam5Models())
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
    
    func testObserveQueryProject() async throws {
        await setup(withModels: ProjectTeam5Models())
        try await startAndWaitForReady()
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        let project = initializeProjectWithTeam(team)
        
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Project.self, where: Project.keys.projectId == project.projectId)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedProject = querySnapshot.items.first {
                    assertProject(receivedProject, hasTeam: savedTeam)
                    await snapshotReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: project, modelSchema: Project.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([snapshotReceived], timeout: 60)
        querySnapshots.cancel()
    }
    
    func testObserveQueryTeam() async throws {
        await setup(withModels: ProjectTeam5Models())
        try await startAndWaitForReady()
        let team = Team(teamId: UUID().uuidString, name: "name")
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Team.self, where: Team.keys.teamId == team.teamId)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedTeam = querySnapshot.items.first {
                    XCTAssertEqual(receivedTeam.teamId, team.teamId)
                    await snapshotReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: team, modelSchema: Team.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([snapshotReceived], timeout: 60)
        querySnapshots.cancel()
    }
}

extension AWSDataStoreLazyLoadProjectTeam5Tests {
    
    typealias Project = Project5
    typealias Team = Team5
    
    struct ProjectTeam5Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Project5.self)
            ModelRegistry.register(modelType: Team5.self)
        }
    }
    
    func initializeProjectWithTeam(_ team: Team) -> Project {
        return Project(projectId: UUID().uuidString,
                       name: "name",
                       team: team,
                       teamId: team.teamId,
                       teamName: team.name)
    }
}
