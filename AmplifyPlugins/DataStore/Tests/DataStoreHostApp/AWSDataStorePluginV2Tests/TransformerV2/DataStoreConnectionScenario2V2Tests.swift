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
        let team = Team2V2(name: "name1")
        let project = Project2V2(teamID: team.id, team: team)
        let syncedTeamReceived = expectation(description: "received team from sync event")
        
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedTeam = try? mutationEvent.decodeModel() as? Team2V2,
               syncedTeam == team {
                syncedTeamReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        _ = try await Amplify.DataStore.save(team)
        await fulfillment(of: [syncedTeamReceived], timeout: TestCommonConstants.networkTimeout)
        
        let syncProjectReceived = expectation(description: "received project from sync event")
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedProject = try? mutationEvent.decodeModel() as? Project2V2,
                      syncedProject == project {
                XCTAssertEqual(mutationEvent.version, 1)
                syncProjectReceived.fulfill()
            }
        }
        
        _ = try await Amplify.DataStore.save(project)
        await fulfillment(of: [syncProjectReceived], timeout: TestCommonConstants.networkTimeout)

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
        let team = Team2V2(name: "name1")
        let anotherTeam = Team2V2(name: "name1")
        var project = Project2V2(teamID: team.id, team: team)
        let expectedUpdatedProject = Project2V2(id: project.id, name: project.name, teamID: anotherTeam.id)
        
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

            if let syncedUpdatedProject = try? mutationEvent.decodeModel() as? Project2V2,
               expectedUpdatedProject == syncedUpdatedProject {
                syncUpdatedProjectReceived.fulfill()
            }
        }
        
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        project.teamID = anotherTeam.id
        project.team = anotherTeam
        _ = try await Amplify.DataStore.save(project)
        await fulfillment(of: [syncUpdatedProjectReceived], timeout: TestCommonConstants.networkTimeout)

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
        
        let team = Team2V2(name: "name")
        var project = Project2V2(teamID: team.id, team: team)
        
        let createReceived = expectation(description: "received created items from cloud")
        createReceived.expectedFulfillmentCount = 2 // 1 project and 1 team
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let projectEvent = try? mutationEvent.decodeModel() as? Project2V2,
               projectEvent.id == project.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            } else if let teamEvent = try? mutationEvent.decodeModel() as? Team2V2, teamEvent.id == team.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            }
        }
        
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(project)
        await fulfillment(of: [createReceived], timeout: TestCommonConstants.networkTimeout)
        
        let updateReceived = expectation(description: "received update project from sync path")
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let projectEvent = try? mutationEvent.decodeModel() as? Project2V2,
               projectEvent.id == project.id {
                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        project.name = "updatedName"
        _ = try await Amplify.DataStore.save(project)
        await fulfillment(of: [updateReceived], timeout: TestCommonConstants.networkTimeout)
        
        let deleteReceived = expectation(description: "received deleted project from sync path")
        deleteReceived.expectedFulfillmentCount = 2 // 1 project and 1 team
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let projectEvent = try? mutationEvent.decodeModel() as? Project2V2,
               projectEvent.id == project.id {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                }

            } else if let teamEvent = try? mutationEvent.decodeModel() as? Team2V2, teamEvent.id == team.id {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.delete(project)
        // TODO: Delete Team should not be necessary, cascade delete should delete the team when deleting the project.
        // Once cascade works for hasOne, the following code can be removed.
        _ = try await Amplify.DataStore.delete(team)
        await fulfillment(of: [deleteReceived], timeout: TestCommonConstants.networkTimeout)
        
        let queriedProject = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNil(queriedProject)

        let queriedTeam = try await Amplify.DataStore.query(Team2V2.self, byId: team.id)
        XCTAssertNil(queriedTeam)
    }

    func testDeleteAndGetProjectReturnsNilWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let team = Team2V2(name: "name")
        let project = Project2V2(teamID: team.id, team: team)
        
        let createReceived = expectation(description: "received created items from cloud")
        createReceived.expectedFulfillmentCount = 2 // 1 project and 1 team
        
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let projectEvent = try? mutationEvent.decodeModel() as? Project2V2,
               projectEvent.id == project.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            } else if let teamEvent = try? mutationEvent.decodeModel() as? Team2V2, teamEvent.id == team.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(project)
        await fulfillment(of: [createReceived], timeout: TestCommonConstants.networkTimeout)
        
        let deleteReceived = expectation(description: "Delete notification received")
        deleteReceived.expectedFulfillmentCount = 2 // 1 project and 1 team
        
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let projectEvent = try? mutationEvent.decodeModel() as? Project2V2,
               projectEvent.id == project.id {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                }

            } else if let teamEvent = try? mutationEvent.decodeModel() as? Team2V2, teamEvent.id == team.id {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.delete(project)

        // TODO: Delete Team should not be necessary, cascade delete should delete the team when deleting the project.
        // Once cascade works for hasOne, the following code can be removed.
        _ = try await Amplify.DataStore.delete(team)
        await fulfillment(of: [deleteReceived], timeout: TestCommonConstants.networkTimeout)
        let queriedProject = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNil(queriedProject)

        let queriedTeam = try await Amplify.DataStore.query(Team2V2.self, byId: team.id)
        XCTAssertNil(queriedTeam)
    }

    func testDeleteWithValidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let team = Team2V2(name: "name")
        let project = Project2V2(teamID: team.id, team: team)
        
        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(project)
        
        _ = try await Amplify.DataStore.delete(project, where: Project2V2.keys.team.eq(team.id))
                                               
        let queriedProject = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNil(queriedProject)
    }

    func testDeleteWithInvalidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let team = Team2V2(name: "name")
        let project = Project2V2(teamID: team.id, team: team)
        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(project)
        
        do {
            _ = try await Amplify.DataStore.delete(project, where: Project2V2.keys.teamID.eq("invalidTeamId"))
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
        
        let team = Team2V2(name: "name")
        let project = Project2V2(teamID: team.id, team: team)
        
        _ = try await Amplify.DataStore.delete(project)
        
        let queriedProjectOptional = try await Amplify.DataStore.query(Project2V2.self, byId: project.id)
        XCTAssertNil(queriedProjectOptional)
        
        _ = try await Amplify.DataStore.delete(project, where: Project2V2.keys.teamID == team.id)
    }

    func testListProjectsByTeamID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let team = Team2V2(name: "name")
        let project = Project2V2(teamID: team.id, team: team)
        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(project)
        
        let predicate = Project2V2.keys.teamID.eq(team.id)
        let projects = try await Amplify.DataStore.query(Project2V2.self, where: predicate)
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects[0].id, project.id)
        XCTAssertEqual(projects[0].teamID, team.id)
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
