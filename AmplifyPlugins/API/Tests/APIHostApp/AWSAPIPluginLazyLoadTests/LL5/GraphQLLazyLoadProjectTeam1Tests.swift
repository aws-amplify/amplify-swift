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

class GraphQLLazyLoadProjectTeam1Tests: GraphQLLazyLoadBaseTest {
   
    func testSaveTeam() async throws {
        await setup(withModels: ProjectTeam1Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        try await assertModelExists(savedTeam)
    }
    
    func testSaveProject() async throws {
        await setup(withModels: ProjectTeam1Models())
        let project = Project(projectId: UUID().uuidString,
                              name: "name")
        let savedProject = try await mutate(.create(project))
        try await assertModelExists(savedProject)
        assertProjectDoesNotContainTeam(savedProject)
    }
    
    func testSaveProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam1Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        
        // Project initializer variation #1 (pass both team reference and fields in)
        let project = Project(projectId: UUID().uuidString,
                              name: "name",
                              team: team,
                              project1TeamTeamId: team.teamId,
                              project1TeamName: team.name)
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
                               project1TeamTeamId: team.teamId,
                               project1TeamName: team.name)
        let savedProject3 = try await mutate(.create(project3))
        let queriedProject3 = try await query(for: savedProject3)!
        try await assertProject(queriedProject3, hasTeam: savedTeam)
    }
    
    // The team has a FK referencing the Project and a project has a FK referencing the Team
    // Saving the Project with the team does not save the team on the project.
    // This test shows that by saving a project with a team, checking that the team doesn't have the project
    // Then updating the team with the project, and checking that the team has the project.
    func testSaveProjectWithTeamThenAccessProjectFromTeamAndTeamFromProject() async throws {
        await setup(withModels: ProjectTeam1Models())
        
        // save project with team
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(savedTeam)
        let savedProject = try await mutate(.create(project))
        
        let queriedProject = try await query(for: savedProject)!
        var queriedTeam = try await query(for: savedTeam)!
        
        // Access team from project
        try await assertProject(queriedProject, hasTeam: savedTeam)
        // The team does not have the project because we need to save the team with the project.
        assertTeamDoesNotContainProject(queriedTeam)
        
        queriedTeam.setProject(queriedProject)
        let teamWithProject = try await mutate(.update(queriedTeam))
        assertTeam(teamWithProject, hasProject: queriedProject)
    }
    
    func assertProject(_ project: Project, hasTeam team: Team) async throws {
        XCTAssertEqual(project.project1TeamTeamId, team.teamId)
        XCTAssertEqual(project.project1TeamName, team.name)
        assertLazyReference(project._team, state: .notLoaded(identifiers: [.init(name: "teamId", value: team.teamId),
                                                                       .init(name: "name", value: team.name)]))
        
        let loadedTeam = try await project.team!
        XCTAssertEqual(loadedTeam.teamId, team.teamId)
    }
    
    func assertProjectDoesNotContainTeam(_ project: Project) {
        XCTAssertNil(project.project1TeamTeamId)
        XCTAssertNil(project.project1TeamName)
        assertLazyReference(project._team, state: .notLoaded(identifiers: nil))
    }
    
    func assertTeam(_ team: Team, hasProject project: Project) {
        assertLazyReference(team._project, state: .notLoaded(identifiers: [.init(name: "projectId", value: project.projectId), .init(name: "name", value: project.name)]))
    }
    
    func assertTeamDoesNotContainProject(_ team: Team) {
        assertLazyReference(team._project, state: .notLoaded(identifiers: nil))
    }
    
    func testIncludesNestedModels() async throws {
        await setup(withModels: ProjectTeam1Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        var savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(savedTeam)
        let savedProject = try await mutate(.create(project))
        savedTeam.setProject(savedProject)
        try await mutate(.update(savedTeam))
        
        guard let queriedTeam = try await query(.get(Team.self,
                                                     byIdentifier: .identifier(teamId: team.teamId,
                                                                               name: team.name),
                                                     includes: { team in [team.project]})) else {
            XCTFail("Could not perform nested query for Team")
            return
        }
        
        assertLazyReference(queriedTeam._project, state: .loaded(model: project))
        
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
        await setup(withModels: ProjectTeam1Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        var savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(savedTeam)
        let savedProject = try await mutate(.create(project))
        savedTeam.setProject(savedProject)
        try await mutate(.update(savedTeam))
        
        let queriedProjects = try await listQuery(.list(Project.self, where: Project.keys.projectId == project.projectId))
        assertList(queriedProjects, state: .isLoaded(count: 1))
        assertLazyReference(queriedProjects.first!._team, state: .notLoaded(identifiers: [
            .init(name: "teamId", value: team.teamId),
            .init(name: "name", value: team.name)]))
        
        let queriedTeams = try await listQuery(.list(Team.self, where: Team.keys.teamId == team.teamId))
        assertList(queriedTeams, state: .isLoaded(count: 1))
        assertLazyReference(queriedTeams.first!._project,
                            state: .notLoaded(identifiers: [
                                .init(name: "projectId", value: project.projectId),
                                .init(name: "name", value: project.name)]))
    }
    
    func testSaveProjectWithTeamThenUpdate() async throws {
        await setup(withModels: ProjectTeam1Models())
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
        await setup(withModels: ProjectTeam1Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await mutate(.create(project))
        assertProjectDoesNotContainTeam(savedProject)
        
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        var queriedProject = try await query(for: savedProject)!
        queriedProject.setTeam(team)
        // Setting the team via the FK fields do not work
        // queriedProject.project1TeamTeamId = team.teamId
        // queriedProject.project1TeamName = team.name
        let savedProjectWithNewTeam = try await mutate(.update(queriedProject))
        try await assertProject(savedProjectWithNewTeam, hasTeam: savedTeam)
    }
    
    func testSaveTeamSaveProjectWithTeamUpdateProjectToNoTeam() async throws {
        await setup(withModels: ProjectTeam1Models())
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
        await setup(withModels: ProjectTeam1Models())
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
        await setup(withModels: ProjectTeam1Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        try await assertModelExists(savedTeam)
        try await mutate(.delete(savedTeam))
        try await assertModelDoesNotExist(savedTeam)
    }
    
    func testDeleteProject() async throws {
        await setup(withModels: ProjectTeam1Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await mutate(.create(project))
        try await assertModelExists(savedProject)
        try await mutate(.delete(savedProject))
        try await assertModelDoesNotExist(savedProject)
    }
    
    func testDeleteProjectWithTeam() async throws {
        await setup(withModels: ProjectTeam1Models())
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

extension GraphQLLazyLoadProjectTeam1Tests: DefaultLogger { }

extension GraphQLLazyLoadProjectTeam1Tests {
    typealias Project = Project1
    typealias Team = Team1
    
    struct ProjectTeam1Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Project1.self)
            ModelRegistry.register(modelType: Team1.self)
        }
    }
    
    func initializeProjectWithTeam(_ team: Team) -> Project {
        return Project(projectId: UUID().uuidString,
                       name: "name",
                       team: team,
                       project1TeamTeamId: team.teamId,
                       project1TeamName: team.name)
    }
}
