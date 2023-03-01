//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import APIHostApp

/*
 A one-to-one connection where a project has one team,
 with a field you would like to use for the connection.
 ```
 type Project2 @model {
   id: ID!
   name: String
   teamID: ID!
   team: Team2 @connection(fields: ["teamID"])
 }

 type Team2 @model {
   id: ID!
   name: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */
class GraphQLConnectionScenario2Tests: XCTestCase {

    override func setUp() async throws {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Project2.self)
            ModelRegistry.register(modelType: Team2.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    // Create Project2 in different ways, then retrieve it
    // 1. `teamID` and `team`
    // 2. With random `teamID` and `team`
    func testCreateAndGetProject() async throws {
        guard let team = try await createTeam2(name: "name"),
              let project2a = try await createProject2(teamID: team.id, team: team),
              let project2b = try await createProject2(teamID: team.id, team: team) else {
            XCTFail("Could not create team and a project")
            return
        }
        let result = try await Amplify.API.query(request: .get(Project2.self, byId: project2a.id))
        switch result {
        case .success(let queriedProjectOptional):
            guard let queriedProject = queriedProjectOptional else {
                XCTFail("Failed")
                return
            }
            XCTAssertEqual(queriedProject.id, project2a.id)
            XCTAssertEqual(queriedProject.teamID, team.id)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        let result2 = try await Amplify.API.query(request: .get(Project2.self, byId: project2b.id))
        switch result2 {
        case .success(let queriedProjectOptional):
            guard let queriedProject = queriedProjectOptional else {
                XCTFail("querying for the project should not return nil")
                return
            }
            XCTAssertEqual(queriedProject.id, project2b.id)
            XCTAssertEqual(queriedProject.teamID, team.id)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    func testUpdateProjectWithAnotherTeam() async throws {
        guard let team = try await createTeam2(name: "name"),
              var project2 = try await createProject2(teamID: team.id, team: team) else {
            XCTFail("Could not create team and a project")
            return
        }
        let anotherTeam = Team2(name: "name")
        guard case .success(let createdAnotherTeam) = try await Amplify.API.mutate(request: .create(anotherTeam)) else {
            XCTFail("Failed to create another team")
            return
        }
        project2.team = createdAnotherTeam

        guard case .success(let updatedProject) = try await Amplify.API.mutate(request: .update(project2)) else {
            XCTFail("Failed to update project to another team")
            return
        }
        XCTAssertEqual(updatedProject.teamID, anotherTeam.id)
        // The team object does not get retrieved from the service and is `nil`, but should be eager loaded to contain the `team`
        //  XCTAssertEqual(updatedProject.team, anotherTeam)
    }
    
    func testDeleteAndGetProject() async throws {
        guard let team = try await createTeam2(name: "name"),
              let project2 = try await createProject2(teamID: team.id, team: team) else {
            XCTFail("Could not create team and a project")
            return
        }
        let deletedProjectResult = try await Amplify.API.mutate(request: .delete(project2))
        switch deletedProjectResult {
        case .success(let deletedProject):
            XCTAssertEqual(deletedProject.id, project2.id)
            print("successfully deleted the project \(deletedProject)")
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        let getProjectAfterDeleteCompleted = try await Amplify.API.query(request: .get(Project2.self, byId: project2.id))
        switch getProjectAfterDeleteCompleted {
        case .success(let queriedDeletedProjectOptional):
            guard queriedDeletedProjectOptional == nil else {
                XCTFail("Should be nil after deletion")
                return
            }
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    func testListProjectsByTeamID() async throws {
        guard let team = try await createTeam2(name: "name"),
              try await createProject2(teamID: team.id, team: team) != nil else {
            XCTFail("Could not create team and two projects")
            return
        }
        let predicate = Project2.keys.teamID.eq(team.id)
        let result = try await Amplify.API.query(request: .list(Project2.self, where: predicate))
        switch result {
        case .success(let projects):
            print(projects)
        case .failure(let graphQLResponse):
            XCTFail("Failed with: \(graphQLResponse)")
        }
    }

    // Create two projects for the same team, then list the projects by teamID, and expect two projects
    // after exhausting the paginated list via `hasNextPage` and `getNextPage`
    func testPaginatedListProjectsByTeamID() async throws {
        guard let team = try await createTeam2(name: "name"),
              try await createProject2(teamID: team.id, team: team) != nil,
              try await createProject2(teamID: team.id, team: team) != nil else {
            XCTFail("Could not create team and two projects")
            return
        }
        var results: List<Project2>?
        let predicate = Project2.keys.teamID.eq(team.id)
        let result = try await Amplify.API.query(request: .list(Project2.self, where: predicate, limit: 100))
        guard case .success(let projects) = result else {
            XCTFail("Missing Successful response")
            return
        }
        results = projects
        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }
        var resultsArray: [Project2] = []
        resultsArray.append(contentsOf: subsequentResults)
        while subsequentResults.hasNextPage() {
            let listResult = try await subsequentResults.getNextPage()
            subsequentResults = listResult
            resultsArray.append(contentsOf: subsequentResults)
        }
        XCTAssertEqual(resultsArray.count, 2)
    }
    
    func createTeam2(id: String = UUID().uuidString, name: String) async throws ->  Team2? {
        let team = Team2(id: id, name: name)
        let graphQLResponse = try await Amplify.API.mutate(request: .create(team))
        switch graphQLResponse {
        case .success(let team):
            return team
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }

    func createProject2(id: String = UUID().uuidString,
                        name: String? = nil,
                        teamID: String,
                        team: Team2? = nil) async throws -> Project2? {
        let project = Project2(id: id, name: name, teamID: teamID, team: team)
        let graphQLResponse = try await Amplify.API.mutate(request: .create(project))
        switch graphQLResponse {
        case .success(let project):
            return project
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
}

extension Team2: Equatable {
    public static func == (lhs: Team2,
                           rhs: Team2) -> Bool {
        return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.createdAt == rhs.createdAt
        && lhs.updatedAt == rhs.updatedAt
    }
}
