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

    func testSaveTeamAndProjectSyncToCloud() throws {
        try startAmplifyAndWaitForSync()
        let team = Team1V2(name: "name1")
        // TODO: No need to add the `team` into the project, it is using explicit field `project1V2TeamId`
        let project = Project1V2(team: team, project1V2TeamId: team.id)
        let syncedTeamReceived = expectation(description: "received team from sync path")
        let syncProjectReceived = expectation(description: "received project from sync path")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedTeam = try? mutationEvent.decodeModel() as? Team1V2, syncedTeam.id == team.id {
                XCTAssertTrue(syncedTeam == team)
                syncedTeamReceived.fulfill()
            } else if let syncedProject = try? mutationEvent.decodeModel() as? Project1V2,
                        syncedProject.id == project.id {
                XCTAssertTrue(syncedProject == project)
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
        Amplify.DataStore.query(Project1V2.self, byId: project.id) { result in
            switch result {
            case .success(let queriedProjectOptional):
                guard let queriedProject = queriedProjectOptional else {
                    XCTFail("Failed")
                    return
                }
                XCTAssertEqual(queriedProject.id, project.id)
                // TODO: Should the queried project eager load the has-one team?
                // XCTAssertEqual(queriedProject.team, team)
                // or
                // access explicit field like this?
                XCTAssertEqual(queriedProject.project1V2TeamId, team.id)
                queriedProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedProjectCompleted], timeout: networkTimeout)
    }

    func testUpdateProjectWithAnotherTeam() throws {
        try startAmplifyAndWaitForSync()
        let team = Team1V2(name: "name1")
        let anotherTeam = Team1V2(name: "name1")
        // TODO: No need to add the `team` into the project, it is using explicit field `project1V2TeamId`
        var project = Project1V2(team: team, project1V2TeamId: team.id)
        let expectedUpdatedProject = Project1V2(id: project.id,
                                                name: project.name,
                                                team: anotherTeam, // Not needed
                                                project1V2TeamId: anotherTeam.id)
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
        project.project1V2TeamId = anotherTeam.id
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
        Amplify.DataStore.query(Project1V2.self, byId: project.id) { result in
            switch result {
            case .success(let queriedProjectOptional):
                XCTAssertNotNil(queriedProjectOptional)
                if let queriedProject = queriedProjectOptional {
                    XCTAssertEqual(queriedProject, project)
                    // TODO: Should the queried project eager load the has-one team?
                    // XCTAssertEqual(queriedProject.team, anotherTeam)
                    // or
                    // access explicit field like this?
                    XCTAssertEqual(queriedProject.project1V2TeamId, anotherTeam.id)
                }

                queriedProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedProjectCompleted, syncUpdatedProjectReceived], timeout: networkTimeout)
    }

    func testCreateUpdateDeleteAndGetProjectReturnsNil() throws {
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name"),
              var project = saveProject(project1V2TeamId: team.id) else {
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

            if let projectEvent = try? mutationEvent.decodeModel() as? Project1V2,
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
        Amplify.DataStore.query(Project1V2.self, byId: project.id) { result in
            switch result {
            case .success(let project):
                XCTAssertNil(project)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAndGetProjectReturnsNilWithSync() throws {
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name"),
              let project = saveProject(project1V2TeamId: team.id) else {
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

            if let projectEvent = try? mutationEvent.decodeModel() as? Project1V2,
               projectEvent.id == project.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                }

            } else if let teamEvent = try? mutationEvent.decodeModel() as? Team1V2, teamEvent.id == team.id {
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
        Amplify.DataStore.query(Project1V2.self, byId: project.id) { result in
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
        Amplify.DataStore.query(Team1V2.self, byId: team.id) { result in
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

    func testDeleteWithValidCondition() throws {
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name"),
              let project = saveProject(project1V2TeamId: team.id) else {
            XCTFail("Could not save team and project")
            return
        }

        let deleteProjectSuccessful = expectation(description: "delete project")
        Amplify.DataStore.delete(project, where: Project1V2.keys.team.eq(team.id)) { result in
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        Amplify.DataStore.query(Project1V2.self, byId: project.id) { result in
            switch result {
            case .success(let project):
                XCTAssertNil(project)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteWithInvalidCondition() throws {
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name"),
              let project = saveProject(project1V2TeamId: team.id) else {
            XCTFail("Could not save team and project")
            return
        }

        let deleteProjectFailed = expectation(description: "delete project")
        Amplify.DataStore.delete(project, where: Project1V2.keys.team.eq("invalidTeamId")) { result in
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
        Amplify.DataStore.query(Project1V2.self, byId: project.id) { result in
            switch result {
            case .success(let project):
                XCTAssertNotNil(project)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testListProjectsByTeamID() throws {
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name") else {
            XCTFail("Could not save team")
            return
        }
        guard let project = saveProject(project1V2TeamId: team.id) else {
            XCTFail("Could not save project")
            return
        }
        let listProjectByTeamIDCompleted = expectation(description: "list projects completed")
        let predicate = Project1V2.keys.team.eq(team.id)
        Amplify.DataStore.query(Project1V2.self, where: predicate) { result in
            switch result {
            case .success(let projects):
                XCTAssertEqual(projects.count, 1)
                XCTAssertEqual(projects[0].id, project.id)
                XCTAssertEqual(projects[0].project1V2TeamId, team.id)
                listProjectByTeamIDCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listProjectByTeamIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func saveTeam(id: String = UUID().uuidString, name: String) -> Team1V2? {
        let team = Team1V2(id: id, name: name)
        var result: Team1V2?
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
                     project1V2TeamId: String?,
                     team: Team1V2? = nil) -> Project1V2? {
        let project = Project1V2(id: id, name: name, team: team, project1V2TeamId: project1V2TeamId)
        var result: Project1V2?
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
