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
    }

    // Create Project2 in different ways, then retrieve it
    // 1. `teamID` and `team`
    // 2. With random `teamID` and `team`
    func testCreateAndGetProject() async throws {
        let team2 = Team2(name: "name")
        _ = try await Amplify.API.mutate(request: .create(team2))
        let project2a = Project2(teamID: team2.id, team: team2)
        _ = try await Amplify.API.mutate(request: .create(project2a))
       
        let result = try await Amplify.API.query(request: .get(Project2.self, byId: project2a.id))
        switch result {
        case .success(let queriedProjectOptional):
            guard let queriedProject = queriedProjectOptional else {
                XCTFail("Failed")
                return
            }
            XCTAssertEqual(queriedProject.id, project2a.id)
            XCTAssertEqual(queriedProject.teamID, team2.id)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        
        let project2b = Project2(teamID: "randomTeamID", team: team2)
        _ = try await Amplify.API.mutate(request: .create(project2b))
        let result2 = try await Amplify.API.query(request: .get(Project2.self, byId: project2b.id))
        switch result2 {
        case .success(let queriedProjectOptional):
            guard let queriedProject = queriedProjectOptional else {
                XCTFail("querying for the project should not return nil")
                return
            }
            XCTAssertEqual(queriedProject.id, project2b.id)
            XCTAssertEqual(queriedProject.teamID, team2.id)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    func testUpdateProjectWithAnotherTeam() async throws {
        let team2 = Team2(name: "name")
        _ = try await Amplify.API.mutate(request: .create(team2))
        let project2 = Project2(teamID: team2.id, team: team2 )
        let createdProjectResult = try await Amplify.API.mutate(request: .create(project2))
        switch createdProjectResult {
        case .success(var createdProject):
            let anotherTeam = Team2(name: "name")
            guard case .success(let createdAnotherTeam) = try await Amplify.API.mutate(request: .create(anotherTeam)) else {
                XCTFail("Failed to create another team")
                return
            }
            createdProject.team = createdAnotherTeam
    
            guard case .success(let updatedProject) = try await Amplify.API.mutate(request: .update(createdProject)) else {
                XCTFail("Failed to update project to another team")
                return
            }
            XCTAssertEqual(updatedProject.teamID, anotherTeam.id)
            // The team object does not get retrieved from the service and is `nil`, but should be eager loaded to contain the `team`
            //  XCTAssertEqual(updatedProject.team, anotherTeam)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }
    
    func testDeleteAndGetProject() async throws {
        let team2 = Team2(name: "name")
        _ = try await Amplify.API.mutate(request: .create(team2))
        let project2 = Project2(teamID: team2.id, team: team2)
        _ = try await Amplify.API.mutate(request: .create(project2))
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

    func testListProjectsByTeamID() {
        guard let team = createTeam2(name: "name") else {
            XCTFail("Could not create team")
            return
        }
        guard createProject2(teamID: team.id, team: team) != nil else {
            XCTFail("Could not create project")
            return
        }
        let listProjectByTeamIDCompleted = expectation(description: "list projects completed")
        let predicate = Project2.keys.teamID.eq(team.id)
        Amplify.API.query(request: .list(Project2.self, where: predicate)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let projects):
                    print(projects)
                    listProjectByTeamIDCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listProjectByTeamIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    // Create two projects for the same team, then list the projects by teamID, and expect two projects
    // after exhausting the paginated list via `hasNextPage` and `getNextPage`
    func testPaginatedListProjectsByTeamID() async throws {
        guard let team = createTeam2(name: "name"),
              createProject2(teamID: team.id, team: team) != nil,
              createProject2(teamID: team.id, team: team) != nil else {
            XCTFail("Could not create team and two projects")
            return
        }
        let listProjectByTeamIDCompleted = expectation(description: "list projects completed")
        var results: List<Project2>?
        let predicate = Project2.keys.teamID.eq(team.id)
        Amplify.API.query(request: .list(Project2.self, where: predicate, limit: 1)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let projects):
                    results = projects
                    listProjectByTeamIDCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listProjectByTeamIDCompleted], timeout: TestCommonConstants.networkTimeout)
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

    func createTeam2(id: String = UUID().uuidString, name: String) -> Team2? {
        let team = Team2(id: id, name: name)
        var result: Team2?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(team)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let team):
                    result = team
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createProject2(id: String = UUID().uuidString,
                        name: String? = nil,
                        teamID: String,
                        team: Team2? = nil) -> Project2? {
        let project = Project2(id: id, name: name, teamID: teamID, team: team)
        var result: Project2?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(project)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let project):
                    result = project
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}

extension Team2: Equatable {
    public static func == (lhs: Team2, rhs: Team2) -> Bool {
        return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.createdAt == rhs.createdAt
        && lhs.updatedAt == rhs.updatedAt
    }
}
