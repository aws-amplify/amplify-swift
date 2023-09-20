//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
#if os(watchOS)
@testable import APIWatchApp
#else
@testable import APIHostApp
#endif

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
    
    override func setUp() async throws {
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
    
    override func tearDown() async throws {
        await Amplify.reset()
    }
    
    func testCreateAndGetProject() async throws {
        guard let team = try await createTeam(name: "name"),
              let project = try await createProject(team: team) else {
            XCTFail("Could not create team and a project")
            return
        }
        
        let result = try await Amplify.API.query(request: .get(Project1.self, byId: project.id))
        switch result {
        case .success(let queriedProjectOptional):
            guard let queriedProject = queriedProjectOptional else {
                XCTFail("Failed")
                return
            }
            XCTAssertEqual(queriedProject.id, project.id)
            XCTAssertEqual(queriedProject.team, team)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }
    
    func testUpdateProjectWithAnotherTeam() async throws {
        guard let team = try await createTeam(name: "name"),
              var project = try await createProject(team: team) else {
            XCTFail("Could not create a Team")
            return
        }
        let anotherTeam = Team1(name: "name")
        guard case .success(let createdAnotherTeam) = try await Amplify.API.mutate(request: .create(anotherTeam)) else {
            XCTFail("Failed to create another team")
            return
        }
        project.team = createdAnotherTeam

        guard case .success(let updatedProject) = try await Amplify.API.mutate(request: .update(project)) else {
            XCTFail("Failed to update project to another team")
            return
        }
        XCTAssertEqual(updatedProject.team, anotherTeam)
    }
    
    func testDeleteAndGetProject() async throws {
        guard let team = try await createTeam(name: "name"),
              let project = try await createProject(team: team) else {
            XCTFail("Could not create team and a project")
            return
        }
        let deletedProjectResult = try await Amplify.API.mutate(request: .delete(project))
        switch deletedProjectResult {
        case .success(let deletedProject):
            XCTAssertEqual(deletedProject.team, team)
            print("successfully deleted the project \(deletedProject)")
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        let getProjectAfterDeleteCompleted = try await Amplify.API.query(request: .get(Project1.self, byId: project.id))
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
    
    // The filter we are passing into is the ProjectTeamID, but the API doesn't have the field ProjectTeamID
    //    so we are disabling it
    func testListProjectsByTeamID() async throws {
        guard let team = try await createTeam(name: "name"),
              let project = try await createProject(team: team) else {
            XCTFail("Could not create team and a project")
            return
        }
        let predicate = Project1.keys.team.eq(team.id)
        let event = try await Amplify.API.query(request: .list(Project1.self, where: predicate))
        switch event {
        case .success(let projects):
            XCTAssertEqual(projects.count, 1)
            XCTAssertEqual(projects[0].id, project.id)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }
    
    func testPaginatedListProjects() async throws {
        let testCompleted = asyncExpectation(description: "test completed")
        Task {
            guard let team = try await createTeam(name: "name"),
                  let projecta = try await createProject(team: team),
                  let projectb = try await createProject(team: team) else {
                XCTFail("Could not create team and two projects")
                return
            }
            
            var results: List<Project1>?
            let predicate = Project1.keys.id == projecta.id || Project1.keys.id == projectb.id
            let request: GraphQLRequest<List<Project1>> = GraphQLRequest<Project1>.list(Project1.self, where: predicate)
            
            let result = try await Amplify.API.query(request: request)
            
            guard case .success(let projects) = result else {
                XCTFail("Missing Successful response")
                return
            }
            results = projects
            guard var subsequentResults = results else {
                XCTFail("Could not get first results")
                return
            }
            var resultsArray: [Project1] = []
            resultsArray.append(contentsOf: subsequentResults)
            while subsequentResults.hasNextPage() {
                let listResult = try await subsequentResults.getNextPage()
                subsequentResults = listResult
                resultsArray.append(contentsOf: subsequentResults)
            }
            XCTAssertEqual(resultsArray.count, 2)
            await testCompleted.fulfill()
        }
        await waitForExpectations([testCompleted], timeout: TestCommonConstants.networkTimeout)
    }
    
    func createTeam(id: String = UUID().uuidString, name: String) async throws -> Team1? {
        let team = Team1(id: id, name: name)
        let graphQLResponse = try await Amplify.API.mutate(request: .create(team))
        switch graphQLResponse {
        case .success(let team):
            return team
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
    
    func createProject(id: String = UUID().uuidString,
                       name: String? = nil,
                       team: Team1? = nil) async throws -> Project1? {
        let project = Project1(id: id, name: name, team: team)
        let graphQLResponse = try await Amplify.API.mutate(request: .create(project))
        switch graphQLResponse {
        case .success(let project):
            return project
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
}

extension Team1: Equatable {
    public static func == (lhs: Team1,
                           rhs: Team1) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
    }
}
