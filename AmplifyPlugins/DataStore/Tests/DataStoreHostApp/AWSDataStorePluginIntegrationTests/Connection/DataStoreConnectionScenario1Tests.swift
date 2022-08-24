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

class DataStoreConnectionScenario1Tests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Team1.self)
            registry.register(modelType: Project1.self)
        }

        let version: String = "1"
    }
    
    func testSaveTeamAndProjectSyncToCloud() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = Team1(name: "name1")
        let project = Project1(team: team)
        let syncedTeamReceived = expectation(description: "received team from sync path")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedTeam = try? mutationEvent.decodeModel() as? Team1,
               syncedTeam == team {
                syncedTeamReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.save(team)
        await waitForExpectations(timeout: networkTimeout)
        
        let syncProjectReceived = expectation(description: "received project from sync path")
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedProject = try? mutationEvent.decodeModel() as? Project1,
                      syncedProject == project {
                syncProjectReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(project)
        await waitForExpectations(timeout: networkTimeout)

        let queriedProjectOptional = try await Amplify.DataStore.query(Project1.self, byId: project.id)
        guard let queriedProject = queriedProjectOptional else {
            XCTFail("Failed")
            return
        }
        XCTAssertEqual(queriedProject.id, project.id)
        XCTAssertEqual(queriedProject.team, team)
    }

    func testUpdateProjectWithAnotherTeam() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
        try await startAmplifyAndWaitForSync()
        let team = Team1(name: "name1")
        let anotherTeam = Team1(name: "name1")
        var project = Project1(team: team)
        let expectedUpdatedProject = Project1(id: project.id, name: project.name, team: anotherTeam)

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

            if let syncedUpdatedProject = try? mutationEvent.decodeModel() as? Project1,
               expectedUpdatedProject == syncedUpdatedProject {
                syncUpdatedProjectReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        project.team = anotherTeam
        _ = try await Amplify.DataStore.save(project)
        await waitForExpectations(timeout: networkTimeout)
        
        let queriedProjectOptional = try await Amplify.DataStore.query(Project1.self, byId: project.id)
        XCTAssertNotNil(queriedProjectOptional)
        if let queriedProject = queriedProjectOptional {
            XCTAssertEqual(queriedProject, project)
            XCTAssertEqual(queriedProject.team, anotherTeam)
        }
    }

    func testDeleteAndGetProjectReturnsNilWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let team = Team1(name: "name")
        let project = Project1(team: team)
        
        let createReceived = expectation(description: "received created items from cloud")
        createReceived.expectedFulfillmentCount = 2 // 1 project and 1 team
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let projectEvent = try? mutationEvent.decodeModel() as? Project1,
               projectEvent.id == project.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }

            } else if let teamEvent = try? mutationEvent.decodeModel() as? Team1, teamEvent.id == team.id {
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
        
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let deleteReceived = expectation(description: "Delete notification received")
        deleteReceived.expectedFulfillmentCount = 2 // 1 project and 1 team
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let projectEvent = try? mutationEvent.decodeModel() as? Project1,
               projectEvent.id == project.id {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                }

            } else if let teamEvent = try? mutationEvent.decodeModel() as? Team1, teamEvent.id == team.id {
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
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let queriedProject = try await Amplify.DataStore.query(Project1.self, byId: project.id)
        XCTAssertNil(queriedProject)
    }

    func testDeleteWithValidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = Team1(name: "name")
        let project = Project1(team: team)
        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(project)
        
        _ = try await Amplify.DataStore.delete(project, where: Project1.keys.team.eq(team.id))
                                               
        let queriedProject = try await Amplify.DataStore.query(Project1.self, byId: project.id)
        XCTAssertNil(queriedProject)
    }

    func testDeleteWithInvalidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = Team1(name: "name")
        let project = Project1(team: team)
        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(project)

        do {
            _ = try await Amplify.DataStore.delete(project, where: Project1.keys.team.eq("invalidTeamId"))
            XCTFail("Should have failed")
        } catch let error as DataStoreError {
            guard case .invalidCondition = error else {
                XCTFail("\(error)")
                return
            }
        } catch {
            throw error
        }

        let queriedProject = try await Amplify.DataStore.query(Project1.self, byId: project.id)
        XCTAssertNotNil(queriedProject)
    }

    func testListProjectsByTeamID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = Team1(name: "name")
        let project = Project1(team: team)
        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(project)
        
        let predicate = Project1.keys.team.eq(team.id)
        let projects = try await Amplify.DataStore.query(Project1.self, where: predicate)
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects[0].id, project.id)
        XCTAssertEqual(projects[0].team, team)
    }
}

extension Team1: Equatable {
    public static func == (lhs: Team1,
                           rhs: Team1) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
    }
}
extension Project1: Equatable {
    public static func == (lhs: Project1, rhs: Project1) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.team == rhs.team
    }
}
