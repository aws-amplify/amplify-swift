//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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

class DataStoreConnectionScenario1FlutterTests: SyncEngineFlutterIntegrationTestBase {

    func testSaveTeamAndProjectSyncToCloud() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
<<<<<<< HEAD
        let team = try TeamWrapper(name: "team1")
        let project = try Project1Wrapper(team: team.model)
=======
        let team = try TestTeam(name: "team1")
        let project = try TestProject(team: team.model)
>>>>>>> flutter integ tests initial commit
        
        let syncedTeamReceived = expectation(description: "received team from sync path")
        let syncProjectReceived = expectation(description: "received project from sync path")
        
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

<<<<<<< HEAD
            if let syncedTeam = mutationEvent.modelId as String?,
               syncedTeam == team.idString() {
                syncedTeamReceived.fulfill()
            }
            else if let syncedProject = mutationEvent.modelId as String?,
=======
            // TODO: Should this be modelId, or id?
            if let syncedTeam = try? mutationEvent.modelId as String,
               syncedTeam == team.idString() {
                syncedTeamReceived.fulfill()
            }
            else if let syncedProject = try? mutationEvent.modelId as String,
>>>>>>> flutter integ tests initial commit
                    syncedProject == project.idString() {
                syncProjectReceived.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let saveTeamCompleted = expectation(description: "save team completed")
        plugin.save(team.model, modelSchema: Team1.schema) { result in
            switch result {
            case .success:
                saveTeamCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveTeamCompleted, syncedTeamReceived], timeout: networkTimeout)
        let saveProjectCompleted = expectation(description: "save project completed")
        plugin.save(project.model, modelSchema: Project1.schema) { result in
            switch result {
            case .success:
                saveProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveProjectCompleted, syncProjectReceived], timeout: networkTimeout)

        let queriedProjectCompleted = expectation(description: "query project completed")
        plugin.query(FlutterSerializedModel.self, modelSchema: Project1.schema, where: Project1.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let queriedProjectList):
                guard queriedProjectList.count == 1 else {
                    XCTFail("project query failed")
                    return
                }
<<<<<<< HEAD
                let queriedProject = Project1Wrapper(model: queriedProjectList[0])
                XCTAssertEqual(queriedProject.idString(), project.idString())
                XCTAssertEqual(queriedProject.teamId(), project.teamId())
=======
                let queriedProject = TestProject(model: queriedProjectList[0])
                XCTAssertEqual(queriedProject.idString(), project.idString())
                XCTAssertEqual(queriedProject.teamId(), project.teamId())
                // TODO: Investigate null non-id values
>>>>>>> flutter integ tests initial commit
                queriedProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }

        wait(for: [queriedProjectCompleted], timeout: networkTimeout)
    }

    func testUpdateProjectWithAnotherTeam() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> flutter integ tests
        let team = try TeamWrapper(name: "name1")
        let anotherTeam = try TeamWrapper(name: "name1")
        let project = try Project1Wrapper(team: team.model)
        let expectedUpdatedProject = project.copy() as! Project1Wrapper
<<<<<<< HEAD
=======
        let team = try TestTeam(name: "name1")
        let anotherTeam = try TestTeam(name: "name1")
        let project = try TestProject(team: team.model)
        let expectedUpdatedProject = project.copy() as! TestProject
>>>>>>> rebasing
=======
>>>>>>> flutter integ tests
=======
        let team = try TestTeam(name: "name1")
        var anotherTeam = try TestTeam(name: "name1")
        var project = try TestProject(team: team.model)
//        let expectedUpdatedProject = Project1(id: project.id, name: project.name, team: anotherTeam)
        let expectedUpdatedProject = project.copy() as! TestProject
>>>>>>> flutter integ tests initial commit
        try expectedUpdatedProject.setTeam(team: anotherTeam.model)
        
        let syncUpdatedProjectReceived = expectation(description: "received updated project from sync path")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedUpdatedProject = try? mutationEvent.modelId as String,
               expectedUpdatedProject.idString() == syncedUpdatedProject {
                syncUpdatedProjectReceived.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let saveTeamCompleted = expectation(description: "save team completed")
        plugin.save(team.model, modelSchema: Team1.schema) { result in
            switch result {
            case .success:
                saveTeamCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveTeamCompleted], timeout: networkTimeout)
        let saveAnotherTeamCompleted = expectation(description: "save team completed")
        plugin.save(anotherTeam.model, modelSchema: Team1.schema) { result in
            switch result {
            case .success:
                saveAnotherTeamCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveAnotherTeamCompleted], timeout: networkTimeout)

        let saveProjectCompleted = expectation(description: "save project completed")
        plugin.save(project.model, modelSchema: Project1.schema) { result in
            switch result {
            case .success:
                saveProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveProjectCompleted], timeout: networkTimeout)

        let updateProjectCompleted = expectation(description: "save project completed")
        try project.setTeam(team: anotherTeam.model)
        plugin.save(project.model, modelSchema: Project1.schema) { result in
            switch result {
            case .success:
                updateProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [updateProjectCompleted], timeout: networkTimeout)
        
        let queriedProjectCompleted = expectation(description: "query project completed")
        plugin.query(FlutterSerializedModel.self, modelSchema: Project1.schema, where: Project1.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let queriedProjectList):
                
                guard queriedProjectList.count == 1 else {
                    XCTFail("project query failed")
                    return
                }
<<<<<<< HEAD
                let queriedProject = Project1Wrapper(model: queriedProjectList[0])
                XCTAssertEqual(queriedProject.idString(), project.idString())

=======
                let queriedProject = TestProject(model: queriedProjectList[0])
                XCTAssertEqual(queriedProject.idString(), project.idString())

                // TODO: Investigate null non-id values
>>>>>>> flutter integ tests initial commit
                queriedProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedProjectCompleted, syncUpdatedProjectReceived], timeout: networkTimeout)
    }

    func testDeleteAndGetProject() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name"),
              let project = try saveProject(team: team) else {
            XCTFail("Could not save team and project")
            return
        }

        let deleteProjectSuccessful = expectation(description: "delete project")
        plugin.delete(project.model, modelSchema: Project1.schema) { result in
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        plugin.query(FlutterSerializedModel.self, modelSchema: Project1.schema, where: Project1.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let project):
                XCTAssertEqual(0, project.count)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteWithValidCondition() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name"),
              let project = try saveProject(team: team) else {
            XCTFail("Could not save team and project")
            return
        }
        
        let queriedProjectExpect1Successful = expectation(description: "delete project")
        let queriedProjectExpect1 = queryProject(id: project.model.id)
        XCTAssertNotNil(queriedProjectExpect1)
        XCTAssertEqual(1, queriedProjectExpect1!.count)
        XCTAssertEqual(project.idString(), queriedProjectExpect1![0].id)
        if (queriedProjectExpect1!.count == 1) {
            queriedProjectExpect1Successful.fulfill()
        }
        wait(for: [queriedProjectExpect1Successful], timeout: TestCommonConstants.networkTimeout)

        
        let deleteProjectSuccessful = expectation(description: "delete project")
<<<<<<< HEAD
        plugin.delete(project.model, modelSchema: Project1.schema,  where: Project1.keys.id.eq(project.idString())) { result in
=======
        plugin.delete(project.model, modelSchema: Project1.schema) { result in
>>>>>>> flutter integ tests initial commit
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        let queriedProjectExpect0 = queryProject(id: project.model.id)
        XCTAssertNotNil(queriedProjectExpect0)
        XCTAssertEqual(0, queriedProjectExpect0!.count)
        if (queriedProjectExpect0!.count == 0) {
            getProjectAfterDeleteCompleted.fulfill()
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

<<<<<<< HEAD
    func testDeleteWithInvalidCondition() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name"),
              let project = try saveProject(team: team) else {
            XCTFail("Could not save team and project")
            return
        }

        let queriedProjectExpect1Successful = expectation(description: "delete project")
        let queriedProjectExpect1 = queryProject(id: project.model.id)
        XCTAssertNotNil(queriedProjectExpect1)
        XCTAssertEqual(1, queriedProjectExpect1!.count)
        XCTAssertEqual(project.idString(), queriedProjectExpect1![0].id)
        if (queriedProjectExpect1!.count == 1) {
            queriedProjectExpect1Successful.fulfill()
        }
        wait(for: [queriedProjectExpect1Successful], timeout: TestCommonConstants.networkTimeout)

        let deleteProjectFailed = expectation(description: "delete project")
        plugin.delete(project.model, modelSchema: Project1.schema, where: Project1.keys.id.eq("invalid")) { result in
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
        let queriedProjectExpectUnDeleted = queryProject(id: project.model.id)
        XCTAssertNotNil(queriedProjectExpectUnDeleted)
        XCTAssertEqual(1, queriedProjectExpectUnDeleted!.count)
        XCTAssertEqual(project.idString(), queriedProjectExpectUnDeleted![0].id)
        if (queriedProjectExpectUnDeleted!.count == 1) {
            getProjectAfterDeleteCompleted.fulfill()
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }
=======
//    func testDeleteWithInvalidCondition() throws {
//        try startAmplifyAndWaitForSync()
//        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
//        guard let team = try saveTeam(name: "name"),
//              let project = try saveProject(team: team) else {
//            XCTFail("Could not save team and project")
//            return
//        }
//
//        let queriedProjectExpect1Successful = expectation(description: "delete project")
//        let queriedProjectExpect1 = queryProject(id: project.model.id)
//        XCTAssertNotNil(queriedProjectExpect1)
//        XCTAssertEqual(1, queriedProjectExpect1!.count)
//        XCTAssertEqual(project.idString(), queriedProjectExpect1![0].id)
//        if (queriedProjectExpect1!.count == 1) {
//            queriedProjectExpect1Successful.fulfill()
//        }
//        wait(for: [queriedProjectExpect1Successful], timeout: TestCommonConstants.networkTimeout)
//
//        let deleteProjectVoidReturn = expectation(description: "delete project")
//        plugin.delete(project.model, modelSchema: Project1.schema, where: Project1.keys.id.eq("invalid")) { result in
//            switch result {
//            case .success:
//                deleteProjectVoidReturn.fulfill()
//            case .failure(let error):
//                XCTFail("\(error)")
//            }
//        }
//        wait(for: [deleteProjectVoidReturn], timeout: TestCommonConstants.networkTimeout)
//
//        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
//        let queriedProjectExpectUnDeleted = queryProject(id: project.model.id)
//        XCTAssertNotNil(queriedProjectExpectUnDeleted)
//        XCTAssertEqual(1, queriedProjectExpectUnDeleted!.count)
//        XCTAssertEqual(project.idString(), queriedProjectExpectUnDeleted![0].id)
//        if (queriedProjectExpectUnDeleted!.count == 1) {
//            getProjectAfterDeleteCompleted.fulfill()
//        }
//        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
//    }
>>>>>>> flutter integ tests initial commit

    func testListProjectsByTeamID() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name") else {
            XCTFail("Could not save team")
            return
        }
        guard let project = try saveProject(team: team) else {
            XCTFail("Could not save project")
            return
        }
        let listProjectByTeamIDCompleted = expectation(description: "list projects completed")
        let predicate = Project1.keys.team.eq(team.idString())
        plugin.query(FlutterSerializedModel.self, modelSchema: Project1.schema, where: predicate) { result in
            switch result {
            case .success(let projects):
                XCTAssertEqual(projects.count, 1)
                XCTAssertEqual(projects[0].id, project.idString())
                XCTAssertEqual(projects[0].values, project.model.values)
                listProjectByTeamIDCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listProjectByTeamIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

<<<<<<< HEAD
    func saveTeam(name: String) throws -> TeamWrapper? {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let team = try TeamWrapper(name: name)
=======
    func saveTeam(name: String) throws -> TestTeam? {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let team = try TestTeam(name: name)
>>>>>>> flutter integ tests initial commit
        var result: FlutterSerializedModel?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(team.model, modelSchema: Team1.schema) { event in
            switch event {
            case .success(let team):
                result = team
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
<<<<<<< HEAD
        return TeamWrapper(model: result!)
    }

    func saveProject(name: String = "project",
                     team: TeamWrapper) throws -> Project1Wrapper? {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let project = try Project1Wrapper(name: name, team: team.model)
=======
        return TestTeam(model: result!)
    }

    func saveProject(name: String = "project",
                     team: TestTeam) throws -> TestProject? {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let project = try TestProject(name: name, team: team.model)
>>>>>>> flutter integ tests initial commit
        var result: FlutterSerializedModel?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(project.model, modelSchema: Project1.schema) { event in
            switch event {
            case .success(let project):
                result = project
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
<<<<<<< HEAD
        return Project1Wrapper(model: result!)
=======
        return TestProject(model: result!)
>>>>>>> flutter integ tests initial commit
    }
    
    func queryProject(id: String) -> [FlutterSerializedModel]? {
        var queryResults: [FlutterSerializedModel]?
        do {
            let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
            plugin.query(FlutterSerializedModel.self, modelSchema: Project1.schema, where: Project1.keys.id.eq(id)) { result in
                switch result {
                case .success(let queriedProject):
                    queryResults = queriedProject
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
        } catch {
            XCTFail("failed \(error)")
        }
        return queryResults
    }
}
