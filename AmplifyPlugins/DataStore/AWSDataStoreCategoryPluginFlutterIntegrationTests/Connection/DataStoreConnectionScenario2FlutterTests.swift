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
 A one-to-one connection where a project has one team,
 with a field you would like to use for the connection.
 ```
 type Project2 @model {
   id: ID!
   name: String
   teamID: ID!
   team: Team2 @connection(fields: ["teamID"])
 }

 type Team2 @model {
   id: ID!
   name: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */

class DataStoreConnectionScenario2FlutterTests: SyncEngineFlutterIntegrationTestBase {

    func testSaveTeamAndProjectSyncToCloud() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        let team = try TeamWrapper(name: "name1")
        let project = try Project2Wrapper(name: "project1", team: team.model, teamID: team.idString())
=======
        let team = try TestTeam(name: "name1")
        let project = try TestProject2(name: "project1", team: team.model, teamID: team.idString())
>>>>>>> rebasing
=======
        let team = try TeamWrapper(name: "name1")
        let project = try Project2Wrapper(name: "project1", team: team.model, teamID: team.idString())
>>>>>>> flutter integ tests
=======
        let team = try TestTeam(name: "name1")
        let project = try TestProject2(name: "project1", team: team.model, teamID: team.idString())
>>>>>>> rebasing
        let syncedTeamReceived = expectation(description: "received team from sync event")
        let syncProjectReceived = expectation(description: "received project from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
            if let syncedTeam = mutationEvent.modelId as String?,
               syncedTeam == team.idString() {
                syncedTeamReceived.fulfill()
            } else if let syncedProject = mutationEvent.modelId as String?,
=======
=======
>>>>>>> rebasing
            if let syncedTeam = try? mutationEvent.modelId as String,
               syncedTeam == team.idString() {
                syncedTeamReceived.fulfill()
            } else if let syncedProject = try? mutationEvent.modelId as String,
<<<<<<< HEAD
>>>>>>> rebasing
=======
            if let syncedTeam = mutationEvent.modelId as String?,
               syncedTeam == team.idString() {
                syncedTeamReceived.fulfill()
            } else if let syncedProject = mutationEvent.modelId as String?,
>>>>>>> flutter integ tests
=======
>>>>>>> rebasing
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
        plugin.save(project.model,  modelSchema: Project2.schema) { result in
            switch result {
            case .success:
                saveProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }

        wait(for: [saveProjectCompleted, syncProjectReceived], timeout: networkTimeout)

        let queriedProjectCompleted = expectation(description: "query project completed")
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let queriedProjectList):
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
                let queriedProject = Project2Wrapper(model: queriedProjectList[0])
=======
                let queriedProject = TestProject(model: queriedProjectList[0])
>>>>>>> rebasing
=======
                let queriedProject = Project2Wrapper(model: queriedProjectList[0])
>>>>>>> flutter integ tests
=======
                let queriedProject = TestProject(model: queriedProjectList[0])
>>>>>>> rebasing
                XCTAssertEqual(queriedProject.idString(), project.idString())
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
        var anotherTeam = try TeamWrapper(name: "name1")
        let project = try Project2Wrapper(name: "project1", team: team.model, teamID: team.idString())
        let expectedUpdatedProject = project.copy() as! Project2Wrapper
        try expectedUpdatedProject.setTeam(name: "project1", team: anotherTeam.model, teamID: anotherTeam.idString())
<<<<<<< HEAD
=======
=======
>>>>>>> rebasing
        let team = try TestTeam(name: "name1")
        let anotherTeam = try TestTeam(name: "name1")
        var project = try TestProject2(name: "project1", team: team.model, teamID: team.idString())
        let expectedUpdatedProject = project.copy() as! TestProject
        try expectedUpdatedProject.setTeam(team: anotherTeam.model)
<<<<<<< HEAD
>>>>>>> rebasing
=======
>>>>>>> flutter integ tests
=======
>>>>>>> rebasing
        
        let syncUpdatedProjectReceived = expectation(description: "received updated project from sync path")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
            if let syncedUpdatedProject = mutationEvent.modelId as String?,
=======
            if let syncedUpdatedProject = try? mutationEvent.modelId as String,
>>>>>>> rebasing
=======
            if let syncedUpdatedProject = mutationEvent.modelId as String?,
>>>>>>> flutter integ tests
=======
            if let syncedUpdatedProject = try? mutationEvent.modelId as String,
>>>>>>> rebasing
               expectedUpdatedProject.idString() == syncedUpdatedProject {
                syncUpdatedProjectReceived.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let saveTeamCompleted = expectation(description: "save team completed")
        plugin.save(team.model, modelSchema: Team2.schema) { result in
            switch result {
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
            case .success(let savedTeam):
                anotherTeam = TeamWrapper(model: savedTeam)
=======
            case .success:
>>>>>>> rebasing
=======
            case .success(let savedTeam):
                anotherTeam = TeamWrapper(model: savedTeam)
>>>>>>> flutter integ tests
=======
            case .success:
>>>>>>> rebasing
                saveTeamCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveTeamCompleted], timeout: networkTimeout)
        let saveAnotherTeamCompleted = expectation(description: "save team completed")
        plugin.save(anotherTeam.model, modelSchema: Team2.schema) { result in
            switch result {
            case .success:
                saveAnotherTeamCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveAnotherTeamCompleted], timeout: networkTimeout)

        let saveProjectCompleted = expectation(description: "save project completed")
        plugin.save(project.model, modelSchema: Project2.schema) { result in
            switch result {
            case .success:
                saveProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveProjectCompleted], timeout: networkTimeout)

        let updateProjectCompleted = expectation(description: "save project completed")
        try project.setTeam(name: "project1", team: anotherTeam.model, teamID: anotherTeam.idString())
        plugin.save(project.model, modelSchema: Project2.schema) { result in
            switch result {
            case .success:
                updateProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [updateProjectCompleted], timeout: networkTimeout)

        let queriedProjectCompleted = expectation(description: "query project completed")
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let queriedProjectList):
                guard queriedProjectList.count == 1 else {
                    XCTFail("project query failed")
                    return
                }
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
                let queriedProject = Project2Wrapper(model: queriedProjectList[0])
                XCTAssertEqual(queriedProject.idString(), project.idString())
                XCTAssertEqual(queriedProject.teamID(), anotherTeam.id())
=======
                let queriedProject = TestProject2(model: queriedProjectList[0])
                XCTAssertEqual(queriedProject.idString(), project.idString())
//                XCTAssertEqual(queriedProject.teamID(), anotherTeam.idString())
>>>>>>> rebasing
=======
                let queriedProject = Project2Wrapper(model: queriedProjectList[0])
                XCTAssertEqual(queriedProject.idString(), project.idString())
                XCTAssertEqual(queriedProject.teamID(), anotherTeam.id())
>>>>>>> flutter integ tests
=======
                let queriedProject = TestProject2(model: queriedProjectList[0])
                XCTAssertEqual(queriedProject.idString(), project.idString())
//                XCTAssertEqual(queriedProject.teamID(), anotherTeam.idString())
>>>>>>> rebasing
                queriedProjectCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }  
        }
        wait(for: [queriedProjectCompleted, syncUpdatedProjectReceived], timeout: networkTimeout)
    }

    func testDeleteAndGetProject() throws {
        try startAmplifyAndWaitForSync()
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
=======
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
>>>>>>> rebasing
=======
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
>>>>>>> more flutter integ tests
=======
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
>>>>>>> rebasing
=======
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
>>>>>>> more flutter integ tests
            XCTFail("Could not save team and project")
            return
        }

        let deleteProjectSuccessful = expectation(description: "delete project")
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        plugin.delete(project.model, modelSchema: Project2.schema) { result in
=======
        Amplify.DataStore.delete(project) { result in
>>>>>>> rebasing
=======
        plugin.delete(project.model, modelSchema: Project2.schema) { result in
>>>>>>> more flutter integ tests
=======
        Amplify.DataStore.delete(project) { result in
>>>>>>> rebasing
=======
        plugin.delete(project.model, modelSchema: Project2.schema) { result in
>>>>>>> more flutter integ tests
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
=======
=======
>>>>>>> rebasing
        Amplify.DataStore.query(Project2.self, byId: project.id) { result in
            switch result {
            case .success(let project2):
                XCTAssertNil(project2)
<<<<<<< HEAD
>>>>>>> rebasing
=======
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
>>>>>>> more flutter integ tests
=======
>>>>>>> rebasing
=======
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
>>>>>>> more flutter integ tests
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteWithValidCondition() throws {
        try startAmplifyAndWaitForSync()
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> more flutter integ tests
=======
>>>>>>> more flutter integ tests
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let team = try saveTeam(name: "name", plugin: plugin)
        let project = try saveProject(teamID: team!.idString(), team: team!, plugin: plugin)
        
<<<<<<< HEAD
<<<<<<< HEAD
        let deleteProjectSuccessful = expectation(description: "delete project")
        plugin.delete(project!.model, modelSchema: Project2.schema, where: Project2.keys.teamID.eq(team!.idString())) { result in
=======
=======
>>>>>>> rebasing
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
            XCTFail("Could not save team and project")
            return
        }

        let deleteProjectSuccessful = expectation(description: "delete project")
        Amplify.DataStore.delete(project, where: Project2.keys.team.eq(team.id)) { result in
<<<<<<< HEAD
>>>>>>> rebasing
=======
        let deleteProjectSuccessful = expectation(description: "delete project")
        plugin.delete(project!.model, modelSchema: Project2.schema, where: Project2.keys.teamID.eq(team!.idString())) { result in
>>>>>>> more flutter integ tests
=======
>>>>>>> rebasing
=======
        let deleteProjectSuccessful = expectation(description: "delete project")
        plugin.delete(project!.model, modelSchema: Project2.schema, where: Project2.keys.teamID.eq(team!.idString())) { result in
>>>>>>> more flutter integ tests
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project!.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
=======
=======
>>>>>>> rebasing
        Amplify.DataStore.query(Project2.self, byId: project.id) { result in
            switch result {
            case .success(let project2):
                XCTAssertNil(project2)
<<<<<<< HEAD
>>>>>>> rebasing
=======
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project!.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
>>>>>>> more flutter integ tests
=======
>>>>>>> rebasing
=======
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project!.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
>>>>>>> more flutter integ tests
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteWithInvalidCondition() throws {
        try startAmplifyAndWaitForSync()
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
=======
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
>>>>>>> rebasing
=======
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
>>>>>>> more flutter integ tests
=======
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
>>>>>>> rebasing
=======
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
>>>>>>> more flutter integ tests
            XCTFail("Could not save team and project")
            return
        }

        let deleteProjectFailed = expectation(description: "delete project")
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        plugin.delete(project.model, modelSchema: Project2.schema, where: Project2.keys.id.eq("invalidTeamId")) { result in
=======
        Amplify.DataStore.delete(project, where: Project2.keys.team.eq("invalidTeamId")) { result in
>>>>>>> rebasing
=======
        plugin.delete(project.model, modelSchema: Project2.schema, where: Project2.keys.id.eq("invalidTeamId")) { result in
>>>>>>> more flutter integ tests
=======
        Amplify.DataStore.delete(project, where: Project2.keys.team.eq("invalidTeamId")) { result in
>>>>>>> rebasing
=======
        plugin.delete(project.model, modelSchema: Project2.schema, where: Project2.keys.id.eq("invalidTeamId")) { result in
>>>>>>> more flutter integ tests
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
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project.model.id)) { result in
=======
        Amplify.DataStore.query(Project2.self, byId: project.id) { result in
>>>>>>> rebasing
=======
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project.model.id)) { result in
>>>>>>> more flutter integ tests
=======
        Amplify.DataStore.query(Project2.self, byId: project.id) { result in
>>>>>>> rebasing
=======
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project.model.id)) { result in
>>>>>>> more flutter integ tests
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

    func testDeleteAlreadyDeletedItemWithCondition() throws {
        try startAmplifyAndWaitForSync()
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
=======
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
>>>>>>> rebasing
=======
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
>>>>>>> more flutter integ tests
=======
        guard let team = saveTeam(name: "name"),
              let project = saveProject(teamID: team.id, team: team) else {
>>>>>>> rebasing
=======
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
>>>>>>> more flutter integ tests
            XCTFail("Could not save team and project")
            return
        }
        let deleteProjectSuccessful = expectation(description: "delete project")
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        plugin.delete(project.model, modelSchema: Project2.schema) { result in
=======
        Amplify.DataStore.delete(project) { result in
>>>>>>> rebasing
=======
        plugin.delete(project.model, modelSchema: Project2.schema) { result in
>>>>>>> more flutter integ tests
=======
        Amplify.DataStore.delete(project) { result in
>>>>>>> rebasing
=======
        plugin.delete(project.model, modelSchema: Project2.schema) { result in
>>>>>>> more flutter integ tests
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
=======
=======
>>>>>>> rebasing
        Amplify.DataStore.query(Project2.self, byId: project.id) { result in
            switch result {
            case .success(let project2):
                XCTAssertNil(project2)
<<<<<<< HEAD
>>>>>>> rebasing
=======
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
>>>>>>> more flutter integ tests
=======
>>>>>>> rebasing
=======
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
>>>>>>> more flutter integ tests
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        let deleteProjectSuccessful2 = expectation(description: "delete project")
        plugin.delete(project.model, modelSchema: Project2.schema, where: Project2.keys.teamID.eq(team.idString())) { result in
=======

        let deleteProjectSuccessful2 = expectation(description: "delete project")
        Amplify.DataStore.delete(project, where: Project2.keys.teamID == team.id) { result in
>>>>>>> rebasing
=======
        let deleteProjectSuccessful2 = expectation(description: "delete project")
        plugin.delete(project.model, modelSchema: Project2.schema, where: Project2.keys.teamID.eq(team.idString())) { result in
>>>>>>> more flutter integ tests
=======

        let deleteProjectSuccessful2 = expectation(description: "delete project")
        Amplify.DataStore.delete(project, where: Project2.keys.teamID == team.id) { result in
>>>>>>> rebasing
=======
        let deleteProjectSuccessful2 = expectation(description: "delete project")
        plugin.delete(project.model, modelSchema: Project2.schema, where: Project2.keys.teamID.eq(team.idString())) { result in
>>>>>>> more flutter integ tests
            switch result {
            case .success:
                deleteProjectSuccessful2.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful2], timeout: TestCommonConstants.networkTimeout)
    }

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> flutter integ tests
=======
>>>>>>> flutter integ tests
    func testListProjectsByTeamID() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin) else {
            XCTFail("Could not save team")
            return
        }
        guard let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
<<<<<<< HEAD
=======
    func testListProjectsByTeamID() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin) else {
            XCTFail("Could not save team")
            return
        }
<<<<<<< HEAD
        guard let project = saveProject(teamID: team.id, team: team) else {
>>>>>>> rebasing
=======
        guard let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
>>>>>>> more flutter integ tests
=======
>>>>>>> flutter integ tests
=======
    func testListProjectsByTeamID() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin) else {
            XCTFail("Could not save team")
            return
        }
<<<<<<< HEAD
        guard let project = saveProject(teamID: team.id, team: team) else {
>>>>>>> rebasing
=======
        guard let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
>>>>>>> more flutter integ tests
            XCTFail("Could not save project")
            return
        }
        let listProjectByTeamIDCompleted = expectation(description: "list projects completed")
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> flutter integ tests
        let predicate = Project2.keys.teamID.eq(team.idString())
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: predicate) { result in
            switch result {
            case .success(let projects):
<<<<<<< HEAD
<<<<<<< HEAD
                let project = TestProject2(model: projects[0])
                XCTAssertEqual(projects.count, 1)
<<<<<<< HEAD
                let returnedProject = Project2Wrapper(model: projects[0])
                XCTAssertEqual(returnedProject.idString(), project.idString())
                XCTAssertEqual(returnedProject.teamID(), team.id())
=======
                XCTAssertEqual(project.idString(), project.idString())
                XCTAssertEqual(project.teamID(), team.id())
>>>>>>> more flutter integ tests
=======
                XCTAssertEqual(projects.count, 1)
                let returnedProject = Project2Wrapper(model: projects[0])
                XCTAssertEqual(returnedProject.idString(), project.idString())
                XCTAssertEqual(returnedProject.teamID(), team.id())
>>>>>>> flutter integ tests
=======
        let predicate = Project2.keys.teamID.eq(team.id)
        Amplify.DataStore.query(Project2.self, where: predicate) { result in
=======
        let predicate = Project2.keys.teamID.eq(team.idString())
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: predicate) { result in
>>>>>>> more flutter integ tests
=======
        let predicate = Project2.keys.teamID.eq(team.idString())
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: predicate) { result in
>>>>>>> more flutter integ tests
            switch result {
            case .success(let projects):
                let project = TestProject2(model: projects[0])
                XCTAssertEqual(projects.count, 1)
<<<<<<< HEAD
<<<<<<< HEAD
                XCTAssertEqual(projects[0].id, project.id)
                XCTAssertEqual(projects[0].teamID, team.id)
>>>>>>> rebasing
=======
                XCTAssertEqual(project.idString(), project.idString())
                XCTAssertEqual(project.teamID(), team.id())
>>>>>>> more flutter integ tests
=======
                XCTAssertEqual(projects.count, 1)
                let returnedProject = Project2Wrapper(model: projects[0])
                XCTAssertEqual(returnedProject.idString(), project.idString())
                XCTAssertEqual(returnedProject.teamID(), team.id())
>>>>>>> flutter integ tests
=======
        let predicate = Project2.keys.teamID.eq(team.id)
        Amplify.DataStore.query(Project2.self, where: predicate) { result in
            switch result {
            case .success(let projects):
                XCTAssertEqual(projects.count, 1)
                XCTAssertEqual(projects[0].id, project.id)
                XCTAssertEqual(projects[0].teamID, team.id)
>>>>>>> rebasing
=======
                XCTAssertEqual(project.idString(), project.idString())
                XCTAssertEqual(project.teamID(), team.id())
>>>>>>> more flutter integ tests
                listProjectByTeamIDCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listProjectByTeamIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> registration changes
//    func testListProjectsByTeamID() throws {
//        try startAmplifyAndWaitForSync()
//        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
//        guard let team = try saveTeam(name: "name", plugin: plugin) else {
//            XCTFail("Could not save team")
//            return
//        }
//        guard let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
//            XCTFail("Could not save project")
//            return
//        }
//        let listProjectByTeamIDCompleted = expectation(description: "list projects completed")
//        let predicate = Project2.keys.teamID.eq(team.idString())
//        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: predicate) { result in
//            switch result {
//            case .success(let projects):
//                let project = TestProject2(model: projects[0])
//                XCTAssertEqual(projects.count, 1)
//                XCTAssertEqual(project.idString(), project.idString())
//                XCTAssertEqual(project.teamID(), team.id())
//                listProjectByTeamIDCompleted.fulfill()
//            case .failure(let error):
//                XCTFail("\(error)")
//            }
//        }
//        wait(for: [listProjectByTeamIDCompleted], timeout: TestCommonConstants.networkTimeout)
//    }
<<<<<<< HEAD
>>>>>>> registration changes
    
<<<<<<< HEAD
    func saveTeam(name: String, plugin: AWSDataStorePlugin) throws -> TeamWrapper? {
        let team = try TeamWrapper(name: name)
        var result: TeamWrapper?
=======
    func saveTeam(name: String, plugin: AWSDataStorePlugin) throws -> TestTeam? {
        let team = try TestTeam(name: name)
        var result: TestTeam?
>>>>>>> more flutter integ tests
=======
    
    func saveTeam(name: String, plugin: AWSDataStorePlugin) throws -> TeamWrapper? {
        let team = try TeamWrapper(name: name)
        var result: TeamWrapper?
>>>>>>> flutter integ tests
        let completeInvoked = expectation(description: "request completed")
        plugin.save(team.model, modelSchema: Team2.schema) { event in
            switch event {
            case .success(let team):
<<<<<<< HEAD
<<<<<<< HEAD
                result = TeamWrapper(model: team)
=======
                result = TestTeam(model: team)
>>>>>>> more flutter integ tests
=======
                result = TeamWrapper(model: team)
>>>>>>> flutter integ tests
=======
=======
>>>>>>> rebasing

    func saveTeam(id: String = UUID().uuidString, name: String) -> Team2? {
        let team = Team2(id: id, name: name)
        var result: Team2?
<<<<<<< HEAD
=======
=======
>>>>>>> registration changes
    
    func saveTeam(name: String, plugin: AWSDataStorePlugin) throws -> TestTeam? {
        let team = try TestTeam(name: name)
        var result: TestTeam?
>>>>>>> more flutter integ tests
=======
    
    func saveTeam(name: String, plugin: AWSDataStorePlugin) throws -> TeamWrapper? {
        let team = try TeamWrapper(name: name)
        var result: TeamWrapper?
>>>>>>> flutter integ tests
        let completeInvoked = expectation(description: "request completed")
        plugin.save(team.model, modelSchema: Team2.schema) { event in
            switch event {
            case .success(let team):
<<<<<<< HEAD
<<<<<<< HEAD
                result = team
>>>>>>> rebasing
=======
                result = TestTeam(model: team)
>>>>>>> more flutter integ tests
=======
                result = TeamWrapper(model: team)
>>>>>>> flutter integ tests
=======
=======
    
    func saveTeam(name: String, plugin: AWSDataStorePlugin) throws -> TestTeam? {
        let team = try TestTeam(name: name)
        var result: TestTeam?
>>>>>>> more flutter integ tests
        let completeInvoked = expectation(description: "request completed")
        plugin.save(team.model, modelSchema: Team2.schema) { event in
            switch event {
            case .success(let team):
<<<<<<< HEAD
                result = team
>>>>>>> rebasing
=======
                result = TestTeam(model: team)
>>>>>>> more flutter integ tests
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveProject(id: String = UUID().uuidString,
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
                     name: String? = "TestTeam",
                     teamID: String,
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> flutter integ tests
                     team: TeamWrapper,
                     plugin: AWSDataStorePlugin) throws -> Project2Wrapper? {
        let project = try Project2Wrapper(name: name!, team: team.model, teamID: teamID)
        var result: Project2Wrapper?
<<<<<<< HEAD
=======
                     team: TestTeam,
                     plugin: AWSDataStorePlugin) throws -> TestProject2? {
        let project = try TestProject2(name: name!, team: team.model, teamID: teamID)
        var result: TestProject2?
>>>>>>> more flutter integ tests
=======
>>>>>>> flutter integ tests
        let completeInvoked = expectation(description: "request completed")
        plugin.save(project.model, modelSchema: Project2.schema) { event in
            switch event {
            case .success(let project):
<<<<<<< HEAD
<<<<<<< HEAD
                result = Project2Wrapper(model: project)
=======
                result = TestProject2(model: project)
>>>>>>> more flutter integ tests
=======
                result = Project2Wrapper(model: project)
>>>>>>> flutter integ tests
=======
                     name: String? = nil,
=======
                     name: String? = "TestTeam",
>>>>>>> more flutter integ tests
                     teamID: String,
                     team: TeamWrapper,
                     plugin: AWSDataStorePlugin) throws -> Project2Wrapper? {
        let project = try Project2Wrapper(name: name!, team: team.model, teamID: teamID)
        var result: Project2Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(project.model, modelSchema: Project2.schema) { event in
            switch event {
            case .success(let project):
<<<<<<< HEAD
<<<<<<< HEAD
                result = project
>>>>>>> rebasing
=======
                result = TestProject2(model: project)
>>>>>>> more flutter integ tests
=======
                result = Project2Wrapper(model: project)
>>>>>>> flutter integ tests
=======
                     name: String? = nil,
=======
                     name: String? = "TestTeam",
>>>>>>> more flutter integ tests
                     teamID: String,
                     team: TestTeam,
                     plugin: AWSDataStorePlugin) throws -> TestProject2? {
        let project = try TestProject2(name: name!, team: team.model, teamID: teamID)
        var result: TestProject2?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(project.model, modelSchema: Project2.schema) { event in
            switch event {
            case .success(let project):
<<<<<<< HEAD
                result = project
>>>>>>> rebasing
=======
                result = TestProject2(model: project)
>>>>>>> more flutter integ tests
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> rebasing

extension Team2: Equatable {
    public static func == (lhs: Team2,
                           rhs: Team2) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
    }
}
extension Project2: Equatable {
    public static func == (lhs: Project2, rhs: Project2) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.teamID == rhs.teamID
    }
}
<<<<<<< HEAD
>>>>>>> rebasing
=======
>>>>>>> more flutter integ tests
=======
>>>>>>> rebasing
=======
>>>>>>> more flutter integ tests
