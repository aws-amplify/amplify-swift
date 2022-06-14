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

    override func setUp() async throws {
        try await super.setUp()
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

    func testDeleteSuccessWhenItemDoesNotExist() {
        let teamA = Team(name: "A-Team")
        let projectA = Project(name: "ProjectA", team: teamA)
        let result = deleteModelSynchronous(modelType: Project.self,
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

    func testDeleteSuccessWhenItemDoesNotExistAndConditionMatches() {
        let teamA = Team(name: "A-Team")
        let projectA = Project(name: "ProjectA", team: teamA)
        let project = Project.keys
        let result = deleteModelSynchronous(modelType: Project.self,
                                            withId: projectA.id,
                                            where: project.name == "ProjectA")
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

    func testDeleteFailWithInvalidConditionWhenItemExistsAndConditionDoesNotMatch() {
        let teamA = Team(name: "A-Team")
        let projectA = Project(name: "ProjectA", team: teamA)

        guard case .success = saveModelSynchronous(model: teamA),
            case .success = saveModelSynchronous(model: projectA) else {
                XCTFail("Failed to save hierachy")
                return
        }
        guard case .success =
            querySingleModelSynchronous(modelType: Project.self, predicate: Project.keys.id == projectA.id) else {
                XCTFail("Failed to query ProjectA")
                return
        }
        guard case .success =
            querySingleModelSynchronous(modelType: Team.self, predicate: Project.keys.id == teamA.id) else {
                XCTFail("Failed to query TeamA")
                return
        }
        let project = Project.keys
        let result = deleteModelSynchronous(modelType: Project.self,
                                            withId: projectA.id,
                                            where: project.name == "NotProjectA")

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

    func testDeleteSuccessWhenItemExistsAndConditionMatches() {
        let teamA = Team(name: "A-Team")
        let projectA = Project(name: "ProjectA", team: teamA)

        let teamB = Team(name: "B-Team")
        let projectB = Project(name: "ProjectB", team: teamB)

        let teamC = Team(name: "C-Team")
        let projectC = Project(name: "ProjectC", team: teamC)

        guard case .success = saveModelSynchronous(model: teamA),
            case .success = saveModelSynchronous(model: projectA),
            case .success = saveModelSynchronous(model: teamB),
            case .success = saveModelSynchronous(model: projectB),
            case .success = saveModelSynchronous(model: teamC),
            case .success = saveModelSynchronous(model: projectC) else {
                XCTFail("Failed to save hierachy")
                return
        }
        guard case .success =
            querySingleModelSynchronous(modelType: Project.self, predicate: Project.keys.id == projectA.id) else {
                XCTFail("Failed to query ProjectA")
                return
        }
        guard case .success =
            querySingleModelSynchronous(modelType: Team.self, predicate: Project.keys.id == teamA.id) else {
                XCTFail("Failed to query TeamA")
                return
        }

        let mutationEventOnProject = expectation(description: "Mutation Events submitted to sync engine")
        syncEngine.setCallbackOnSubmit(callback: { _ in
            mutationEventOnProject.fulfill()
        })
        let project = Project.keys
        guard case .success = deleteModelSynchronousOrFailOtherwise(modelType: Project.self,
                                                                    withId: projectA.id,
                                                                    where: project.name == "ProjectA") else {
            XCTFail("Failed to delete projectA")
            return
        }
        wait(for: [mutationEventOnProject], timeout: defaultTimeout)
    }
}
