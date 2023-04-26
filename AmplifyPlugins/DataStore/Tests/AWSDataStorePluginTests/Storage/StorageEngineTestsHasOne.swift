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
        let saved = expectation(description: "Team saved")
        Task {
            _ = await storageEngine.save(team, modelSchema: team.schema, condition: QueryPredicateConstant.all, eagerLoad: true)
            saved.fulfill()
        }
        wait(for: [saved], timeout: 1)

        guard case .success =
            querySingleModel(modelType: Team.self, predicate: Team.keys.id == team.id) else {
                XCTFail("Failed to query Team")
                return
        }
    }

    func testBelongsToRelationshipWithoutOwner() async {
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
        guard case .success = await deleteModelOrFailOtherwise(modelType: Project.self,
                                                                    withId: projectA.id) else {
            XCTFail("Failed to delete projectA")
            return
        }
        wait(for: [mutationEventOnProject], timeout: defaultTimeout)
    }
}
