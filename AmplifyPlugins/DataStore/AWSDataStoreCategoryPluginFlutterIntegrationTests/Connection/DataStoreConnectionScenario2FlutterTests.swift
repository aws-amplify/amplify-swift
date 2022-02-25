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
        let team = try TeamWrapper(name: "name1")
        let project = try Project2Wrapper(name: "project1", team: team.model, teamID: team.idString())
        let syncedTeamReceived = expectation(description: "received team from sync event")
        let syncProjectReceived = expectation(description: "received project from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }
            if let syncedTeam = mutationEvent.modelId as String?,
               syncedTeam == team.idString() {
                syncedTeamReceived.fulfill()
            } else if let syncedProject = mutationEvent.modelId as String?,
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
                let queriedProject = Project2Wrapper(model: queriedProjectList[0])
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
        let team = try TeamWrapper(name: "name1")
        var anotherTeam = try TeamWrapper(name: "name1")
        let project = try Project2Wrapper(name: "project1", team: team.model, teamID: team.idString())
        let expectedUpdatedProject = project.copy() as! Project2Wrapper
        try expectedUpdatedProject.setTeam(name: "project1", team: anotherTeam.model, teamID: anotherTeam.idString())
        
        let syncUpdatedProjectReceived = expectation(description: "received updated project from sync path")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }
            if let syncedUpdatedProject = mutationEvent.modelId as String?,

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
            case .success(let savedTeam):
                anotherTeam = TeamWrapper(model: savedTeam)
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
                let queriedProject = Project2Wrapper(model: queriedProjectList[0])
                XCTAssertEqual(queriedProject.idString(), project.idString())
                XCTAssertEqual(queriedProject.teamID(), anotherTeam.id())
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
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {

            XCTFail("Could not save team and project")
            return
        }
        let deleteProjectSuccessful = expectation(description: "delete project")
        plugin.delete(project.model, modelSchema: Project2.schema) { result in
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
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
        let team = try saveTeam(name: "name", plugin: plugin)
        let project = try saveProject(teamID: team!.idString(), team: team!, plugin: plugin)
        let deleteProjectSuccessful = expectation(description: "delete project")
        plugin.delete(project!.model, modelSchema: Project2.schema, where: Project2.keys.teamID.eq(team!.idString())) { result in
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project!.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)
                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteWithInvalidCondition() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
            XCTFail("Could not save team and project")
            return
        }
        let deleteProjectFailed = expectation(description: "delete project")
        plugin.delete(project.model, modelSchema: Project2.schema, where: Project2.keys.id.eq("invalidTeamId")) { result in
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
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project.model.id)) { result in
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
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin),
              let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
            XCTFail("Could not save team and project")
            return
        }
        let deleteProjectSuccessful = expectation(description: "delete project")
        plugin.delete(project.model, modelSchema: Project2.schema) { result in
            switch result {
            case .success:
                deleteProjectSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getProjectAfterDeleteCompleted = expectation(description: "get project after deleted complete")
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where:  Project2.keys.id.eq(project.model.id)) { result in
            switch result {
            case .success(let project2):
                XCTAssert(project2.isEmpty)

                getProjectAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getProjectAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
        let deleteProjectSuccessful2 = expectation(description: "delete project")
        plugin.delete(project.model, modelSchema: Project2.schema, where: Project2.keys.teamID.eq(team.idString())) { result in
            switch result {
            case .success:
                deleteProjectSuccessful2.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteProjectSuccessful2], timeout: TestCommonConstants.networkTimeout)
    }


    func testListProjectsByTeamID() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let team = try saveTeam(name: "name", plugin: plugin) else {
            XCTFail("Could not save team")
            return
        }
        guard let project = try saveProject(teamID: team.idString(), team: team, plugin: plugin) else {
            XCTFail("Could not save project")
            return
        }
        let listProjectByTeamIDCompleted = expectation(description: "list projects completed")

        let predicate = Project2.keys.teamID.eq(team.idString())
        plugin.query(FlutterSerializedModel.self, modelSchema: Project2.schema, where: predicate) { result in
            switch result {
            case .success(let projects):
                let returnedProject = Project2Wrapper(model: projects[0])
                XCTAssertEqual(projects.count, 1)
                XCTAssertEqual(project.teamID(), team.id())
                listProjectByTeamIDCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listProjectByTeamIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func saveTeam(name: String, plugin: AWSDataStorePlugin) throws -> TeamWrapper? {
        let team = try TeamWrapper(name: name)
        var result: TeamWrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(team.model, modelSchema: Team2.schema) { event in
            switch event {
            case .success(let team):
                result = TeamWrapper(model: team)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveProject(teamID: String,
                     team: TeamWrapper,
                     plugin: AWSDataStorePlugin) throws -> Project2Wrapper? {
        let project = try Project2Wrapper(name: name, team: team.model, teamID: teamID)
        var result: Project2Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(project.model, modelSchema: Project2.schema) { event in
            switch event {
            case .success(let project):
                result = Project2Wrapper(model: project)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
