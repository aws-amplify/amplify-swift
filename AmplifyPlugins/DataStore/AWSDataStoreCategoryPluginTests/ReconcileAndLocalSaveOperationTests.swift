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
@testable import AWSDataStoreCategoryPlugin
import AWSPluginsCore

class ReconcileAndLocalSaveOperationTests: XCTestCase {
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    var testPost: Post!
    var anyPost: AnyModel!
    var operation: ReconcileAndLocalSaveOperation!
    var stateMachine: MockStateMachine!

    override func setUp() {
        do {
            try setUpWithAPI()
        } catch {
            XCTFail(String(describing: "Unable to setup API category for unit tests"))
        }
        ModelRegistry.register(modelType: Post.self)
        testPost = Post(id: "1",
                        title: "post1",
                        content: "content")
        anyPost = AnyModel(testPost)
        storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQuery(dataStoreResult: .none)
        storageAdapter.returnOnSave(dataStoreResult: .none)
        stateMachine = MockStateMachine(initialState: .waiting,
                                        resolver: ReconcileAndLocalSaveOperation.resolve(currentState:action:))
        operation = ReconcileAndLocalSaveOperation(anyModel: anyPost,
                                                   storageAdapter: storageAdapter,
                                                   stateMachine: stateMachine)
    }

    func testCreateOperation() throws {
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.waiting)
    }

    func testDeserializing() throws {
        //Ensure state is correctly configured via setUp()
        let expect = expectation(description: "action .deserialized notified")
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.waiting)
        stateMachine.setExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.deserialized(self.anyPost))
            expect.fulfill()
        }

        stateMachine.state = .deserializing(anyPost)

        waitForExpectations(timeout: 1)
    }

    //    func testDeserializingToError() throws {
    //        //Ensure state is correctly configured via setUp()
    //        XCTAssertEqual(operation.stateMachine.state, ReconcileAndLocalSaveOperation.State.waiting)
    //        operation.stateMachine.notify(action: .started(myModel))
    //
    //        //TODO: deserialize does not currently have an error case.
    //    }

    func testQuerying() throws {
        let expect = expectation(description: "action .queried notified")
        storageAdapter.returnOnQuery(dataStoreResult: .success([anyPost]))
        stateMachine.setExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.queried(self.anyPost, self.anyPost))
            expect.fulfill()
        }

        stateMachine.state = .querying(anyPost)

        waitForExpectations(timeout: 1)
    }

    func testQueryingUnregisteredModel_error() throws {
        let comment = Comment(content: "testContent", post: testPost)
        let anyComment = AnyModel(comment)

        stateMachine.state = .querying(anyComment)

        //TODO: Consider going to error state?
        //Currently there is not good way to verify this
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.querying(anyComment))
    }

    func testQueryingWithInvalidStorageAdapter_error() throws {
        storageAdapter = nil
        stateMachine.state = .querying(anyPost)

        //TODO: Consider going to error state?
        //Currently there is not good way to verify this
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.querying(anyPost))
    }

    func testQueryingWithErrorOnQuery() throws {
        let expect = expectation(description: "action .errored notified")
        let error = DataStoreError.invalidModelName("invalidModelName")
        storageAdapter.returnOnQuery(dataStoreResult: .failure(error))
        stateMachine.setExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .querying(anyPost)

        waitForExpectations(timeout: 1)
    }

    func testQueryingWithEmptyLocalStore() throws {
        let expect = expectation(description: "action .queried notified with local data == nil")
        storageAdapter.returnOnQuery(dataStoreResult: .success([]))
        stateMachine.setExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.queried(self.anyPost, nil))
            expect.fulfill()
        }

        stateMachine.state = .querying(anyPost)

        waitForExpectations(timeout: 1)
    }

    func testQueryingWithMultipleEntriesInLocalStore_error() throws {
        let expect = expectation(description: "action .errored notified")
        let testPost2 = Post(id: "1",
                             title: "post2",
                             content: "content2")
        let anyPost2 = AnyModel(testPost2)
        let error = DataStoreError.nonUniqueResult(model: testPost2.modelName, count: 2)
        storageAdapter.returnOnQuery(dataStoreResult: .success([anyPost, anyPost2]))
        stateMachine.setExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .querying(anyPost)

        waitForExpectations(timeout: 1)
    }

    //Not entirely accurate, and will update this when we add version/conflict state
    //    func testReconcilingWithLocalModel() throws {
    //        operation.stateMachine.state = .reconciling(anyPost, anyPost)
    //
    //        operation.respond(to: .reconciling(anyPost, anyPost))
    //
    //        XCTAssertEqual(operation.stateMachine.state, ReconcileAndLocalSaveOperation.State.saving(anyPost))
    //    }

    func testReconcilingWithoutLocalModel() throws {
        let expect = expectation(description: "action .reconciled notified")
        stateMachine.setExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.reconciled(self.anyPost))
            expect.fulfill()
        }
        stateMachine.state = .reconciling(anyPost, nil)

        waitForExpectations(timeout: 1)
    }

    func testSaving() throws {
        let expect = expectation(description: "action .saved notified")
        stateMachine.setExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.saved(self.anyPost))
            expect.fulfill()
        }
        storageAdapter.returnOnSave(dataStoreResult: .success(anyPost))

        stateMachine.state = .saving(anyPost)

        waitForExpectations(timeout: 1)
    }

    func testSavingWithInvalidStorageAdapter() throws {
        storageAdapter = nil

        stateMachine.state = .saving(anyPost)

        //TODO: Consider going to error state?
        //Currently there is not good way to verify this
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.saving(anyPost))
    }

    func testSavingWithError() throws {
        let expect = expectation(description: ".action errored notified")
        let error = DataStoreError.invalidModelName("invalidModelName--save")
        storageAdapter.returnOnSave(dataStoreResult: .failure(error))
        stateMachine.setExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .saving(anyPost)

        waitForExpectations(timeout: 1)
    }

    func testNotifying() throws {
        let hubExpect = expectation(description: "Hub is notified")
        let notifyExpect = expectation(description: "action .notified notified")
        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            XCTAssertEqual(payload.eventName, "DataStore.syncReceived")
            hubExpect.fulfill()
        }
        stateMachine.setExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.notified)
            notifyExpect.fulfill()
        }

        stateMachine.state = .notifying(anyPost)

        waitForExpectations(timeout: 1)
        Amplify.Hub.removeListener(hubListener)
    }
}

class MockStateMachine: StateMachine<ReconcileAndLocalSaveOperation.State, ReconcileAndLocalSaveOperation.Action> {
    typealias ExpectActionCriteria = (_ action: ReconcileAndLocalSaveOperation.Action) -> Void
    var expectActionCriteria: ExpectActionCriteria?

    override func notify(action: ReconcileAndLocalSaveOperation.Action) {
        if let expectActionCriteria = expectActionCriteria {
            expectActionCriteria(action)
        }
    }

    func setExpectActionCriteria(expectActionCriteria: @escaping ExpectActionCriteria) {
        self.expectActionCriteria = expectActionCriteria
    }
}

extension ReconcileAndLocalSaveOperation.State: Equatable {
    public static func == (lhs: ReconcileAndLocalSaveOperation.State, rhs: ReconcileAndLocalSaveOperation.State) -> Bool {
        switch (lhs, rhs) {
        case (.waiting, .waiting):
            return true
        case (.deserializing(let model1), .deserializing(let model2)):
            return model1.id == model2.id
                && model1.modelName == model2.modelName
        case (.querying(let model1), .querying(let model2)):
            return model1.id == model2.id
                && model1.modelName == model2.modelName
        case (.reconciling(let model1, let lmodel1), .reconciling(let model2, let lmodel2)):
            return model1.id == model2.id
                && lmodel1?.id == lmodel2?.id
                && model1.modelName == model2.modelName
                && lmodel1?.modelName == lmodel2?.modelName
        case (.saving(let model1), .saving(let model2)):
            return model1.id == model2.id
                && model1.modelName == model2.modelName
        case (.notifying(let model1), .notifying(let model2)):
            return model1.id == model2.id
                && model1.modelName == model2.modelName
        case (.finished, .finished):
            return true
        case (.inError(let error1), .inError(let error2)):
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
            return model1.id == model2.id
                && model1.modelName == model2.modelName
        case (.deserialized(let model1), .deserialized(let model2)):
            return model1.id == model2.id
                && model1.modelName == model2.modelName
        case (.queried(let model1, let lmodel1), .queried(let model2, let lmodel2)):
            return model1.id == model2.id
                && lmodel1?.id == lmodel2?.id
                && model1.modelName == model2.modelName
                && lmodel1?.modelName == lmodel2?.modelName
        case (.reconciled(let model1), .reconciled(let model2)):
            return model1.id == model2.id
                && model1.modelName == model2.modelName
        case (.cancelled, .cancelled):
            return true
        case (.conflicted(let model1, let lmodel1), .conflicted(let model2, let lmodel2)):
            return model1.id == model2.id
                && lmodel1.id == lmodel2.id
                && model1.modelName == model2.modelName
                && lmodel1.modelName == lmodel2.modelName
        case (.saved(let model1), .saved(let model2)):
            return model1.id == model2.id
                && model1.modelName == model2.modelName
        case (.notified, .notified):
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

    init() {
        self.resultForQuery = nil
        self.resultForSave = nil
    }
    func setUp(models: [Model.Type]) throws {
        XCTFail("Not expected to execute")
    }
    func save<M: Model>(_ model: M, completion: @escaping DataStoreCallback<M>) {
        XCTFail("Not expected to execute")
    }
    func delete(_ modelType: Model.Type, withId id: Model.Identifier, completion: DataStoreCallback<Void>) {
        XCTFail("Not expected to execute")
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
    func returnOnQuery(dataStoreResult: DataStoreResult<[Model]>?) {
        resultForQuery = dataStoreResult
    }
    func query(untypedModel modelType: Model.Type,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>) {
        let result = resultForQuery ?? .failure(DataStoreError.invalidOperation(causedBy: nil))
        completion(result)
    }
    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         additionalStatements: String?,
                         completion: (Result<[M], DataStoreError>) -> Void) {
        completion(.failure(DataStoreError.invalidOperation(causedBy: nil)))
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
    func delete(_ modelType: Model.Type,
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
        let dataStorePlugin = AWSDataStoreCategoryPlugin(modelRegistration: TestModelRegistration(),
                                                         storageEngine: storageEngine,
                                                         dataStorePublisher: dataStorePublisher)
        try Amplify.add(plugin: dataStorePlugin)
        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStoreCategoryPlugin": true
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
