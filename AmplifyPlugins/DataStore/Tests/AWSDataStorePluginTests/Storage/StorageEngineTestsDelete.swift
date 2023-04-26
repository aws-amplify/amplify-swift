//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class StorageEngineTestsDelete: StorageEngineTestsBase {

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .warn

        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            syncEngine = MockRemoteSyncEngine()
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
            ModelRegistry.register(modelType: Team.self)
            ModelRegistry.register(modelType: Project.self)

            do {
                try storageEngine.setUp(modelSchemas: [Team.schema])
                try storageEngine.setUp(modelSchemas: [Project.schema])

            } catch {
                XCTFail("Failed to setup storage engine")
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    // may be moved
    func testDeleteFails_QueryByIdFails() {

    }
    // may be moved
    func testDeleteFails_ExistsCheckFails() {

    }

    func testDeleteSuccessWhenItemDoesNotExist() async {
        let teamA = Team(name: "A-Team")
        let projectA = Project(name: "ProjectA", team: teamA)
        let result = await deleteModel(modelType: Project.self,
                                            withId: projectA.id)
        switch result {
        case .success(let model):
            guard model == nil else {
                XCTFail("Should be missing model")
                return
            }
        case .failure(let error):
            XCTFail("\(error)")
        }
    }

    func testDeleteSuccessWhenItemDoesNotExistAndConditionMatches() async {
        let teamA = Team(name: "A-Team")
        let projectA = Project(name: "ProjectA", team: teamA)
        let project = Project.keys
        let result = await deleteModel(
            modelType: Project.self,
            withId: projectA.id,
            where: project.name == "ProjectA"
        )

        switch result {
        case .success(let model):
            guard model == nil else {
                XCTFail("Should be missing model")
                return
            }
        case .failure(let error):
            XCTFail("\(error)")
        }
    }

    func testDeleteFailWithInvalidConditionWhenItemExistsAndConditionDoesNotMatch() async {
        let teamA = Team(name: "A-Team")
        let projectA = Project(name: "ProjectA", team: teamA)

        guard case .success = await saveModel(model: teamA),
            case .success = await saveModel(model: projectA) else {
                XCTFail("Failed to save hierachy")
                return
        }
        guard case .success =
            querySingleModel(modelType: Project.self, predicate: Project.keys.id == projectA.id) else {
                XCTFail("Failed to query ProjectA")
                return
        }
        guard case .success =
            querySingleModel(modelType: Team.self, predicate: Project.keys.id == teamA.id) else {
                XCTFail("Failed to query TeamA")
                return
        }
        let project = Project.keys
        let result = await deleteModel(
            modelType: Project.self,
            withId: projectA.id,
            where: project.name == "NotProjectA"
        )

        switch result {
        case .success:
            XCTFail("Should have failed")
        case .failure(let error):
            guard case .invalidCondition = error else {
                XCTFail("\(error)")
                return
            }
        }
    }

    func testDeleteSuccessWhenItemExistsAndConditionMatches() async {
        let teamA = Team(name: "A-Team")
        let projectA = Project(name: "ProjectA", team: teamA)

        let teamB = Team(name: "B-Team")
        let projectB = Project(name: "ProjectB", team: teamB)

        let teamC = Team(name: "C-Team")
        let projectC = Project(name: "ProjectC", team: teamC)

        guard case .success = await saveModel(model: teamA),
            case .success = await saveModel(model: projectA),
            case .success = await saveModel(model: teamB),
            case .success = await saveModel(model: projectB),
            case .success = await saveModel(model: teamC),
            case .success = await saveModel(model: projectC) else {
                XCTFail("Failed to save hierachy")
                return
        }
        guard case .success =
            querySingleModel(modelType: Project.self, predicate: Project.keys.id == projectA.id) else {
                XCTFail("Failed to query ProjectA")
                return
        }
        guard case .success =
            querySingleModel(modelType: Team.self, predicate: Project.keys.id == teamA.id) else {
                XCTFail("Failed to query TeamA")
                return
        }

        let mutationEventOnProject = expectation(description: "Mutation Events submitted to sync engine")
        syncEngine.setCallbackOnSubmit { submittedMutationEvent in
            mutationEventOnProject.fulfill()
            return .success(submittedMutationEvent)
        }

        let project = Project.keys
        guard case .success = await deleteModelOrFailOtherwise(modelType: Project.self,
                                                                    withId: projectA.id,
                                                                    where: project.name == "ProjectA") else {
            XCTFail("Failed to delete projectA")
            return
        }
        await fulfillment(of: [mutationEventOnProject], timeout: defaultTimeout)
    }
}
