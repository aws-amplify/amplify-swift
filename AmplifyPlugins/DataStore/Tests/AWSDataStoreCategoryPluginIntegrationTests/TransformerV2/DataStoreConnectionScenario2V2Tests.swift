//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

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
        try startAmplifyAndWaitForSync()
        let team = Team2V2(name: "name1")
        let project = Project2V2(teamID: team.id, team: team)
        let syncedTeamReceived = expectation(description: "received team from sync event")
        let syncProjectReceived = expectation(description: "received project from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedTeam = try? mutationEvent.decodeModel() as? Team2V2,
               syncedTeam == team {
                syncedTeamReceived.fulfill()
            } else if let syncedProject = try? mutationEvent.decodeModel() as? Project2V2,
                      syncedProject == project {
                XCTAssertEqual(mutationEvent.version, 1)
                syncProjectReceived.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let saveTeamCompleted = expectation(description: "save team completed")

        Amplify.DataStore.save(team) { result in
            switch result {
            case .success:
                saveTeamCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveTeamCompleted, syncedTeamReceived], timeout: networkTimeout)
        let saveProjectCompleted = expectation(description: "save project completed")
        Amplify.DataStore.save(project) { result in
            switch result {
            case .success:
                saveProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }

        wait(for: [saveProjectCompleted, syncProjectReceived], timeout: networkTimeout)

        let queriedProjectCompleted = expectation(description: "query project completed")
        Amplify.DataStore.query(Project2V2.self, byId: project.id) { result in
            switch result {
            case .success(let queriedProject):
                XCTAssertEqual(queriedProject, project)
                queriedProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedProjectCompleted], timeout: networkTimeout)
    }

    func testUpdateProjectWithAnotherTeam() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        let team = Team2V2(name: "name1")
        let anotherTeam = Team2V2(name: "name1")
        var project = Project2V2(teamID: team.id, team: team)
        let expectedUpdatedProject = Project2V2(id: project.id, name: project.name, teamID: anotherTeam.id)
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
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let saveTeamCompleted = expectation(description: "save team completed")
        Amplify.DataStore.save(team) { result in
            switch result {
            case .success:
                saveTeamCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveTeamCompleted], timeout: networkTimeout)
        let saveAnotherTeamCompleted = expectation(description: "save team completed")
        Amplify.DataStore.save(anotherTeam) { result in
            switch result {
            case .success:
                saveAnotherTeamCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveAnotherTeamCompleted], timeout: networkTimeout)

        let saveProjectCompleted = expectation(description: "save project completed")
        Amplify.DataStore.save(project) { result in
            switch result {
            case .success:
                saveProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveProjectCompleted], timeout: networkTimeout)

        let updateProjectCompleted = expectation(description: "save project completed")
        project.teamID = anotherTeam.id
        project.team = anotherTeam
        Amplify.DataStore.save(project) { result in
            switch result {
            case .success:
                updateProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [updateProjectCompleted], timeout: networkTimeout)

        let queriedProjectCompleted = expectation(description: "query project completed")
        Amplify.DataStore.query(Project2V2.self, byId: project.id) { result in
            switch result {
            case .success(let queriedProjectOptional):
                XCTAssertNotNil(queriedProjectOptional)
                if let queriedProject = queriedProjectOptional {
                    XCTAssertEqual(queriedProject, project)
                    XCTAssertEqual(queriedProject.teamID, anotherTeam.id)
                }

                queriedProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedProjectCompleted, syncUpdatedProjectReceived], timeout: networkTimeout)
    }

    func testCreateUpdateDeleteAndGetProjectReturnsNil() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name"),
              var project = saveProject(teamID: team.id, team: team) else {
            XCTFail("Could not save team and project")
            return
        }
        let createReceived = expectation(description: "received create project from sync path")
        let updateReceived = expectation(description: "received update project from sync path")
        let deleteReceived = expectation(description: "received deleted project from sync path")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let projectEvent = try? mutationEvent.decodeModel() as? Project2V2,
               projectEvent.id == project.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    createReceived.fulfill()
                } else if mutationEvent.mutationType ==  GraphQLMutationType.update.rawValue {
                    updateReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                }

            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let updateProjectSuccessful = expectation(description: "update project")
        project.name = "updatedName"
        Amplify.DataStore.save(project) { result in
            switch result {
            case .success:
                updateProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateProjectSuccessful, updateReceived], timeout: TestCommonConstants.networkTimeout)

        let deleteProjectSuccessful = expectation(description: "delete project")
        Amplify.DataStore.delete(project) { result in
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful, deleteReceived], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        Amplify.DataStore.query(Project2V2.self, byId: project.id) { result in
            switch result {
            case .success(let project2V2):
                XCTAssertNil(project2V2)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAndGetProjectReturnsNilWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
            XCTFail("Could not save team and project")
            return
        }
        let createReceived = expectation(description: "received created items from cloud")
        createReceived.expectedFulfillmentCount = 2 // 1 project and 1 team
        let deleteReceived = expectation(description: "Delete notification received")
        deleteReceived.expectedFulfillmentCount = 2 // 1 project and 1 team
        let hubListener = Amplify.Hub.listen(to: .dataStore,
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
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                }

            } else if let teamEvent = try? mutationEvent.decodeModel() as? Team2V2, teamEvent.id == team.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                }
            }

        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let deleteProjectSuccessful = expectation(description: "delete project")
        Amplify.DataStore.delete(project) { result in
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)

        // TODO: Delete Team should not be necessary, cascade delete should delete the team when deleting the project.
        // Once cascade works for hasOne, the following code can be removed.
        let deleteTeamSuccessful = expectation(description: "delete team")
        Amplify.DataStore.delete(team) { result in
            switch result {
            case .success:
                deleteTeamSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteTeamSuccessful, deleteReceived], timeout: TestCommonConstants.networkTimeout)

        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        Amplify.DataStore.query(Project2V2.self, byId: project.id) { result in
            switch result {
            case .success(let project):
                XCTAssertNil(project)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)

        let getTeamIsEmptySuccess = expectation(description: "get team after deleted project complete")
        Amplify.DataStore.query(Team2V2.self, byId: team.id) { result in
            switch result {
            case .success(let team):
                XCTAssertNil(team)
                getTeamIsEmptySuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getTeamIsEmptySuccess], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteWithValidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
            XCTFail("Could not save team and project")
            return
        }

        let deleteProjectSuccessful = expectation(description: "delete project")
        Amplify.DataStore.delete(project, where: Project2V2.keys.team.eq(team.id)) { result in
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        Amplify.DataStore.query(Project2V2.self, byId: project.id) { result in
            switch result {
            case .success(let project2):
                XCTAssertNil(project2)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteWithInvalidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
            XCTFail("Could not save team and project")
            return
        }

        let deleteProjectFailed = expectation(description: "delete project")
        Amplify.DataStore.delete(project, where: Project2V2.keys.team.eq("invalidTeamId")) { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                guard case .invalidCondition = error else {
                    XCTFail("\(error)")
                    return
                }
                deleteProjectFailed.fulfill()
            }
        }
        wait(for: [deleteProjectFailed], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        Amplify.DataStore.query(Project2V2.self, byId: project.id) { result in
            switch result {
            case .success(let project2):
                XCTAssertNotNil(project2)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAlreadyDeletedItemWithCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
            XCTFail("Could not save team and project")
            return
        }
        let deleteProjectSuccessful = expectation(description: "delete project")
        Amplify.DataStore.delete(project) { result in
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        Amplify.DataStore.query(Project2V2.self, byId: project.id) { result in
            switch result {
            case .success(let project2V2):
                XCTAssertNil(project2V2)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)

        let deleteProjectSuccessful2 = expectation(description: "delete project")
        Amplify.DataStore.delete(project, where: Project2V2.keys.teamID == team.id) { result in
            switch result {
            case .success:
                deleteProjectSuccessful2.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful2], timeout: TestCommonConstants.networkTimeout)
    }

    func testListProjectsByTeamID() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name") else {
            XCTFail("Could not save team")
            return
        }
        guard let project = saveProject(teamID: team.id, team: team) else {
            XCTFail("Could not save project")
            return
        }
        let listProjectByTeamIDCompleted = expectation(description: "list projects completed")
        let predicate = Project2V2.keys.teamID.eq(team.id)
        Amplify.DataStore.query(Project2V2.self, where: predicate) { result in
            switch result {
            case .success(let projects):
                XCTAssertEqual(projects.count, 1)
                XCTAssertEqual(projects[0].id, project.id)
                XCTAssertEqual(projects[0].teamID, team.id)
                listProjectByTeamIDCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listProjectByTeamIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func saveTeam(id: String = UUID().uuidString, name: String) -> Team2V2? {
        let team = Team2V2(id: id, name: name)
        var result: Team2V2?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(team) { event in
            switch event {
            case .success(let team):
                result = team
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveProject(id: String = UUID().uuidString,
                     name: String? = nil,
                     teamID: String,
                     team: Team2V2? = nil) -> Project2V2? {
        let project = Project2V2(id: id, name: name, teamID: teamID, team: team)
        var result: Project2V2?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(project) { event in
            switch event {
            case .success(let project):
                result = project
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
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
