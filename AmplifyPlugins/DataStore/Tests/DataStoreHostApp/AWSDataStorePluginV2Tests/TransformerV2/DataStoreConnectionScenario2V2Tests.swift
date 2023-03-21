//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

/* Has One (Explicit Field)
 A one-to-one connection where a project has one team,
 with a field you would like to use for the connection.
 ```
 type Project2V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   name: String
   teamID: ID!
   team: Team2V2 @hasOne(fields: ["teamID"])
 }

 type Team2V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   name: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */

// swiftlint:disable type_body_length
class DataStoreConnectionScenario2V2Tests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Team2V2.self)
            registry.register(modelType: Project2V2.self)
        }

        let version: String = "1"
    }

    func testSaveTeamAndProjectSyncToCloud() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = randomTeam()
        let project = randomProject(with: team)

        try await createModelUntilSynced(data: team)
        try await createModelUntilSynced(data: project)

        let queriedProjectOptional = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        guard let queriedProject = queriedProjectOptional else {
            XCTFail("Failed")
            return
        }
        XCTAssertEqual(queriedProject, project)
    }

    func testUpdateProjectWithAnotherTeam() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = randomTeam()
        let anotherTeam = randomTeam()
        var project = randomProject(with: team)
        let expectedUpdatedProject = Project2V2(id: project.id, name: project.name, teamID: anotherTeam.id)
        
        try await createModelUntilSynced(data: team)
        try await createModelUntilSynced(data: anotherTeam)
        try await createModelUntilSynced(data: project)

        project.teamID = anotherTeam.id
        project.team = anotherTeam
        try await updateModelWaitFroSync(data: project)

        let queriedProjectOptional = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNotNil(queriedProjectOptional)
        if let queriedProject = queriedProjectOptional {
            XCTAssertEqual(queriedProject, project)
            XCTAssertEqual(queriedProject.teamID, anotherTeam.id)
        }
    }

    func testCreateUpdateDeleteAndGetProjectReturnsNil() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let team = randomTeam()
        var project = randomProject(with: team)

        try await createModelUntilSynced(data: team)
        try await createModelUntilSynced(data: project)

        project.name = "updatedName"
        try await updateModelWaitFroSync(data: project)

        try await deleteModelWaitForSync(data: project)
        // TODO: Delete Team should not be necessary, cascade delete should delete the team when deleting the project.
        // Once cascade works for hasOne, the following code can be removed.
        try await deleteModelWaitForSync(data: team)

        let queriedProject = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNil(queriedProject)

        let queriedTeam = try await Amplify.DataStore.query(Team2V2.self, byId: team.id)
        XCTAssertNil(queriedTeam)
    }

    func testDeleteAndGetProjectReturnsNilWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let team = randomTeam()
        let project = randomProject(with: team)
        
        try await createModelUntilSynced(data: team)
        try await createModelUntilSynced(data: project)

        try await deleteModelWaitForSync(data: project)

        // TODO: Delete Team should not be necessary, cascade delete should delete the team when deleting the project.
        // Once cascade works for hasOne, the following code can be removed.
        try await deleteModelWaitForSync(data: team)

        let queriedProject = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNil(queriedProject)

        let queriedTeam = try await Amplify.DataStore.query(Team2V2.self, byId: team.id)
        XCTAssertNil(queriedTeam)
    }

    func testDeleteWithValidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let team = randomTeam()
        let project = randomProject(with: team)
        
        try await createModelUntilSynced(data: team)
        try await createModelUntilSynced(data: project)

        try await deleteModelWaitForSync(data: project, predicate: Project2V2.keys.team.eq(team.id))

        let queriedProject = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNil(queriedProject)
    }

    func testDeleteWithInvalidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let team = randomTeam()
        let project = randomProject(with: team)
        try await createModelUntilSynced(data: team)
        try await createModelUntilSynced(data: project)
        
        do {
            try await deleteModelWaitForSync(data: project, predicate: Project2V2.keys.teamID.eq("invalidTeamId"))
            XCTFail("Should have failed")
        } catch let error as DataStoreError {
            guard case .invalidCondition = error else {
                XCTFail("\(error)")
                return
            }
        } catch {
            throw error
        }
        
        let queriedProject = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNotNil(queriedProject)
    }

    func testDeleteAlreadyDeletedItemWithCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let team = randomTeam()
        let project = randomProject(with: team)
        
        _ = try await Amplify.DataStore.delete(project)

        let queriedProjectOptional = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNil(queriedProjectOptional)
        
        _ = try await Amplify.DataStore.delete(project, where: Project2V2.keys.teamID == team.id)
    }

    func testListProjectsByTeamID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let team = randomTeam()
        let project = randomProject(with: team)
        try await createModelUntilSynced(data: team)
        try await createModelUntilSynced(data: project)
        
        let predicate = Project2V2.keys.teamID.eq(team.id)
        let projects = try await Amplify.DataStore.query(Project2V2.self, where: predicate)
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects[0].id, project.id)
        XCTAssertEqual(projects[0].teamID, team.id)
    }

    private func randomTeam() -> Team2V2 {
        Team2V2(name: UUID().uuidString)
    }

    private func randomProject(with team: Team2V2) -> Project2V2 {
        Project2V2(teamID: team.id, team: team)
    }
}

extension Team2V2: Equatable {
    public static func == (lhs: Team2V2,
                           rhs: Team2V2) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
    }
}
extension Project2V2: Equatable {
    public static func == (lhs: Project2V2, rhs: Project2V2) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.teamID == rhs.teamID
    }
}
