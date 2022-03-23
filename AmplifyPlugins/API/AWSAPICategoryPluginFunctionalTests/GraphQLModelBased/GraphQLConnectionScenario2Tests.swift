//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import AmplifyTestCommon

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

    override func setUp() {
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

    override func tearDown() {
        Amplify.reset()
    }

    // Create Project2 in different ways, then retrieve it
    // 1. `teamID` and `team`
    // 2. With random `teamID` and `team`
    func testCreateAndGetProject() throws {
        guard let team2 = createTeam2(name: "name") else {
            XCTFail("Could not create team")
            return
        }
        let createProject2aSuccessful = expectation(description: "create project2")
        let project2a = Project2(teamID: team2.id, team: team2)
        Amplify.API.mutate(request: .create(project2a)) { result in
            switch result {
            case .success(let result):
                createProject2aSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [createProject2aSuccessful], timeout: TestCommonConstants.networkTimeout)
        let createProject2bSuccessful = expectation(description: "create project2")
        let project2b = Project2(teamID: "randomTeamId", team: team2)
        Amplify.API.mutate(request: .create(project2b)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let createdProject):
                    XCTAssertEqual(createdProject.teamID, team2.id)
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
                createProject2bSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [createProject2bSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectCompleted = expectation(description: "get project complete")
        Amplify.API.query(request: .get(Project2.self, byId: project2a.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let project2):
                    XCTAssertNotNil(project2)
                    XCTAssertEqual(project2!.id, project2a.id)
                    getProjectCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testUpdateProjectWithAnotherTeam() {
        guard let team = createTeam2(name: "name") else {
            XCTFail("Could not create team")
            return
        }
        guard var project2 = createProject2(teamID: team.id, team: team) else {
            XCTFail("Could not create project")
            return
        }
        guard let anotherTeam = createTeam2(name: "name") else {
            XCTFail("Could not create team")
            return
        }

        let updateProject2Successful = expectation(description: "update project2")
        project2.team = anotherTeam
        Amplify.API.mutate(request: .update(project2)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let updatedProject):
                    XCTAssertEqual(updatedProject.teamID, anotherTeam.id)
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
                updateProject2Successful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateProject2Successful], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAndGetProject() {
        guard let team = createTeam2(name: "name") else {
            XCTFail("Could not create team")
            return
        }
        guard let project2 = createProject2(teamID: team.id, team: team) else {
            XCTFail("Could not create project")
            return
        }

        let deleteProjectSuccessful = expectation(description: "delete project")
        Amplify.API.mutate(request: .delete(project2)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let deletedProject):
                    XCTAssertEqual(deletedProject.teamID, team.id)
                    deleteProjectSuccessful.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }

            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        Amplify.API.query(request: .get(Project2.self, byId: project2.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let project2):
                    guard project2 == nil else {
                        XCTFail("Should be nil after deletion")
                        return
                    }
                    getProjectAfterDeleteCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
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
    func testPaginatedListProjectsByTeamID() {
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
            let semaphore = DispatchSemaphore(value: 0)
            subsequentResults.getNextPage { result in
                defer {
                    semaphore.signal()
                }
                switch result {
                case .success(let listResult):
                    subsequentResults = listResult
                    resultsArray.append(contentsOf: subsequentResults)
                case .failure(let coreError):
                    XCTFail("Unexpected error: \(coreError)")
                }

            }
            semaphore.wait()
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
