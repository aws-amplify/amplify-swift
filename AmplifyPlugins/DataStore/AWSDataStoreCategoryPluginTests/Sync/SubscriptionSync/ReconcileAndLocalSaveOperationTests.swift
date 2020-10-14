//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStoreCategoryPlugin

class ReconcileAndLocalSaveOperationTests: XCTestCase {
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    var anyPostMetadata: MutationSyncMetadata!
    var anyPostMutationSync: MutationSync<AnyModel>!
    var anyPostDeletedMutationSync: MutationSync<AnyModel>!

    var operation: ReconcileAndLocalSaveOperation!
    var stateMachine: MockStateMachine<ReconcileAndLocalSaveOperation.State, ReconcileAndLocalSaveOperation.Action>!

    override func setUp() {
        tryOrFail {
            try setUpWithAPI()
        }
        ModelRegistry.register(modelType: Post.self)

        let testPost = Post(id: "1", title: "post1", content: "content", createdAt: .now())
        let anyPost = AnyModel(testPost)
        anyPostMetadata = MutationSyncMetadata(id: "1",
                                               deleted: false,
                                               lastChangedAt: Int(Date().timeIntervalSince1970),
                                               version: 1)
        anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)

        let testDelete = Post(id: "2", title: "post2", content: "content2", createdAt: .now())
        let anyPostDelete = AnyModel(testDelete)
        let anyPostDeleteMetadata = MutationSyncMetadata(id: "2",
                                                         deleted: true,
                                                         lastChangedAt: Int(Date().timeIntervalSince1970),
                                                         version: 2)
        anyPostDeletedMutationSync = MutationSync<AnyModel>(model: anyPostDelete, syncMetadata: anyPostDeleteMetadata)

        storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQuery(dataStoreResult: .none)
        storageAdapter.returnOnSave(dataStoreResult: .none)
        stateMachine = MockStateMachine(initialState: .waiting,
                                        resolver: ReconcileAndLocalSaveOperation.Resolver.resolve(currentState:action:))

        operation = ReconcileAndLocalSaveOperation(remoteModel: anyPostMutationSync,
                                                   storageAdapter: storageAdapter,
                                                   stateMachine: stateMachine)
    }

    func testCreateOperation() throws {
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.waiting)
    }

    func testQuerying() throws {
        let expect = expectation(description: "action .queried notified")
        storageAdapter.returnOnQueryMutationSyncMetadata(anyPostMetadata)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action.queried(self.anyPostMutationSync,
                                                                         self.anyPostMetadata))
            expect.fulfill()
        }

        stateMachine.state = .querying(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }
    /*
     //    TODO: Need to check the model registry
     func testQueryingUnregisteredModel_error() throws {
     let comment = Comment(content: "testContent", post: testPost)
     let anyComment = AnyModel(comment)
     let anyCommentMetadata = MutationSyncMetadata(id: "3",
     deleted: false,
     lastChangedAt: Int(Date().timeIntervalSince1970),
     version: 2)
     let anyCommentMutationSync = MutationSync<AnyModel>(model: anyComment, syncMetadata: anyCommentMetadata)

     stateMachine.state = .querying(anyCommentMutationSync)

     }
     */
    func testQueryingWithInvalidStorageAdapter_error() throws {
        let expect = expectation(description: "action .errored nil storage adapter")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action.errored(DataStoreError.nilStorageAdapter()))
            expect.fulfill()
        }

        storageAdapter = nil
        stateMachine.state = .querying(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testQueryingWithErrorOnQuery() throws {
        let expect = expectation(description: "action .errored notified")
        let error = DataStoreError.invalidModelName("invalidModelName")
        storageAdapter.throwOnQueryMutationSyncMetadata(error: error)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .querying(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testQueryingWithEmptyLocalStore() throws {
        let expect = expectation(description: "action .queried notified with local data == nil")
        storageAdapter.returnOnQueryMutationSyncMetadata(nil)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.queried(self.anyPostMutationSync, nil))
            expect.fulfill()
        }

        stateMachine.state = .querying(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testReconcilingWithoutLocalModel() throws {
        let expect = expectation(description: "action .reconciled notified")
        let expectedDisposition = RemoteSyncReconciler.Disposition.applyRemoteModel(anyPostMutationSync)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.reconciled(expectedDisposition))
            expect.fulfill()
        }
        stateMachine.state = .reconciling(anyPostMutationSync, nil)

        waitForExpectations(timeout: 1)
    }

    func testExecuteApplyRemoteModelThatDoesNotExistLocally() throws {
        let expect = expectation(description: "action .execute applyRemoteModel")
        let disposition = RemoteSyncReconciler.Disposition.applyRemoteModel(anyPostMutationSync)
        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostMutationSync.model))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.applied(self.anyPostMutationSync,
                                                                                 existsLocally: false))
            expect.fulfill()
        }

        stateMachine.state = .executing(disposition)
        waitForExpectations(timeout: 1)
    }

    func testExecuteApplyRemoteModelThatExistsLocally() throws {
        let expect = expectation(description: "action .execute applyRemoteModel")
        let disposition = RemoteSyncReconciler.Disposition.applyRemoteModel(anyPostMutationSync)

        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostMutationSync.model))
        storageAdapter.returnOnQueryMutationSyncMetadata(.some(anyPostMetadata))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.applied(self.anyPostMutationSync,
                                                                                 existsLocally: true))
            expect.fulfill()
        }
        stateMachine.state = .executing(disposition)

        waitForExpectations(timeout: 1)
    }

    func testExecuteApplyRemoteModel_saveMutationFailed() throws {
        let expect = expectation(description: "action .execute error on save model")
        let disposition = RemoteSyncReconciler.Disposition.applyRemoteModel(anyPostMutationSync)
        let error = DataStoreError.invalidModelName("invModelName")
        storageAdapter.returnOnSave(dataStoreResult: .failure(error))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .executing(disposition)

        waitForExpectations(timeout: 1)
    }

    func testExecuteApplyRemoteModel_saveMutationOK_MetadataFailed() throws {
        let expect = expectation(description: "action .execute error on save mutation")
        let disposition = RemoteSyncReconciler.Disposition.applyRemoteModel(anyPostMutationSync)
        let error = DataStoreError.invalidModelName("forceError")
        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostMutationSync.model))
        storageAdapter.shouldReturnErrorOnSaveMetadata = true
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .executing(disposition)
        waitForExpectations(timeout: 1)
    }

    func testExecuteApplyRemoteModel_Delete() throws {
        let expect = expectation(description: "action .execute applyRemoteModel delete success case")
        let disposition = RemoteSyncReconciler.Disposition.applyRemoteModel(anyPostDeletedMutationSync)
        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostDeletedMutationSync.model))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.applied(self.anyPostDeletedMutationSync,
                                                                                 existsLocally: false))
            expect.fulfill()
        }

        stateMachine.state = .executing(disposition)
        waitForExpectations(timeout: 1)
    }

    func testExecuteApplyRemoteModel_Delete_saveMutationFailed() throws {
        let expect = expectation(description: "action .execute applyRemoteModel delete mutation error")
        let disposition = RemoteSyncReconciler.Disposition.applyRemoteModel(anyPostDeletedMutationSync)
        let error = DataStoreError.invalidModelName("DelMutate")
        storageAdapter.shouldReturnErrorOnDeleteMutation = true
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .executing(disposition)

        waitForExpectations(timeout: 1)
    }

    func testExecuteApplyRemoteModel_Delete_saveMutationOK_saveMetadataFailed() throws {
        let expect = expectation(description: "action .execute applyRemoteModel delete metadata error")
        let disposition = RemoteSyncReconciler.Disposition.applyRemoteModel(anyPostDeletedMutationSync)
        let error = DataStoreError.invalidModelName("forceError")
        storageAdapter.shouldReturnErrorOnSaveMetadata = true
        storageAdapter.returnOnSave(dataStoreResult: .failure(error))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .executing(disposition)
        waitForExpectations(timeout: 1)
    }

    func testExecuteDropRemoteModel() throws {
        let expect = expectation(description: "action .execute dropRemoteModel")
        let disposition = RemoteSyncReconciler.Disposition.dropRemoteModel
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.dropped(modelName: "Post"))
            expect.fulfill()
        }

        stateMachine.state = .executing(disposition("Post"))

        waitForExpectations(timeout: 1)
    }

    func testExecuteErrorOnDisposition() throws {
        let expect = expectation(description: "action .execute error")
        let error = DataStoreError.invalidModelName("invModelName")
        let disposition = RemoteSyncReconciler.Disposition.error(error)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .executing(disposition)

        waitForExpectations(timeout: 1)
    }

    func testNotifying() throws {
        let hubExpect = expectation(description: "Hub is notified")
        let notifyExpect = expectation(description: "action .notified notified")
        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.syncReceived" {
                hubExpect.fulfill()
            }
        }
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.notified)
            notifyExpect.fulfill()
        }

        stateMachine.state = .notifying(anyPostMutationSync, false)

        waitForExpectations(timeout: 1)
        Amplify.Hub.removeListener(hubListener)
    }
}

extension ReconcileAndLocalSaveOperationTests {
    private func setUpCore() throws -> AmplifyConfiguration {
        Amplify.reset()

        let storageEngine = MockStorageEngineBehavior()
        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngine: storageEngine,
                                                 dataStorePublisher: dataStorePublisher,
                                                 validAPIPluginKey: "MockAPICategoryPlugin",
                                                 validAuthPluginKey: "MockAuthCategoryPlugin")
        try Amplify.add(plugin: dataStorePlugin)
        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        return amplifyConfig
    }

    private func setUpAPICategory(config: AmplifyConfiguration) throws -> AmplifyConfiguration {
        let apiPlugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: apiPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: config.dataStore)
        return amplifyConfig
    }

    private func setUpWithAPI() throws {
        let configWithoutAPI = try setUpCore()
        let configWithAPI = try setUpAPICategory(config: configWithoutAPI)
        try Amplify.configure(configWithAPI)
    }

}
