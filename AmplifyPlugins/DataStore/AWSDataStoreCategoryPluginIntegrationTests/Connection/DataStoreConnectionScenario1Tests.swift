//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyPlugins
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

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

    func testSaveTeamAndProjectSyncToCloud() throws {
        try startAmplifyAndWaitForSync()
        let team = Team1(name: "name1")
        let project = Project1(team: team)
        let syncedTeamReceived = expectation(description: "received team from sync path")
        let syncProjectReceived = expectation(description: "received project from sync path")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedTeam = try? mutationEvent.decodeModel() as? Team1,
               syncedTeam == team {
                syncedTeamReceived.fulfill()
            } else if let syncedProject = try? mutationEvent.decodeModel() as? Project1,
                      syncedProject == project {
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
        Amplify.DataStore.query(Project1.self, byId: project.id) { result in
            switch result {
            case .success(let queriedProjectOptional):
                guard let queriedProject = queriedProjectOptional else {
                    XCTFail("Failed")
                    return
                }
                XCTAssertEqual(queriedProject.id, project.id)
                XCTAssertEqual(queriedProject.team, team)
                queriedProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedProjectCompleted], timeout: networkTimeout)
    }

    func testUpdateProjectWithAnotherTeam() throws {
        try startAmplifyAndWaitForSync()
        let team = Team1(name: "name1")
        let anotherTeam = Team1(name: "name1")
        var project = Project1(team: team)
        let expectedUpdatedProject = Project1(id: project.id, name: project.name, team: anotherTeam)
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
        Amplify.DataStore.query(Project1.self, byId: project.id) { result in
            switch result {
            case .success(let queriedProjectOptional):
                XCTAssertNotNil(queriedProjectOptional)
                if let queriedProject = queriedProjectOptional {
                    XCTAssertEqual(queriedProject, project)
                    XCTAssertEqual(queriedProject.team, anotherTeam)
                }

                queriedProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedProjectCompleted, syncUpdatedProjectReceived], timeout: networkTimeout)
    }

    func testDeleteAndGetProject() throws {
        try startAmplifyAndWaitForSync()
        guard let team = saveTeam(name: "name") else {
            XCTFail("Could not save team")
            return
        }
        guard let project = saveProject(teamID: team.id, team: team) else {
            XCTFail("Could not save project")
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
        Amplify.DataStore.query(Project1.self, byId: project.id) { result in
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

    // TODO: This test will fail until https://github.com/aws-amplify/amplify-ios/pull/885 is merged in
    func testListProjectsByTeamID() throws {
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
        let predicate = Project1.keys.team.eq(team.id)
        Amplify.DataStore.query(Project1.self, where: predicate) { result in
            switch result {
            case .success(let projects):
                XCTAssertEqual(projects.count, 1)
                XCTAssertEqual(projects[0].id, project.id)
                XCTAssertEqual(projects[0].team, team)
                listProjectByTeamIDCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listProjectByTeamIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func saveTeam(id: String = UUID().uuidString, name: String) -> Team1? {
        let team = Team1(id: id, name: name)
        var result: Team1?
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
                     team: Team1? = nil) -> Project1? {
        let project = Project1(id: id, name: name, team: team)
        var result: Project1?
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
