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

class StorageEngineTestsHasOne: StorageEngineTestsBase {

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

    func testSaveModelWithPredicateAll() {
        let team = Team(name: "Team")
        let saveFinished = expectation(description: "Save finished")
        var result: DataStoreResult<Team>?
        storageEngine.save(team, condition: QueryPredicateConstant.all) { sResult in
            result = sResult
            saveFinished.fulfill()
        }
        wait(for: [saveFinished], timeout: defaultTimeout)

        guard let saveResult = result else {
            XCTFail("Save operation timed out")
            return
        }

        guard case .success =
            querySingleModelSynchronous(modelType: Team.self, predicate: Team.keys.id == team.id) else {
                XCTFail("Failed to query Team")
                return
        }
    }

    func testBelongsToRelationshipWithoutOwner() {
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
        syncEngine.setCallbackOnSubmit{ submittedMutationEvent, completion in
            mutationEventOnProject.fulfill()
            completion(.success(submittedMutationEvent))
        }
        guard case .success = deleteModelSynchronousOrFailOtherwise(modelType: Project.self,
                                                                    withId: projectA.id) else {
            XCTFail("Failed to delete projectA")
            return
        }
        wait(for: [mutationEventOnProject], timeout: defaultTimeout)
    }
}
