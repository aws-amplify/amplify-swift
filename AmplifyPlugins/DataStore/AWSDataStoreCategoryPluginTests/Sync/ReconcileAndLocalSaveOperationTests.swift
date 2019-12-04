//
// Copyright 2018-2019 Amazon.com,
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

// swiftlint:disable file_length
// TODO: Refactor this into separate test suites
class ReconcileAndLocalSaveOperationTests: XCTestCase {
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    var anyPostMutationSync: MutationSync<AnyModel>!
    var anyPostDeletedMutationSync: MutationSync<AnyModel>!

    var operation: ReconcileAndLocalSaveOperation!
    var stateMachine: MockStateMachine<ReconcileAndLocalSaveOperation.State, ReconcileAndLocalSaveOperation.Action>!

    override func setUp() {
        do {
            try setUpWithAPI()
        } catch {
            XCTFail(String(describing: "Unable to setup API category for unit tests"))
        }
        ModelRegistry.register(modelType: Post.self)

        let testPost = Post(id: "1", title: "post1", content: "content")
        let anyPost = AnyModel(testPost)
        let anyPostMetadata = MutationSyncMetadata(id: "1",
                                                   deleted: false,
                                                   lastChangedAt: Int(Date().timeIntervalSince1970),
                                                   version: 1)
        anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)

        let testDelete = Post(id: "2", title: "post2", content: "content2")
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
        storageAdapter.returnOnQueryMutationSync(mutationSync: anyPostMutationSync)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action.queried(self.anyPostMutationSync,
                                                                         self.anyPostMutationSync))
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
        storageAdapter.throwOnQueryMutationSync(error: error)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .querying(anyPostMutationSync)

        waitForExpectations(timeout: 1)
    }

    func testQueryingWithEmptyLocalStore() throws {
        let expect = expectation(description: "action .queried notified with local data == nil")
        storageAdapter.returnOnQueryMutationSync(mutationSync: nil)
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

    func testExecuteApplyRemoteModel() throws {
        let expect = expectation(description: "action .execute applyRemoteModel")
        let disposition = RemoteSyncReconciler.Disposition.applyRemoteModel(anyPostMutationSync)
        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostMutationSync.model))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.applied(self.anyPostMutationSync))
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
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.applied(self.anyPostDeletedMutationSync))
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
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.dropped)
            expect.fulfill()
        }

        stateMachine.state = .executing(disposition)

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
            XCTAssertEqual(payload.eventName, "DataStore.syncReceived")
            hubExpect.fulfill()
        }
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.notified)
            notifyExpect.fulfill()
        }

        stateMachine.state = .notifying(anyPostMutationSync)

        waitForExpectations(timeout: 1)
        Amplify.Hub.removeListener(hubListener)
    }
}
extension ReconcileAndLocalSaveOperation.State: Equatable {
    public static func == (lhs: ReconcileAndLocalSaveOperation.State,
                           rhs: ReconcileAndLocalSaveOperation.State) -> Bool {
        switch (lhs, rhs) {
        case (.waiting, .waiting):
            return true
        case (.querying(let model1), .querying(let model2)):
            return model1.model.id == model2.model.id
                && model1.model.modelName == model2.model.modelName
        case (.reconciling(let model1, let lmodel1), .reconciling(let model2, let lmodel2)):
            return model1.model.id == model2.model.id
                && lmodel1?.model.id == lmodel2?.model.id
                && model1.model.modelName == model2.model.modelName
                && lmodel1?.model.modelName == lmodel2?.model.modelName
        case (.executing(let disposition1), .executing(let disposition2)):
            return disposition1 == disposition2
        case (.notifying(let model1), .notifying(let model2)):
            return model1.model.id == model2.model.id
                && model1.model.modelName == model2.model.modelName
        case (.finished, .finished):
            return true
        case (.inError(let error1), .inError(let error2)):
            return error1.errorDescription == error2.errorDescription
        default:
            return false
        }
    }
}

extension RemoteSyncReconciler.Disposition: Equatable {
    public static func == (lhs: RemoteSyncReconciler.Disposition,
                           rhs: RemoteSyncReconciler.Disposition) -> Bool {
        switch (lhs, rhs) {
        case (.applyRemoteModel(let rm1), .applyRemoteModel(let rm2)):
            return rm1.model.id == rm2.model.id &&
                rm1.model.modelName == rm2.model.modelName
        case (.dropRemoteModel, .dropRemoteModel):
            return true
        case (.error(let error1), .error(let error2)):
            return error1.errorDescription == error2.errorDescription
        default:
            return false
        }
    }
}

extension ReconcileAndLocalSaveOperation.Action: Equatable {
    public static func == (lhs: ReconcileAndLocalSaveOperation.Action, rhs: ReconcileAndLocalSaveOperation.Action) -> Bool {
        switch (lhs, rhs) {
        case (.started(let model1), .started(let model2)):
            return model1.model.id == model2.model.id
                && model1.model.modelName == model2.model.modelName
        case (.queried(let model1, let lmodel1), .queried(let model2, let lmodel2)):
            return model1.model.id == model2.model.id
                && lmodel1?.model.id == lmodel2?.model.id
                && model1.model.modelName == model2.model.modelName
                && lmodel1?.model.modelName == lmodel2?.model.modelName
        case (.reconciled(let disposition1), .reconciled(let disposition2)):
            return disposition1 == disposition2
        case (.applied(let model1), .applied(let model2)):
            return model1.model.id == model2.model.id
                && model1.model.modelName == model2.model.modelName
        case (.dropped, dropped):
            return true
        case (.notified, .notified):
            return true
        case (.cancelled, .cancelled):
            return true
        case (.errored(let error1), .errored(let error2)):
            return error1.errorDescription == error2.errorDescription
        default:
            return false
        }
    }
}

class MockSQLiteStorageEngineAdapter: StorageEngineAdapter {
    var resultForQuery: DataStoreResult<[Model]>?
    var resultForSave: DataStoreResult<Model>?
    var resultForQueryMutationSync: MutationSync<AnyModel>?
    var errorToThrowOnMutationSync: DataStoreError?
    var shouldReturnErrorOnSaveMetadata: Bool
    var shouldReturnErrorOnDeleteMutation: Bool

    init() {
        self.resultForQuery = nil
        self.resultForSave = nil
        self.resultForQueryMutationSync = nil
        self.errorToThrowOnMutationSync = nil
        self.shouldReturnErrorOnSaveMetadata = false
        self.shouldReturnErrorOnDeleteMutation = false
    }

    func setUp(models: [Model.Type]) throws {
        XCTFail("Not expected to execute")
    }
    func delete<M: Model>(_ modelType: M.Type,
                          withId id: Model.Identifier,
                          completion: DataStoreCallback<Void>) {
        XCTFail("Not expected to execute")
    }
    func delete(untypedModelType modelType: Model.Type,
                withId id: String,
                completion: (Result<Void, DataStoreError>) -> Void) {
        return shouldReturnErrorOnDeleteMutation
            ? completion(.failure(causedBy: DataStoreError.invalidModelName("DelMutate")))
            : completion(.emptyResult)
    }
    func query(untypedModel modelType: Model.Type,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>) {
        let result = resultForQuery ?? .failure(DataStoreError.invalidOperation(causedBy: nil))
        completion(result)
    }
    func query<M: Model>(_ modelType: M.Type, predicate: QueryPredicate?, completion: DataStoreCallback<[M]>) {
        XCTFail("Not expected to execute")
    }
    func queryMutationSync(for models: [Model]) throws -> [MutationSync<AnyModel>] {
        XCTFail("Not expected to execute")
        return []
    }
    func exists(_ modelType: Model.Type, withId id: Model.Identifier) throws -> Bool {
        XCTFail("Not expected to execute")
        return true
    }
    func returnOnSave(dataStoreResult: DataStoreResult<Model>?) {
        resultForSave = dataStoreResult
    }
    func save(untypedModel: Model, completion: @escaping DataStoreCallback<Model>) {
        completion(resultForSave!)
    }

    func save<M: Model>(_ model: M, completion: @escaping DataStoreCallback<M>) {
        return shouldReturnErrorOnSaveMetadata
            ? completion(.failure(DataStoreError.invalidModelName("forceError")))
            : completion(.success(model))
    }
    func returnOnQuery(dataStoreResult: DataStoreResult<[Model]>?) {
        resultForQuery = dataStoreResult
    }
    func returnOnQueryMutationSync(mutationSync: MutationSync<AnyModel>?) {
        resultForQueryMutationSync = mutationSync
    }
    func throwOnQueryMutationSync(error: DataStoreError) {
        errorToThrowOnMutationSync = error
    }
    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>? {
        if let err = self.errorToThrowOnMutationSync {
            errorToThrowOnMutationSync = nil
            throw err
        }
        return resultForQueryMutationSync
    }
    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         additionalStatements: String?,
                         completion: DataStoreCallback<[M]>) {
        //TODO: find way to mock different errors here
        completion(.success([]))
    }
    func queryMutationSyncMetadata(for modelId: String) throws -> MutationSyncMetadata? {
        XCTFail("not expected to execute")
        return nil
    }
}
class MockStorageEngineBehavior: StorageEngineBehavior {
    func startSync() {
    }
    func setUp(models: [Model.Type]) throws {
    }
    func save<M: Model>(_ model: M, completion: @escaping DataStoreCallback<M>) {
        XCTFail("Not expected to execute")
    }
    func delete<M: Model>(_ modelType: M.Type,
                          withId id: Model.Identifier,
                          completion: DataStoreCallback<Void>) {
        XCTFail("Not expected to execute")
    }
    func query<M: Model>(_ modelType: M.Type, predicate: QueryPredicate?, completion: DataStoreCallback<[M]>) {
        XCTFail("Not expected to execute")
    }
}
extension ReconcileAndLocalSaveOperationTests {
    private func setUpCore() throws -> AmplifyConfiguration {
        Amplify.reset()

        let storageEngine = MockStorageEngineBehavior()
        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngine: storageEngine,
                                                 dataStorePublisher: dataStorePublisher)
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
