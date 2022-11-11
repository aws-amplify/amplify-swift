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
    
    /*
     {
      "query" : "query GetTeam1($name: String!, $teamId: String!) {\n  getTeam1(name: $name, teamId: $teamId) {\n    teamId\n    name\n    createdAt\n    updatedAt\n    project {\n      projectId\n      name\n      __typename\n    }\n    __typename\n  }\n}",
      "variables" : {
        "teamId" : "587F7E73-F90A-4420-AF29-ECE76ECE34A9",
        "name" : "name"
      }
    }
     
    -[AWSAPIPluginLazyLoadTests.GraphQLLazyLoadProjectTeam1Tests testSaveTeam] : failed - Failed with error GraphQLResponseError<Optional<Team1>>: GraphQL service returned a successful response containing errors: [Amplify.GraphQLError(message: "Validation error of type VariableTypeMismatch: Variable type \'String!\' doesn\'t match expected type \'ID!\' @ \'getTeam1\'", locations: Optional([Amplify.GraphQLError.Location(line: 2, column: 33)]), path: nil, extensions: nil)]

     */
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
        assertProject(queriedProject, hasTeam: savedTeam)
        
        // Project initializer variation #2 (pass only team reference)
        let project2 = Project(projectId: UUID().uuidString,
                               name: "name",
                               team: team)
        let savedProject2 = try await mutate(.create(project2))
        let queriedProject2 = try await query(for: savedProject2)!
        assertProjectDoesNotContainTeam(queriedProject2)
        
        // Project initializer variation #3 (pass fields in)
        let project3 = Project(projectId: UUID().uuidString,
                               name: "name",
                               project1TeamTeamId: team.teamId,
                               project1TeamName: team.name)
        let savedProject3 = try await mutate(.create(project3))
        let queriedProject3 = try await query(for: savedProject3)!
        assertProject(queriedProject3, hasTeam: savedTeam)
    }
    
    func testSaveProjectWithTeamThenAccessProjectFromTeam() async throws {
        await setup(withModels: ProjectTeam1Models())
        
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(savedTeam)
        let savedProject = try await mutate(.create(project))
        let queriedProject = try await query(for: savedProject)!
        assertProject(queriedProject, hasTeam: savedTeam)
        var queriedTeam = try await query(for: savedTeam)!
        
        // The team has a FK referencing the Project. Updating the project with team
        // does not reflect the team, which is why the queried team does not have the project
        // to load.
        // Project (Parent) hasOne Team
        // Team (Child) belongsTo Project
        // Team has the FK of Project.
        switch queriedTeam._project.modelProvider.getState() {
        case .notLoaded(let identifiers):
            print("NOT LOADED \(identifiers)")
        case .loaded(let model):
            print("LOADED \(model)")
        }

        queriedTeam.setProject(queriedProject)
        let savedTeamWithProject = try await mutate(.update(queriedTeam))
        // Now the FK in the Team should be populated with Project's PK
        switch savedTeamWithProject._project.modelProvider.getState() {
        case .notLoaded(let identifiers):
            print("NOT LOADED \(identifiers)")
        case .loaded(let model):
            print("LOADED \(model)")
        }
        var queriedTeamWithProject = try await query(for: savedTeamWithProject)
        switch savedTeamWithProject._project.modelProvider.getState() {
        case .notLoaded(let identifiers):
            print("NOT LOADED \(identifiers)")
        case .loaded(let model):
            print("LOADED \(model)")
        }
    }
    
    // One-to-One relationships do not create a foreign key for the Team or Project table
    // So the LazyModel does not have the FK value to be instantiated as metadata for lazy loading.
    // We only assert the FK fields on the Project exist and are equal to the Team's PK.
    func assertProject(_ project: Project, hasTeam team: Team) {
        XCTAssertEqual(project.project1TeamTeamId, team.teamId)
        XCTAssertEqual(project.project1TeamName, team.name)
    }
    
    func assertProjectDoesNotContainTeam(_ project: Project) {
        XCTAssertNil(project.project1TeamTeamId)
        XCTAssertNil(project.project1TeamName)
    }
    
    func testSaveProjectWithTeamThenUpdate() async throws {
        await setup(withModels: ProjectTeam1Models())
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
        await setup(withModels: ProjectTeam1Models())
        let project = Project(projectId: UUID().uuidString, name: "name")
        let savedProject = try await mutate(.create(project))
        assertProjectDoesNotContainTeam(savedProject)
        
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        var queriedProject = try await query(for: savedProject)!
        queriedProject.project1TeamTeamId = team.teamId
        queriedProject.project1TeamName = team.name
        let savedProjectWithNewTeam = try await mutate(.update(queriedProject))
        assertProject(savedProjectWithNewTeam, hasTeam: savedTeam)
    }
    
    func testSaveTeamSaveProjectWithTeamUpdateProjectToNoTeam() async throws {
        await setup(withModels: ProjectTeam1Models())
        let team = Team(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await mutate(.create(team))
        let project = initializeProjectWithTeam(team)
        let savedProject = try await mutate(.create(project))
        var queriedProject = try await query(for: savedProject)!
        assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.project1TeamTeamId = nil
        queriedProject.project1TeamName = nil
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
        assertProject(queriedProject, hasTeam: savedTeam)
        queriedProject.project1TeamTeamId = newTeam.teamId
        queriedProject.project1TeamName = newTeam.name
        let savedProjectWithNewTeam = try await mutate(.update(queriedProject))
        assertProject(queriedProject, hasTeam: savedNewTeam)
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
