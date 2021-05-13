//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
    var anyPostMutationEvent: MutationEvent!

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
        anyPostMutationEvent = MutationEvent(id: "1",
                                             modelId: "1",
                                             modelName: testPost.modelName,
                                             json: "",
                                             mutationType: .create)
        storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQuery(dataStoreResult: .none)
        storageAdapter.returnOnSave(dataStoreResult: .none)
        stateMachine = MockStateMachine(initialState: .waiting,
                                        resolver: ReconcileAndLocalSaveOperation.Resolver.resolve(currentState:action:))

        operation = ReconcileAndLocalSaveOperation(modelSchema: anyPostMutationSync.model.schema,
                                                   remoteModel: anyPostMutationSync,
                                                   storageAdapter: storageAdapter,
                                                   stateMachine: stateMachine)
    }

    func testCreateOperation() throws {
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.waiting)
    }

    // MARK: - queryPendingMutations

    func testQueryPendingMutations_queriedPendingMutations() {
        let expect = expectation(description: "action .queriedPendingMutations")
        let mutationEvent = MutationEvent(modelId: "1111-22",
                                          modelName: "Post",
                                          json: "{}",
                                          mutationType: .create)
        let queryResponder = QueryModelTypePredicateResponder<MutationEvent> { _, _ in
            return .success([mutationEvent])
        }
        storageAdapter.responders[.queryModelTypePredicate] = queryResponder

        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action
                            .queriedPendingMutations(self.anyPostMutationSync, [mutationEvent]))
            expect.fulfill()
        }

        stateMachine.state = .queryingPendingMutations(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testQueryPendingMutations_error() {
        let expect = expectation(description: "action .queriedPendingMutations")
        let error = DataStoreError.internalOperation("Failed to query pending mutations", "")
        let queryResponder = QueryModelTypePredicateResponder<MutationEvent> { _, _ in
            return .failure(error)
        }
        storageAdapter.responders[.queryModelTypePredicate] = queryResponder

        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .queryingPendingMutations(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testQueryPendingMutations_invalidStorageAdapter() throws {
        let expect = expectation(description: "action .errored nil storage adapter")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action.errored(DataStoreError.nilStorageAdapter()))
            expect.fulfill()
        }

        storageAdapter = nil
        stateMachine.state = .queryingPendingMutations(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testQueryPendingMutationsWithEmptyStore() throws {
        let expect = expectation(description: "action .queriedPendingMutations notified with pending mutation == []")
        let queryResponder = QueryModelTypePredicateResponder<MutationEvent> { _, _ in
            return .success([])
        }
        storageAdapter.responders[.queryModelTypePredicate] = queryResponder
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action
                            .queriedPendingMutations(self.anyPostMutationSync, []))
            expect.fulfill()
        }

        stateMachine.state = .queryingPendingMutations(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    // MARK: - reconcile(remoteModel:pendingMutations)

    func testReconcilePendingMutations_reconciled() {
        let expect = expectation(description: "action .reconciledWithPendingMutations")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action
                            .reconciledWithPendingMutations(self.anyPostMutationSync))
            expect.fulfill()
        }

        stateMachine.state = .reconcilingWithPendingMutations(anyPostMutationSync, [])

        waitForExpectations(timeout: 1)
    }

    func testReoncilePendingMutations_dropped() {
        let expect = expectation(description: "action .reconciledWithPendingMutations")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action
                            .dropped(modelName: "Post"))
            expect.fulfill()
        }

        stateMachine.state = .reconcilingWithPendingMutations(anyPostMutationSync, [anyPostMutationEvent])

        waitForExpectations(timeout: 1)
    }

    // MARK: - queryLocalMetadata

    func testQueryLocalMetadata_queriedPendingMutations() {
        let expect = expectation(description: "action .queriedLocalMetadata")
        storageAdapter.returnOnQueryMutationSyncMetadata(anyPostMetadata)

        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action
                            .queriedLocalMetadata(self.anyPostMutationSync, self.anyPostMetadata))
            expect.fulfill()
        }

        stateMachine.state = .queryingLocalMetadata(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testQueryLocalMetadata_error() {
        let expect = expectation(description: "action .errored")
        let error = DataStoreError.internalOperation("Failed to query local metadata", "")
        storageAdapter.throwOnQueryMutationSyncMetadata(error: error)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .queryingLocalMetadata(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testQueryLocalMetadata_invalidStorageAdapter() throws {
        let expect = expectation(description: "action .errored nil storage adapter")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action.errored(DataStoreError.nilStorageAdapter()))
            expect.fulfill()
        }

        storageAdapter = nil
        stateMachine.state = .queryingLocalMetadata(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testQueryLocalMetadataWithEmptyStore() throws {
        let expect = expectation(description: "action .queried notified with local metadata == nil")
        storageAdapter.returnOnQueryMutationSyncMetadata(nil)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action
                            .queriedLocalMetadata(self.anyPostMutationSync, nil))
            expect.fulfill()
        }

        stateMachine.state = .queryingLocalMetadata(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    // MARK: - reconcile(remoteModel:localMetadata)

    func testReconcileLocalMetadata_apply() {
        let expect = expectation(description: "action .reconciledAsApply")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action
                            .reconciledAsApply(self.anyPostMutationSync, .update))
            expect.fulfill()
        }

        stateMachine.state = .reconcilingWithLocalMetadata(anyPostMutationSync, anyPostMetadata)

        waitForExpectations(timeout: 1)
    }

    func testReconcileWithNilLocalMetadata_dropped() {
        let expect = expectation(description: "action .dropped")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action
                            .dropped(modelName: "Post"))
            expect.fulfill()
        }

        stateMachine.state = .reconcilingWithLocalMetadata(anyPostDeletedMutationSync, nil)

        waitForExpectations(timeout: 1)
    }

    // MARK: - applyRemoteModel

    func testApplyRemoteModelCreate() throws {
        let expect = expectation(description: "action .applied")
        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostMutationSync.model))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.applied(self.anyPostMutationSync,
                                                                                 .create))
            expect.fulfill()
        }

        stateMachine.state = .applyingRemoteModel(anyPostMutationSync, .create)
        waitForExpectations(timeout: 1)
    }

    func testExecuteApplyRemoteModelUpdate() throws {
        let expect = expectation(description: "action .applied")
        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostMutationSync.model))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.applied(self.anyPostMutationSync,
                                                                                 .update))
            expect.fulfill()
        }
        stateMachine.state = .applyingRemoteModel(anyPostMutationSync, .update)

        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModel_saveMutationFailed() throws {
        let expect = expectation(description: "action .errorred on save model")
        let error = DataStoreError.invalidModelName("invModelName")
        storageAdapter.returnOnSave(dataStoreResult: .failure(error))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .applyingRemoteModel(anyPostMutationSync, .create)

        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModel_saveMutationOK_MetadataFailed() throws {
        let expect = expectation(description: "action .errorred on save mutation")
        let error = DataStoreError.invalidModelName("forceError")
        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostMutationSync.model))
        storageAdapter.shouldReturnErrorOnSaveMetadata = true
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .applyingRemoteModel(anyPostMutationSync, .create)
        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModel_Delete() throws {
        let expect = expectation(description: "action .applied delete success case")
        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostDeletedMutationSync.model))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.applied(self.anyPostDeletedMutationSync,
                                                                                 .delete))
            expect.fulfill()
        }

        stateMachine.state = .applyingRemoteModel(anyPostDeletedMutationSync, .delete)
        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModel_Delete_saveMutationFailed() throws {
        let expect = expectation(description: "action .errored delete mutation error")
        let error = DataStoreError.invalidModelName("DelMutate")
        storageAdapter.shouldReturnErrorOnDeleteMutation = true
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .applyingRemoteModel(anyPostDeletedMutationSync, .delete)

        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModel_Delete_saveMutationOK_saveMetadataFailed() throws {
        let expect = expectation(description: "action .errored delete metadata error")
        let error = DataStoreError.invalidModelName("forceError")
        storageAdapter.shouldReturnErrorOnSaveMetadata = true
        storageAdapter.returnOnSave(dataStoreResult: .failure(error))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .applyingRemoteModel(anyPostDeletedMutationSync, .delete)
        waitForExpectations(timeout: 1)
    }

    // MARK: - notifyDropped
    func testNotifyingDropped() throws {
        let expect = expectation(description: "action .notified")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.notified)
            expect.fulfill()
        }

        stateMachine.state = .notifyingDropped("Post")
        waitForExpectations(timeout: 1)
    }

    // MARK: - notify

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

        stateMachine.state = .notifying(anyPostMutationSync, .create)

        waitForExpectations(timeout: 1)
        Amplify.Hub.removeListener(hubListener)
    }
}

extension ReconcileAndLocalSaveOperationTests {
    private func setUpCore() throws -> AmplifyConfiguration {
        Amplify.reset()

        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngineBehaviorFactory: MockStorageEngineBehavior.mockStorageEngineBehaviorFactory,
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
