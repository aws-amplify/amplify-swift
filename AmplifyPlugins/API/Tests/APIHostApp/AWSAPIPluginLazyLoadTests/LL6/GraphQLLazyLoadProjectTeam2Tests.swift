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

class GraphQLLazyLoadProjectTeam2Tests: GraphQLLazyLoadBaseTest {

    func testSaveTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        try await assertModelExists(savedTeam)
    }
    
    func testSaveProject() async throws {
        await setup(withModels: ProjectTeam2Models())
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        let savedProject = try await mutate(.create(project))
        try await assertModelExists(savedProject)
        assertProjectDoesNotContainTeam(savedProject)
    }
    
    func testSaveProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        
        // Project initializer variation #1 (pass both team reference and fields in)
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team,
                              project2TeamTeamId: team.teamId,
                              project2TeamName: team.name)
        let savedProject = try await mutate(.create(project))
        let queriedProject = try await query(for: savedProject)!
        try await assertProject(queriedProject, hasTeam: savedTeam)
        
        // Project initializer variation #2 (pass only team reference)
        let project2 = Project(projectId: UUID().uuidString,
                               name: "name",
                               team: team)
        let savedProject2 = try await mutate(.create(project2))
        let queriedProject2 = try await query(for: savedProject2)!
        try await assertProject(queriedProject2, hasTeam: savedTeam)
        
        // Project initializer variation #3 (pass fields in)
        let project3 = Project(projectId: UUID().uuidString,
                               name: "name",
                               project2TeamTeamId: team.teamId,
                               project2TeamName: team.name)
        let savedProject3 = try await mutate(.create(project3))
        let queriedProject3 = try await query(for: savedProject3)!
        try await assertProject(queriedProject3, hasTeam: savedTeam)
    }
    
    func assertProject(_ project: Project, hasTeam team: Team) async throws {
        XCTAssertEqual(project.project2TeamTeamId, team.teamId)
        XCTAssertEqual(project.project2TeamName, team.name)
        assertLazyReference(project._team, state: .notLoaded(identifiers: [.init(name: "teamId", value: team.teamId),
                                                                       .init(name: "name", value: team.name)]))
        
        let loadedTeam = try await project.team!
        XCTAssertEqual(loadedTeam.teamId, team.teamId)
    }
    
    func assertProjectDoesNotContainTeam(_ project: Project) {
        XCTAssertNil(project.project2TeamTeamId)
        XCTAssertNil(project.project2TeamName)
        assertLazyReference(project._team, state: .notLoaded(identifiers: nil))
    }
    
    func testIncludesNestedModels() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        try await mutate(.create(team))
        let project = initializeProjectWithTeam(team)
        try await mutate(.create(project))
        
        guard let queriedProject = try await query(.get(Project.self,
                                                     byIdentifier: .identifier(projectId: project.projectId,
                                                                               name: project.name),
                                                     includes: { project in [project.team]})) else {
            XCTFail("Could not perform nested query for Project")
            return
        }
        
        assertLazyReference(queriedProject._team, state: .loaded(model: team))
    }
    
    func testListProjectListTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
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
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
    
        let project = initializeProjectWithTeam(team)
        let savedProject = try await mutate(.create(project))
        try await assertProject(savedProject, hasTeam: savedTeam)
        let queriedProject = try await query(for: savedProject)!
        try await assertProject(queriedProject, hasTeam: savedTeam)
        let updatedProject = try await mutate(.update(project))
        try await assertProject(updatedProject, hasTeam: savedTeam)
    }
    
    func testSaveProjectWithoutTeamUpdateProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await mutate(.create(project))
        assertProjectDoesNotContainTeam(savedProject)
        
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        var queriedProject = try await query(for: savedProject)!
        queriedProject.setTeam(team)
        // Setting the team via the FK fields do not work
        // queriedProject.project2TeamTeamId = team.teamId
        // queriedProject.project2TeamName = team.name
        let savedProjectWithNewTeam = try await mutate(.update(queriedProject))
        try await assertProject(savedProjectWithNewTeam, hasTeam: savedTeam)
    }
    
    func testSaveTeamSaveProjectWithTeamUpdateProjectToNoTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(team)
        let savedProject = try await mutate(.create(project))
        var queriedProject = try await query(for: savedProject)!
        try await assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.setTeam(nil)
        // Setting the team via the FK fields do not work
        // queriedProject.project2TeamTeamId = nil
        // queriedProject.project2TeamName = nil
        let savedProjectWithNoTeam = try await mutate(.update(queriedProject))
        assertProjectDoesNotContainTeam(savedProjectWithNoTeam)
    }
    
    func testSaveProjectWithTeamUpdateProjectToNewTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(team)
        let savedProject = try await mutate(.create(project))
        let newTeam = Team(teamId: UUID().uuidString, name: "name")
        let savedNewTeam = try await mutate(.create(newTeam))
        var queriedProject = try await query(for: savedProject)!
        try await assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.setTeam(newTeam)
        // Setting the team via the FK fields do not work
        // queriedProject.project2TeamTeamId = newTeam.teamId
        // queriedProject.project2TeamName = newTeam.name
        let savedProjectWithNewTeam = try await mutate(.update(queriedProject))
        try await assertProject(savedProjectWithNewTeam, hasTeam: savedNewTeam)
    }
    
    func testDeleteTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        try await assertModelExists(savedTeam)
        try await mutate(.delete(savedTeam))
        try await assertModelDoesNotExist(savedTeam)
    }
    
    func testDeleteProject() async throws {
        await setup(withModels: ProjectTeam2Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await mutate(.create(project))
        try await assertModelExists(savedProject)
        try await mutate(.delete(savedProject))
        try await assertModelDoesNotExist(savedProject)
    }
    
    func testDeleteProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam2Models())
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
}

extension GraphQLLazyLoadProjectTeam2Tests: DefaultLogger { }

extension GraphQLLazyLoadProjectTeam2Tests {
    
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
