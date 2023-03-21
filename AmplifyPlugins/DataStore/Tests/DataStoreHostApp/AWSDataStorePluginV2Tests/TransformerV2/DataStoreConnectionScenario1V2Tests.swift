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

/* Has One (Implicit Field)
 A one-to-one connection where a project has a team.
 ```
 type Project1V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   name: String
   team: Team1V2 @hasOne
 }

 type Team1V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   name: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details

 */

class DataStoreConnectionScenario1V2Tests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Team1V2.self)
            registry.register(modelType: Project1V2.self)
        }

        let version: String = "1"
    }

    func testSaveTeamAndProjectSyncToCloud() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = randomTeam()
        // TODO: No need to add the `team` into the project, it is using explicit field `project1V2TeamId`
        let project = randomProject(with: team)
        
        _ = try await createModelUntilSynced(data: team)
        _ = try await createModelUntilSynced(data: project)

        let queriedProjectOptional = try await Amplify.DataStore.query(Project1V2.self, byId: project.id)
        guard let queriedProject = queriedProjectOptional else {
            XCTFail("Failed")
            return
        }
        XCTAssertEqual(queriedProject.id, project.id)
        XCTAssertEqual(queriedProject.project1V2TeamId, team.id)
    }

    func testUpdateProjectWithAnotherTeam() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = randomTeam()
        let anotherTeam = randomTeam()
        // TODO: No need to add the `team` into the project, it is using explicit field `project1V2TeamId`
        var project = randomProject(with: team)
        let expectedUpdatedProject = Project1V2(id: project.id,
                                                name: project.name,
                                                team: anotherTeam, // Not needed
                                                project1V2TeamId: anotherTeam.id)
        
        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(anotherTeam)
        _ = try await Amplify.DataStore.save(project)
        
        let syncUpdatedProjectReceived = expectation(description: "received updated project from sync path")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedUpdatedProject = try? mutationEvent.decodeModel() as? Project1V2,
                syncedUpdatedProject.id == expectedUpdatedProject.id,
               syncedUpdatedProject.project1V2TeamId == expectedUpdatedProject.project1V2TeamId {
                syncUpdatedProjectReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        project.project1V2TeamId = anotherTeam.id
        _ = try await Amplify.DataStore.save(project)
        await waitForExpectations(timeout: networkTimeout)

        let queriedProjectOptional = try await Amplify.DataStore.query(Project1V2.self, byId: project.id)
        XCTAssertNotNil(queriedProjectOptional)
        if let queriedProject = queriedProjectOptional {
            XCTAssertEqual(queriedProject, project)
            // TODO: Should the queried project eager load the has-one team?
            // XCTAssertEqual(queriedProject.team, anotherTeam)
            // or
            // access explicit field like this?
            XCTAssertEqual(queriedProject.project1V2TeamId, anotherTeam.id)
        }
    }

    func testCreateUpdateDeleteAndGetProjectReturnsNil() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let team = randomTeam()
        var project = randomProject(with: team)

        _ = try await createModelUntilSynced(data: team)
        _ = try await createModelUntilSynced(data: project)

        project.name = "updatedName"
        _ = try await updateModelWaitFroSync(data: project)

        _ = try await deleteModelWaitForSync(data: project)
        
        // TODO: Delete Team should not be necessary, cascade delete should delete the team when deleting the project.
        // Once cascade works for hasOne, the following code can be removed.
        _ = try await deleteModelWaitForSync(data: team)

        let queriedProject = try await Amplify.DataStore.query(Project1V2.self, byId: project.id)
        XCTAssertNil(queriedProject)

        let queriedTeam = try await Amplify.DataStore.query(Team1V2.self, byId: team.id)
        XCTAssertNil(queriedTeam)
    }

    func testDeleteAndGetProjectReturnsNilWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let team = randomTeam()
        let project = randomProject(with: team)

        _ = try await createModelUntilSynced(data: team)
        _ = try await createModelUntilSynced(data: project)

        _ = try await deleteModelWaitForSync(data: project)

        // TODO: Delete Team should not be necessary, cascade delete should delete the team when deleting the project.
        // Once cascade works for hasOne, the following code can be removed.
        _ = try await deleteModelWaitForSync(data: team)
        let queriedProject = try await Amplify.DataStore.query(Project1V2.self, byId: project.id)
        XCTAssertNil(queriedProject)

        let queriedTeam = try await Amplify.DataStore.query(Team1V2.self, byId: team.id)
        XCTAssertNil(queriedTeam)
    }

    func testDeleteWithValidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let team = randomTeam()
        let project = randomProject(with: team)
        _ = try await createModelUntilSynced(data: team)
        _ = try await createModelUntilSynced(data: project)
        
        _ = try await deleteModelWaitForSync(data: project, predicate: Project1V2.keys.team.eq(team.id))
                                               
        let queriedProject = try await Amplify.DataStore.query(Project1V2.self, byId: project.id)
        XCTAssertNil(queriedProject)
    }

    func testDeleteWithInvalidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let team = randomTeam()
        let project = randomProject(with: team)
        _ = try await createModelUntilSynced(data: team)
        _ = try await createModelUntilSynced(data: project)

        do {
            _ = try await Amplify.DataStore.delete(project, where: Project1V2.keys.team.eq("invalidTeamId"))
            XCTFail("Should have failed")
        } catch let error as DataStoreError {
            guard case .invalidCondition = error else {
                XCTFail("\(error)")
                return
            }
        } catch {
            throw error
        }

        let queriedProject = try await Amplify.DataStore.query(Project1V2.self, byId: project.id)
        XCTAssertNotNil(queriedProject)
    }

    func testListProjectsByTeamID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = randomTeam()
        let project = randomProject(with: team)
        _ = try await createModelUntilSynced(data: team)
        _ = try await createModelUntilSynced(data: project)
        
        let predicate = Project1V2.keys.team.eq(team.id)
        let projects = try await Amplify.DataStore.query(Project1V2.self, where: predicate)
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects[0].id, project.id)
        XCTAssertEqual(projects[0].project1V2TeamId, team.id)
    }

    private func randomTeam() -> Team1V2 {
        Team1V2(name: UUID().uuidString)
    }

    private func randomProject(with team: Team1V2? = nil) -> Project1V2 {
        if let team = team {
            return Project1V2(team: team, project1V2TeamId: team.id)
        }
        return Project1V2()
    }
}

extension Team1V2: Equatable {
    public static func == (lhs: Team1V2,
                           rhs: Team1V2) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
    }
}
extension Project1V2: Equatable {
    public static func == (lhs: Project1V2, rhs: Project1V2) -> Bool {
        return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.project1V2TeamId == rhs.project1V2TeamId
            // && lhs.team == rhs.team // TODO: Should the Project have the team?
    }
}
