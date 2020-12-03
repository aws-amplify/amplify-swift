//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon

/*
 A one-to-one connection where a project has a team.
 ```
 type Project1 @model {
   id: ID!
   name: String
   team: Team1 @connection
 }

 type Team1 @model {
   id: ID!
   name: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details

 */
class GraphQLConnectionScenario1Tests: XCTestCase {

    override func setUp() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Project1.self)
            ModelRegistry.register(modelType: Team1.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testCreateAndGetProject() throws {
        guard let team = createTeam(name: "name") else {
            XCTFail("Could not create team")
            return
        }
        let createProjectSuccessful = expectation(description: "create project2")
        let project = Project1(team: team)
        Amplify.API.mutate(request: .create(project)) { result in
            switch result {
            case .success(let result):
                createProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [createProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectCompleted = expectation(description: "get project complete")
        Amplify.API.query(request: .get(Project1.self, byId: project.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedProjectOptional):
                    guard let queriedProject = queriedProjectOptional else {
                        XCTFail("Failed")
                        return
                    }
                    XCTAssertEqual(queriedProject.id, project.id)
                    XCTAssertEqual(queriedProject.team, team)
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
        guard let team = createTeam(name: "name") else {
            XCTFail("Could not create team")
            return
        }
        guard var project = createProject(team: team) else {
            XCTFail("Could not create project")
            return
        }
        guard let anotherTeam = createTeam(name: "name") else {
            XCTFail("Could not create team")
            return
        }

        let updateProjectSuccessful = expectation(description: "update project")
        project.team = anotherTeam
        Amplify.API.mutate(request: .update(project)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let updatedProject):
                    XCTAssertEqual(updatedProject.team, anotherTeam)
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
                updateProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAndGetProject() {
        guard let team = createTeam(name: "name") else {
            XCTFail("Could not create team")
            return
        }
        guard let project = createProject(team: team) else {
            XCTFail("Could not create project")
            return
        }

        let deleteProjectSuccessful = expectation(description: "delete project")
        Amplify.API.mutate(request: .delete(project)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let deletedProject):
                    XCTAssertEqual(deletedProject.team, team)
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
        Amplify.API.query(request: .get(Project1.self, byId: project.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let project):
                    guard project == nil else {
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

    // TODO: This test will fail until https://github.com/aws-amplify/amplify-ios/pull/885 is merged in
    func testListProjectsByTeamID() {
        guard let team = createTeam(name: "name") else {
            XCTFail("Could not create team")
            return
        }
        guard let project = createProject(team: team) else {
            XCTFail("Could not create project")
            return
        }
        let listProjectByTeamIDCompleted = expectation(description: "list projects completed")
        let predicate = Project1.keys.team.eq(team.id)
        Amplify.API.query(request: .list(Project1.self, where: predicate)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let projects):
                    XCTAssertEqual(projects.count, 1)
                    XCTAssertEqual(projects[0].id, project.id)
                    XCTAssertEqual(projects[0].team, team)
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

    func createTeam(id: String = UUID().uuidString, name: String) -> Team1? {
        let team = Team1(id: id, name: name)
        var result: Team1?
        let completeInvoked = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(team)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let team):
                    result = team
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createProject(id: String = UUID().uuidString,
                       name: String? = nil,
                       team: Team1? = nil) -> Project1? {
        let project = Project1(id: id, name: name, team: team)
        var result: Project1?
        let completeInvoked = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(project)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let project):
                    result = project
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}

extension Team1: Equatable {
    public static func == (lhs: Team1,
                           rhs: Team1) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
    }
}
