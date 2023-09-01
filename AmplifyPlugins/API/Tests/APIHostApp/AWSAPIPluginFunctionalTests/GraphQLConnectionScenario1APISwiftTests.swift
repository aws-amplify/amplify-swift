//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
#if os(watchOS)
@testable import APIWatchApp
#else
@testable import APIHostApp
#endif

extension GraphQLConnectionScenario1Tests {
    
    func createTeamAPISwift() async throws -> APISwift.CreateTeam1Mutation.Data.CreateTeam1? {
        let input = APISwift.CreateTeam1Input(name: "name")
        let mutation = APISwift.CreateTeam1Mutation(input: input)
        let request = GraphQLRequest<APISwift.CreateTeam1Mutation.Data>(
            document: APISwift.CreateTeam1Mutation.operationString,
            variables: mutation.variables?.jsonObject,
            responseType: APISwift.CreateTeam1Mutation.Data.self)
        let response = try await Amplify.API.mutate(request: request)
        switch response {
        case .success(let data):
            return data.createTeam1
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
    
    func createProjectAPISwift(with team: APISwift.CreateTeam1Mutation.Data.CreateTeam1? = nil) async throws -> APISwift.CreateProject1Mutation.Data.CreateProject1? {
        
        let input = APISwift.CreateProject1Input(project1TeamId: team?.id)
        let mutation = APISwift.CreateProject1Mutation(input: input)
        let request = GraphQLRequest<APISwift.CreateProject1Mutation.Data>(
            document: APISwift.CreateProject1Mutation.operationString,
            variables: mutation.variables?.jsonObject,
            responseType: APISwift.CreateProject1Mutation.Data.self)
        let response = try await Amplify.API.mutate(request: request)
        switch response {
        case .success(let data):
            return data.createProject1
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
    
    func updateProjectAPISwift(projectId: String, teamId: String) async throws -> APISwift.UpdateProject1Mutation.Data.UpdateProject1? {
        let input = APISwift.UpdateProject1Input(id: projectId, project1TeamId: teamId)
        let mutation = APISwift.UpdateProject1Mutation(input: input)
        let request = GraphQLRequest<APISwift.UpdateProject1Mutation.Data>(
            document: APISwift.UpdateProject1Mutation.operationString,
            variables: mutation.variables?.jsonObject,
            responseType: APISwift.UpdateProject1Mutation.Data.self)
        let response = try await Amplify.API.mutate(request: request)
        switch response {
        case .success(let data):
            return data.updateProject1
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
    
    func deleteProjectAPISwift(projectId: String) async throws -> APISwift.DeleteProject1Mutation.Data.DeleteProject1? {
        let input = APISwift.DeleteProject1Input(id: projectId)
        let mutation = APISwift.DeleteProject1Mutation(input: input)
        let request = GraphQLRequest<APISwift.DeleteProject1Mutation.Data>(
            document: APISwift.DeleteProject1Mutation.operationString,
            variables: mutation.variables?.jsonObject,
            responseType: APISwift.DeleteProject1Mutation.Data.self)
        let response = try await Amplify.API.mutate(request: request)
        switch response {
        case .success(let data):
            return data.deleteProject1
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
    
    func getProjectAPISwift(projectId: String) async throws -> APISwift.GetProject1Query.Data.GetProject1? {
        let query = APISwift.GetProject1Query(id: projectId)
        let request = GraphQLRequest<APISwift.GetProject1Query.Data>(
            document: APISwift.GetProject1Query.operationString,
            variables: query.variables?.jsonObject,
            responseType: APISwift.GetProject1Query.Data.self)
        let response = try await Amplify.API.query(request: request)
        switch response {
        case .success(let data):
            return data.getProject1
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
    
    func listProjectsAPISwift() async throws -> APISwift.ListProject1sQuery.Data.ListProject1? {
        let query = APISwift.ListProject1sQuery(limit: 1)
        let request = GraphQLRequest<APISwift.ListProject1sQuery.Data>(
            document: APISwift.ListProject1sQuery.operationString,
            variables: query.variables?.jsonObject,
            responseType: APISwift.ListProject1sQuery.Data.self)
        let response = try await Amplify.API.query(request: request)
        switch response {
        case .success(let data):
            return data.listProject1s
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
    
    func testCreateTeamAPISwift() async throws {
        guard try await createTeamAPISwift() != nil else {
            XCTFail("Could not create team")
            return
        }
    }
    
    func testCreateProject() async throws {
        guard try await createProjectAPISwift() != nil else {
            XCTFail("Could not create team")
            return
        }
    }
    
    func testCreateAndGetProjectAPISwift() async throws {
        guard let team = try await createTeamAPISwift(),
              let project = try await createProjectAPISwift(with: team) else {
            XCTFail("Could not create team and a project")
            return
        }
        
        let query = APISwift.GetProject1Query(id: project.id)
        let request = GraphQLRequest<APISwift.GetProject1Query.Data>(
            document: APISwift.GetProject1Query.operationString,
            variables: query.variables?.jsonObject,
            responseType: APISwift.GetProject1Query.Data.self)
        let result = try await Amplify.API.query(request: request)
        switch result {
        case .success(let data):
            guard let queriedProject = data.getProject1 else {
                XCTFail("Failed to get queried project")
                return
            }
            XCTAssertEqual(queriedProject.id, project.id)
            guard let queriedTeam = queriedProject.team else {
                XCTFail("Failed to get queried team")
                return
            }
            XCTAssertEqual(queriedTeam.id, team.id)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }
    
    func testUpdateProjectWithAnotherTeamAPISwift() async throws {
        guard let team = try await createTeamAPISwift(),
              let project = try await createProjectAPISwift(with: team) else {
            XCTFail("Could not create a Team")
            return
        }
        guard let createdAnotherTeam = try await createTeamAPISwift() else {
            XCTFail("Failed to create another team")
            return
        }
        
        guard let updatedProject = try await updateProjectAPISwift(projectId: project.id, teamId: createdAnotherTeam.id) else {
            XCTFail("Failed to update project to another team")
            return
        }
        XCTAssertEqual(updatedProject.team?.id, createdAnotherTeam.id)
    }
    
    func testDeleteAndGetProjectAPISwift() async throws {
        guard let team = try await createTeamAPISwift(),
              let project = try await createProjectAPISwift(with: team) else {
            XCTFail("Could not create team and a project")
            return
        }
        
        guard let deletedProject = try await deleteProjectAPISwift(projectId: project.id) else {
            XCTFail("Could not delete project")
            return
        }
        XCTAssertEqual(deletedProject.id, project.id)
        
        guard try await getProjectAPISwift(projectId: project.id) == nil else {
            XCTFail("Project after deletion should be nil")
            return
        }
    }
    
    func testListProjectsAPISwift() async throws {
        guard let projects = try await listProjectsAPISwift() else {
            XCTFail("Could not list projects")
            return
        }
    }
}
