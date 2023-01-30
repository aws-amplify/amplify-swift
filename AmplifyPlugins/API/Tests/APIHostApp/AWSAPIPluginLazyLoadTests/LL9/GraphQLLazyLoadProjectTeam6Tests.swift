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

class GraphQLLazyLoadProjectTeam6Tests: GraphQLLazyLoadBaseTest {
    
    func testSaveTeam() async throws {
        await setup(withModels: ProjectTeam6Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        try await assertModelExists(savedTeam)
    }
    
    func testSaveProject() async throws {
        await setup(withModels: ProjectTeam6Models())
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        let savedProject = try await mutate(.create(project))
        try await assertModelExists(savedProject)
        assertProjectDoesNotContainTeam(savedProject)
    }
    
    func testSaveProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam6Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        
        // Project initializer variation #1 (pass both team reference and fields in)
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team,
                              teamId: team.teamId,
                              teamName: team.name)
        let savedProject = try await mutate(.create(project))
        let queriedProject = try await query(for: savedProject)!
        assertProject(queriedProject, hasTeam: savedTeam)
        
        // Project initializer variation #2 (pass only team reference)
        let project2 = Project(projectId: UUID().uuidString,
                               name: "name",
                               team: team)
        let savedProject2 = try await mutate(.create(project2))
        let queriedProject2 = try await query(for: savedProject2)!
        assertProject(queriedProject2, hasTeam: savedTeam)
        
        // Project initializer variation #3 (pass fields in)
        let project3 = Project(projectId: UUID().uuidString,
                               name: "name",
                               teamId: team.teamId,
                               teamName: team.name)
        let savedProject3 = try await mutate(.create(project3))
        let queriedProject3 = try await query(for: savedProject3)!
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
    
    func testListProjectListTeam() async throws {
        await setup(withModels: ProjectTeam6Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        try await mutate(.create(team))
        let project = initializeProjectWithTeam(team)
        try await mutate(.create(project))
        
        let queriedProjects = try await listQuery(.list(Project.self, where: Project.keys.projectId == project.projectId))
        assertList(queriedProjects, state: .isLoaded(count: 1))
        assertLazyReference(queriedProjects.first!._team, state: .notLoaded(identifiers: [
            .init(name: "teamId", value: team.teamId),
            .init(name: "name", value: team.name)]))
        
        let queriedTeams = try await listQuery(.list(Team.self, where: Team.keys.teamId == team.teamId))
        assertList(queriedTeams, state: .isLoaded(count: 1))
    }
    
    func testSaveProjectWithTeamThenUpdate() async throws {
        await setup(withModels: ProjectTeam6Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
    
        let project = initializeProjectWithTeam(team)
        let savedProject = try await mutate(.create(project))
        assertProject(savedProject, hasTeam: savedTeam)
        let queriedProject = try await query(for: savedProject)!
        assertProject(queriedProject, hasTeam: savedTeam)
        let updatedProject = try await mutate(.update(project))
        assertProject(updatedProject, hasTeam: savedTeam)
    }
    
    func testSaveProjectWithoutTeamUpdateProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam6Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await mutate(.create(project))
        assertProjectDoesNotContainTeam(savedProject)
        
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        var queriedProject = try await query(for: savedProject)!
        queriedProject.setTeam(team)
        let savedProjectWithNewTeam = try await mutate(.update(queriedProject))
        assertProject(savedProjectWithNewTeam, hasTeam: savedTeam)
    }
    
    func testSaveTeamSaveProjectWithTeamUpdateProjectToNoTeam() async throws {
        await setup(withModels: ProjectTeam6Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(team)
        let savedProject = try await mutate(.create(project))
        var queriedProject = try await query(for: savedProject)!
        assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.setTeam(nil)
        let savedProjectWithNoTeam = try await mutate(.update(queriedProject))
        assertProjectDoesNotContainTeam(savedProjectWithNoTeam)
    }
    
    func testSaveProjectWithTeamUpdateProjectToNewTeam() async throws {
        await setup(withModels: ProjectTeam6Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(team)
        let savedProject = try await mutate(.create(project))
        let newTeam = Team(teamId: UUID().uuidString, name: "name")
        let savedNewTeam = try await mutate(.create(newTeam))
        var queriedProject = try await query(for: savedProject)!
        assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.teamId = newTeam.teamId
        queriedProject.teamName = newTeam.name
        let savedProjectWithNewTeam = try await mutate(.update(queriedProject))
        assertProject(queriedProject, hasTeam: savedNewTeam)
    }
    
    func testDeleteTeam() async throws {
        await setup(withModels: ProjectTeam6Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        try await assertModelExists(savedTeam)
        try await mutate(.delete(savedTeam))
        try await assertModelDoesNotExist(savedTeam)
    }
    
    func testDeleteProject() async throws {
        await setup(withModels: ProjectTeam6Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await mutate(.create(project))
        try await assertModelExists(savedProject)
        try await mutate(.delete(savedProject))
        try await assertModelDoesNotExist(savedProject)
    }
    
    func testDeleteProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam6Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(team)
        let savedProject = try await mutate(.create(project))
        
        try await assertModelExists(savedProject)
        try await assertModelExists(savedTeam)
        
        try await mutate(.delete(savedProject))
        
        try await assertModelDoesNotExist(savedProject)
        try await assertModelExists(savedTeam)
        
        try await mutate(.delete(savedTeam))
        try await assertModelDoesNotExist(savedTeam)
    }
    
    func testSubscribeToTeam() async throws {
        await setup(withModels: ProjectTeam6Models())
        let connected = asyncExpectation(description: "subscription connected")
        let onCreatedTeam = asyncExpectation(description: "onCreate received")
        let subscription = Amplify.API.subscribe(request: .subscription(of: Team.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        log.verbose("Subscription connect state is \(subscriptionConnectionState)")
                        if case .connected = subscriptionConnectionState {
                            await connected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let createdTeam):
                            log.verbose("Successfully got createdTeam from subscription: \(createdTeam)")
                            await onCreatedTeam.fulfill()
                        case .failure(let error):
                            XCTFail("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                XCTFail("Subscription has terminated with \(error)")
            }
        }
        
        await waitForExpectations([connected], timeout: 10)
        
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        await waitForExpectations([onCreatedTeam], timeout: 10)
        subscription.cancel()
    }
    
    func testSubscribeProject() async throws {
        await setup(withModels: ProjectTeam6Models())
        let connected = asyncExpectation(description: "subscription connected")
        let onCreated = asyncExpectation(description: "onCreate received")
        let subscription = Amplify.API.subscribe(request: .subscription(of: Project.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        log.verbose("Subscription connect state is \(subscriptionConnectionState)")
                        if case .connected = subscriptionConnectionState {
                            await connected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let created):
                            log.verbose("Successfully got model from subscription: \(created)")
                            await onCreated.fulfill()
                        case .failure(let error):
                            XCTFail("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                XCTFail("Subscription has terminated with \(error)")
            }
        }
        
        await waitForExpectations([connected], timeout: 10)
        
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        let savedProject = try await mutate(.create(project))
        
        await waitForExpectations([onCreated], timeout: 10)
        subscription.cancel()
    }
}

extension GraphQLLazyLoadProjectTeam6Tests: DefaultLogger { }

extension GraphQLLazyLoadProjectTeam6Tests {
    
    typealias Project = Project6
    typealias Team = Team6
    
    struct ProjectTeam6Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Project6.self)
            ModelRegistry.register(modelType: Team6.self)
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
