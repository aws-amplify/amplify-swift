//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class ReconcileAndLocalSaveOperationTests: XCTestCase {
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    var anyPostMetadata: MutationSyncMetadata!
    var anyPostMutationSync: MutationSync<AnyModel>!
    var anyPostDeletedMutationSync: MutationSync<AnyModel>!
    var anyPostMutationEvent: MutationEvent!
    var operation: ReconcileAndLocalSaveOperation!
    var stateMachine: MockStateMachine<ReconcileAndLocalSaveOperation.State, ReconcileAndLocalSaveOperation.Action>!
    var cancellables: Set<AnyCancellable>!
    override func setUp() {
        tryOrFail {
            try setUpWithAPI()
        }
        ModelRegistry.register(modelType: Post.self)

        let testPost = Post(id: "1", title: "post1", content: "content", createdAt: .now())
        let anyPost = AnyModel(testPost)
        anyPostMetadata = MutationSyncMetadata(modelId: "1",
                                               modelName: testPost.modelName,
                                               deleted: false,
                                               lastChangedAt: Int(Date().timeIntervalSince1970),
                                               version: 1)
        anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)

        let testDelete = Post(id: "2", title: "post2", content: "content2", createdAt: .now())
        let anyPostDelete = AnyModel(testDelete)
        let anyPostDeleteMetadata = MutationSyncMetadata(modelId: "2",
                                                         modelName: testPost.modelName,
                                                         deleted: true,
                                                         lastChangedAt: Int(Date().timeIntervalSince1970),
                                                         version: 2)
        anyPostDeletedMutationSync = MutationSync<AnyModel>(model: anyPostDelete, syncMetadata: anyPostDeleteMetadata)
        anyPostMutationEvent = MutationEvent(id: "1",
                                             modelId: "3",
                                             modelName: testPost.modelName,
                                             json: "",
                                             mutationType: .create)
        storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQuery(dataStoreResult: .none)
        storageAdapter.returnOnSave(dataStoreResult: .none)
        stateMachine = MockStateMachine(initialState: .waiting,
                                        resolver: ReconcileAndLocalSaveOperation.Resolver.resolve(currentState:action:))

        operation = ReconcileAndLocalSaveOperation(modelSchema: anyPostMutationSync.model.schema,
                                                   remoteModels: [anyPostMutationSync],
                                                   storageAdapter: storageAdapter,
                                                   stateMachine: stateMachine)
        cancellables = Set<AnyCancellable>()
    }

    func testCreateOperation() throws {
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.waiting)
    }

    // MARK: - State tests

    func testReconcile() {
        let expect = expectation(description: "action .reconciled")

        storageAdapter.returnOnSave(dataStoreResult: .success(anyPostMutationSync.model))
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.reconciled)
            expect.fulfill()
        }

        stateMachine.state = .reconciling([anyPostMutationSync])

        waitForExpectations(timeout: 1)
    }

    func testReconcile_nilStorageAdapter() {
        let expect = expectation(description: "action .errored")

        storageAdapter = nil
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action,
                           ReconcileAndLocalSaveOperation.Action.errored(DataStoreError.nilStorageAdapter()))
            expect.fulfill()
        }

        stateMachine.state = .reconciling([anyPostMutationSync])

        waitForExpectations(timeout: 1)
    }

    func testReconcile_emptyRemoteModels() {
        let expect = expectation(description: "action .reconciled")

        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.reconciled)
            expect.fulfill()
        }

        stateMachine.state = .reconciling([])

        waitForExpectations(timeout: 1)
    }

    func testReconcile_failedQueryPendingMutations() {
        let expect = expectation(description: "action .reconciled")

        let expectedError = DataStoreError.internalOperation("Query failed", "")
        let queryResponder = QueryModelTypePredicateResponder<MutationEvent> { _, _ in
            return .failure(expectedError)
        }
        storageAdapter.responders[.queryModelTypePredicate] = queryResponder
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(expectedError))
            expect.fulfill()
        }

        stateMachine.state = .reconciling([anyPostMutationSync])

        waitForExpectations(timeout: 1)
    }

    func testReconcile_transactionDataStoreError() {
        let expect = expectation(description: "action .errored")

        let error = DataStoreError.internalOperation("Transaction failed", "")
        storageAdapter.errorToThrowOnTransaction = error
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .reconciling([anyPostMutationSync])

        waitForExpectations(timeout: 1)
    }

    func testReconcile_transactionError() {
        let expect = expectation(description: "action .errored")

        enum UnknownError: Error {
            case unknown
        }
        storageAdapter.errorToThrowOnTransaction = UnknownError.unknown
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, ReconcileAndLocalSaveOperation.Action.errored(
                            DataStoreError.invalidOperation(causedBy: UnknownError.unknown)))
            expect.fulfill()
        }

        stateMachine.state = .reconciling([anyPostMutationSync])

        waitForExpectations(timeout: 1)
    }

    func testInError() {
        let expect = expectation(description: "publisher should finish")
        operation.publisher.sink { completion in
            switch completion {
            case .finished:
                expect.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        } receiveValue: { _ in }.store(in: &cancellables)

        stateMachine.state = .inError(DataStoreError.unknown("InError State", ""))
        waitForExpectations(timeout: 1)
    }

    func testFinished() {
        let expect = expectation(description: "publisher should finish")
        operation.publisher.sink { completion in
            switch completion {
            case .finished:
                expect.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        } receiveValue: { _ in }.store(in: &cancellables)

        stateMachine.state = .finished
        waitForExpectations(timeout: 1)
    }

    // MARK: - queryPendingMutations

    func testQueryPendingMutations_nilStorageAdapter() {
        let expect = expectation(description: "storage adapter error")

        storageAdapter = nil
        operation.queryPendingMutations(forModelIds: [anyPostMutationSync.model.id])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTAssertEqual(error.errorDescription, DataStoreError.nilStorageAdapter().errorDescription)
                    expect.fulfill()
                case .finished:
                    XCTFail("Should have failed")
                }
            }, receiveValue: { mutationEvents in
                XCTFail("Unexpected \(mutationEvents)")
            }).store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testQueryPendingMutations_emptyModels() {
        let expect = expectation(description: "should complete successfully for empty input")
        expect.expectedFulfillmentCount = 2

        operation.queryPendingMutations(forModelIds: [])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected failure \(error)")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { mutationEvents in
                XCTAssertTrue(mutationEvents.isEmpty)
                expect.fulfill()
            }).store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testQueryPendingMutations_querySuccess() {
        let expect = expectation(description: "queried pending mutations success")
        expect.expectedFulfillmentCount = 2

        let queryResponder = QueryModelTypePredicateResponder<MutationEvent> { _, _ in
            return .success([self.anyPostMutationEvent])
        }
        storageAdapter.responders[.queryModelTypePredicate] = queryResponder
        operation.queryPendingMutations(forModelIds: [anyPostMutationSync.model.id])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected failure \(error)")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { mutationEvents in
                XCTAssertEqual(mutationEvents, [self.anyPostMutationEvent])
                expect.fulfill()
            }).store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testQueryPendingMutations_queryFailure() {
        let expect = expectation(description: "queried pending mutations failed")

        let queryResponder = QueryModelTypePredicateResponder<MutationEvent> { _, _ in
            return .failure(DataStoreError.internalOperation("Query failed", ""))
        }
        storageAdapter.responders[.queryModelTypePredicate] = queryResponder
        operation.queryPendingMutations(forModelIds: [anyPostMutationSync.model.id])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    expect.fulfill()
                case .finished:
                    XCTFail("Expected to complete with failure")
                }
            }, receiveValue: { _ in
                XCTFail("Should not return a value")
            }).store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    // MARK: - reconcile(remoteModels:pendingMutations)

    func testReconcilePendingMutations_emptyModels() {
        let result = operation.reconcile([], pendingMutations: [anyPostMutationEvent])

        XCTAssertTrue(result.isEmpty)
    }

    func testReconcilePendingMutations_emptyPendingMutations() {
        let result = operation.reconcile([anyPostMutationSync], pendingMutations: [])

        guard let remoteModelToApply = result.first else {
            XCTFail("Missing models to apply")
            return
        }
        XCTAssertEqual(remoteModelToApply.model.id, anyPostMutationSync.model.id)
    }

    func testReconcilePendingMutations_notifyDropped() {
        let expect = expectation(description: "notify dropped twice")
        expect.expectedFulfillmentCount = 2
        let model1 = AnyModel(Post(title: "post1", content: "content", createdAt: .now()))
        let model2 = AnyModel(Post(title: "post2", content: "content", createdAt: .now()))
        let metadata1 = MutationSyncMetadata(modelId: model1.id,
                                             modelName: model1.modelName,
                                             deleted: false,
                                             lastChangedAt: Int(Date().timeIntervalSince1970),
                                             version: 1)
        let metadata2 = MutationSyncMetadata(modelId: model2.id,
                                             modelName: model2.modelName,
                                             deleted: false,
                                             lastChangedAt: Int(Date().timeIntervalSince1970),
                                             version: 1)
        let remoteModel1 = MutationSync<AnyModel>(model: model1, syncMetadata: metadata1)
        let remoteModel2 = MutationSync<AnyModel>(model: model2, syncMetadata: metadata2)

        let mutationEvent1 = MutationEvent(id: "1",
                                           modelId: remoteModel1.model.id,
                                           modelName: remoteModel1.model.modelName,
                                           json: "",
                                           mutationType: .create)
        let mutationEvent2 = MutationEvent(id: "2",
                                           modelId: remoteModel2.model.id,
                                           modelName: remoteModel2.model.modelName,
                                           json: "",
                                           mutationType: .create)
        operation.publisher
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Unexpected completion")
                case .failure(let error):
                    XCTFail("Unexpected error \(error)")
                }
            } receiveValue: { (event: ReconcileAndLocalSaveOperationEvent) in
                switch event {
                case .mutationEventDropped(let name):
                    XCTAssertEqual(name, Post.modelName)
                    expect.fulfill()
                default:
                    break
                }
            }.store(in: &cancellables)

        let result = operation.reconcile([remoteModel1, remoteModel2],
                                         pendingMutations: [mutationEvent1, mutationEvent2])

        XCTAssertTrue(result.isEmpty)
        waitForExpectations(timeout: 1)
    }

    // MARK: - queryLocalMetadata

    func testQueryLocalMetadata_nilStorageAdapter() {
        let expect = expectation(description: "storage adapter error")

        storageAdapter = nil
        operation.queryLocalMetadata([anyPostMutationSync])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTAssertEqual(error.errorDescription, DataStoreError.nilStorageAdapter().errorDescription)
                    expect.fulfill()
                case .finished:
                    XCTFail("Should have failed")
                }
            }, receiveValue: { result in
                XCTFail("Unexpected \(result)")
            }).store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testQueryLocalMetadata_emptyModels() {
        let expect = expectation(description: "should complete successfully for empty input")
        expect.expectedFulfillmentCount = 2

        operation.queryLocalMetadata([])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected failure \(error)")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { remoteModels, localMetadatas in
                XCTAssertTrue(remoteModels.isEmpty)
                XCTAssertTrue(localMetadatas.isEmpty)
                expect.fulfill()
            }).store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testQueryLocalMetadata_querySuccess() {
        let expect = expectation(description: "queried local metadata success")
        expect.expectedFulfillmentCount = 2

        storageAdapter.returnOnQueryMutationSyncMetadatas([anyPostMetadata])
        operation.queryLocalMetadata([anyPostMutationSync])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected failure \(error)")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { remoteModels, localMetadatas in
                guard let remoteModel = remoteModels.first else {
                    XCTFail("Empty remote models")
                    return
                }
                XCTAssertEqual(remoteModel.model.id, self.anyPostMutationSync.model.id)
                guard let localMetadata = localMetadatas.first else {
                    XCTFail("Empty local metadata")
                    return
                }
                XCTAssertEqual(localMetadata, self.anyPostMetadata)
                expect.fulfill()
            }).store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    // MARK: - reconcile(remoteModels:localMetadata)

    func testReconcileLocalMetadata_emptyModels() {
        let result = operation.getDispositions(for: [], localMetadatas: [anyPostMetadata])

        XCTAssertTrue(result.isEmpty)
    }

    func testReconcileLocalMetadata_emptyLocalMetadatas() {
        let result = operation.getDispositions(for: [anyPostMutationSync], localMetadatas: [])

        guard let remoteModelDisposition = result.first else {
            XCTFail("Missing models to apply")
            return
        }
        XCTAssertEqual(remoteModelDisposition, .create(anyPostMutationSync))
    }

    func testReconcileLocalMetadata_success() {
        let expect = expectation(description: "notify dropped twice")
        expect.expectedFulfillmentCount = 2
        let model1 = AnyModel(Post(title: "post1", content: "content", createdAt: .now()))
        let model2 = AnyModel(Post(title: "post2", content: "content", createdAt: .now()))
        let metadata1 = MutationSyncMetadata(modelId: model1.id,
                                             modelName: model1.modelName,
                                             deleted: false,
                                             lastChangedAt: Int(Date().timeIntervalSince1970),
                                             version: 1)
        let metadata2 = MutationSyncMetadata(modelId: model2.id,
                                             modelName: model2.modelName,
                                             deleted: false,
                                             lastChangedAt: Int(Date().timeIntervalSince1970),
                                             version: 1)
        let remoteModel1 = MutationSync<AnyModel>(model: model1, syncMetadata: metadata1)
        let remoteModel2 = MutationSync<AnyModel>(model: model2, syncMetadata: metadata2)

        let localMetadata1 = MutationSyncMetadata(modelId: model1.id,
                                                  modelName: model1.modelName,
                                                  deleted: false,
                                                  lastChangedAt: Int(Date().timeIntervalSince1970),
                                                  version: 3)
        let localMetadata2 = MutationSyncMetadata(modelId: model2.id,
                                                  modelName: model2.modelName,
                                                  deleted: false,
                                                  lastChangedAt: Int(Date().timeIntervalSince1970),
                                                  version: 4)
        operation.publisher
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Unexpected completion")
                case .failure(let error):
                    XCTFail("Unexpected error \(error)")
                }
            } receiveValue: { (event: ReconcileAndLocalSaveOperationEvent) in
                switch event {
                case .mutationEventDropped(let name):
                    XCTAssertEqual(name, Post.modelName)
                    expect.fulfill()
                default:
                    break
                }
            }.store(in: &cancellables)

        let result = operation.getDispositions(for: [remoteModel1, remoteModel2],
                                                  localMetadatas: [localMetadata1, localMetadata2])

        XCTAssertTrue(result.isEmpty)
        waitForExpectations(timeout: 1)
    }

    // MARK: - applyRemoteModels

    func testApplyRemoteModels_nilStorageAdapter() {
        let expect = expectation(description: "storage adapter error")

        storageAdapter = nil
        operation.applyRemoteModelsDispositions([])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTAssertEqual(error.errorDescription, DataStoreError.nilStorageAdapter().errorDescription)
                    expect.fulfill()
                case .finished:
                    XCTFail("Should have failed")
                }
            }, receiveValue: { result in
                XCTFail("Unexpected \(result)")
            }).store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModels_emptyDisposition() {
        let expect = expectation(description: "should complete successfully")
        expect.expectedFulfillmentCount = 2

        operation.applyRemoteModelsDispositions([])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected failure \(error)")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { _ in
                expect.fulfill()
            }).store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModels_createDisposition() {
        let expect = expectation(description: "operation should send value and complete successfully")
        expect.expectedFulfillmentCount = 2
        let stoargeExpect = expectation(description: "storage save should be called")
        let storageMetadataExpect = expectation(description: "storage save metadata should be called")
        let notifyExpect = expectation(description: "mutation event should be emitted")
        let hubExpect = expectation(description: "Hub is notified")
        let saveResponder = SaveUntypedModelResponder { model, completion in
            stoargeExpect.fulfill()
            completion(.success(model))
        }

        storageAdapter.responders[.saveUntypedModel] = saveResponder

        let saveMetadataResponder = SaveModelCompletionResponder<MutationSyncMetadata> { model, completion in
            storageMetadataExpect.fulfill()
            completion(.success(model))
        }
        storageAdapter.responders[.saveModelCompletion] = saveMetadataResponder

        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.syncReceived" {
                hubExpect.fulfill()
            }
        }
        operation.publisher
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Unexpected completion")
                case .failure(let error):
                    XCTFail("Unexpected error \(error)")
                }
            } receiveValue: { (event: ReconcileAndLocalSaveOperationEvent) in
                switch event {
                case .mutationEvent(let mutationEvent):
                    XCTAssertEqual(mutationEvent.modelId, self.anyPostMutationSync.model.id)
                    notifyExpect.fulfill()
                default:
                    break
                }
            }.store(in: &cancellables)

        operation.applyRemoteModelsDispositions([.create(anyPostMutationSync)])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected failure \(error)")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { _ in
                expect.fulfill()
            }).store(in: &cancellables)
        waitForExpectations(timeout: 1)
        Amplify.Hub.removeListener(hubListener)
    }

    func testApplyRemoteModels_updateDisposition() {
        let expect = expectation(description: "operation should send value and complete successfully")
        expect.expectedFulfillmentCount = 2
        let stoargeExpect = expectation(description: "storage save should be called")
        let storageMetadataExpect = expectation(description: "storage save metadata should be called")
        let notifyExpect = expectation(description: "mutation event should be emitted")
        let hubExpect = expectation(description: "Hub is notified")
        let saveResponder = SaveUntypedModelResponder { _, completion in
            stoargeExpect.fulfill()
            completion(.success(self.anyPostMutationSync.model))
        }
        storageAdapter.responders[.saveUntypedModel] = saveResponder

        let saveMetadataResponder = SaveModelCompletionResponder<MutationSyncMetadata> { model, completion in
            storageMetadataExpect.fulfill()
            completion(.success(model))
        }
        storageAdapter.responders[.saveModelCompletion] = saveMetadataResponder
        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.syncReceived" {
                hubExpect.fulfill()
            }
        }
        operation.publisher
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Unexpected completion")
                case .failure(let error):
                    XCTFail("Unexpected error \(error)")
                }
            } receiveValue: { (event: ReconcileAndLocalSaveOperationEvent) in
                switch event {
                case .mutationEvent(let mutationEvent):
                    XCTAssertEqual(mutationEvent.modelId, self.anyPostMutationSync.model.id)
                    notifyExpect.fulfill()
                default:
                    break
                }
            }.store(in: &cancellables)

        operation.applyRemoteModelsDispositions([.update(anyPostMutationSync)])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected failure \(error)")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { _ in
                expect.fulfill()
            }).store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModels_deleteDisposition() {
        let expect = expectation(description: "operation should send value and complete successfully")
        expect.expectedFulfillmentCount = 2
        let stoargeExpect = expectation(description: "storage delete should be called")
        let storageMetadataExpect = expectation(description: "storage save metadata should be called")
        let notifyExpect = expectation(description: "mutation event should be emitted")
        let hubExpect = expectation(description: "Hub is notified")
        let deleteResponder = DeleteUntypedModelCompletionResponder { _, id in
            XCTAssertEqual(id, self.anyPostMutationSync.model.id)
            stoargeExpect.fulfill()
            return .emptyResult
        }
        storageAdapter.responders[.deleteUntypedModel] = deleteResponder

        let saveMetadataResponder = SaveModelCompletionResponder<MutationSyncMetadata> { model, completion in
            storageMetadataExpect.fulfill()
            completion(.success(model))
        }
        storageAdapter.responders[.saveModelCompletion] = saveMetadataResponder
        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.syncReceived" {
                hubExpect.fulfill()
            }
        }
        operation.publisher
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Unexpected completion")
                case .failure(let error):
                    XCTFail("Unexpected error \(error)")
                }
            } receiveValue: { (event: ReconcileAndLocalSaveOperationEvent) in
                switch event {
                case .mutationEvent(let mutationEvent):
                    XCTAssertEqual(mutationEvent.modelId, self.anyPostMutationSync.model.id)
                    notifyExpect.fulfill()
                default:
                    break
                }
            }.store(in: &cancellables)

        operation.applyRemoteModelsDispositions([.delete(anyPostMutationSync)])
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected failure \(error)")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { _ in
                expect.fulfill()
            }).store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModels_multipleDispositions() {
        let dispositions: [RemoteSyncReconciler.Disposition] = [.create(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync)]
        let expect = expectation(description: "should complete successfully")
        expect.expectedFulfillmentCount = 2
        let stoargeExpect = expectation(description: "storage save/delete should be called")
        stoargeExpect.expectedFulfillmentCount = dispositions.count
        let storageMetadataExpect = expectation(description: "storage save metadata should be called")
        storageMetadataExpect.expectedFulfillmentCount = dispositions.count
        let notifyExpect = expectation(description: "mutation event should be emitted")
        notifyExpect.expectedFulfillmentCount = dispositions.count
        let hubExpect = expectation(description: "Hub is notified")
        hubExpect.expectedFulfillmentCount = dispositions.count

        let saveResponder = SaveUntypedModelResponder { _, completion in
            stoargeExpect.fulfill()
            completion(.success(self.anyPostMutationSync.model))
        }
        storageAdapter.responders[.saveUntypedModel] = saveResponder

        let deleteResponder = DeleteUntypedModelCompletionResponder { _, id in
            XCTAssertEqual(id, self.anyPostMutationSync.model.id)
            stoargeExpect.fulfill()
            return .emptyResult
        }
        storageAdapter.responders[.deleteUntypedModel] = deleteResponder

        let saveMetadataResponder = SaveModelCompletionResponder<MutationSyncMetadata> { model, completion in
            storageMetadataExpect.fulfill()
            completion(.success(model))
        }
        storageAdapter.responders[.saveModelCompletion] = saveMetadataResponder
        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.syncReceived" {
                hubExpect.fulfill()
            }
        }
        operation.publisher
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Unexpected completion")
                case .failure(let error):
                    XCTFail("Unexpected error \(error)")
                }
            } receiveValue: { (event: ReconcileAndLocalSaveOperationEvent) in
                switch event {
                case .mutationEvent(let mutationEvent):
                    XCTAssertEqual(mutationEvent.modelId, self.anyPostMutationSync.model.id)
                    notifyExpect.fulfill()
                default:
                    break
                }
            }.store(in: &cancellables)

        operation.applyRemoteModelsDispositions(dispositions)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected failure \(error)")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { _ in
                expect.fulfill()
            }).store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModels_saveFail() {
        let dispositions: [RemoteSyncReconciler.Disposition] = [.create(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync)]
        let expect = expectation(description: "should fail")
        let saveResponder = SaveUntypedModelResponder { _, completion in
            completion(.failure(DataStoreError.internalOperation("Failed to save", "")))
        }
        storageAdapter.responders[.saveUntypedModel] = saveResponder

        operation.applyRemoteModelsDispositions(dispositions)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    expect.fulfill()
                case .finished:
                    XCTFail("Unexpected successfully completion")
                }
            }, receiveValue: { _ in
                XCTFail("Unexpected value received")
            }).store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModels_failWithConstraintViolationShouldBeSuccessful() {
        let expect = expectation(description: "should complete successfully")
        expect.expectedFulfillmentCount = 2
        let dispositions: [RemoteSyncReconciler.Disposition] = [.create(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync)]
        let expectDropped = expectation(description: "should notify dropped")
        expectDropped.expectedFulfillmentCount = dispositions.count
        let dataStoreError = DataStoreError.internalOperation("Failed to save", "")
        let saveResponder = SaveUntypedModelResponder { _, completion in
            completion(.failure(dataStoreError))
        }
        storageAdapter.shouldIgnoreError = true
        storageAdapter.responders[.saveUntypedModel] = saveResponder
        let deleteResponder = DeleteUntypedModelCompletionResponder { _, _ in
            return .failure(dataStoreError)
        }
        storageAdapter.responders[.deleteUntypedModel] = deleteResponder

        operation.publisher
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Unexpected completion")
                case .failure(let error):
                    XCTFail("Unexpected error \(error)")
                }
            } receiveValue: { (event: ReconcileAndLocalSaveOperationEvent) in
                switch event {
                case .mutationEventDropped:
                    expectDropped.fulfill()
                default:
                    break
                }
            }.store(in: &cancellables)

        operation.applyRemoteModelsDispositions(dispositions)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    XCTFail("Unexpected failure")
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { _ in
                expect.fulfill()
            }).store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModels_deleteFail() {
        let dispositions: [RemoteSyncReconciler.Disposition] = [.create(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync)]
        let expect = expectation(description: "should fail")
        let saveResponder = SaveUntypedModelResponder { _, completion in
            completion(.success(self.anyPostMutationSync.model))
        }
        storageAdapter.responders[.saveUntypedModel] = saveResponder
        storageAdapter.shouldReturnErrorOnDeleteMutation = true

        operation.applyRemoteModelsDispositions(dispositions)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    expect.fulfill()
                case .finished:
                    XCTFail("Unexpected successfully completion")
                }
            }, receiveValue: { _ in
                XCTFail("Unexpected value received")
            }).store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func testApplyRemoteModels_saveMetadataFail() {
        let dispositions: [RemoteSyncReconciler.Disposition] = [.create(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .delete(anyPostMutationSync),
                                                                .create(anyPostMutationSync),
                                                                .update(anyPostMutationSync),
                                                                .delete(anyPostMutationSync)]
        let expect = expectation(description: "should fail")
        let saveResponder = SaveUntypedModelResponder { _, completion in
            completion(.success(self.anyPostMutationSync.model))
        }
        storageAdapter.responders[.saveUntypedModel] = saveResponder
        let saveMetadataResponder = SaveModelCompletionResponder<MutationSyncMetadata> { _, completion in
            completion(.failure(.internalOperation("Failed to save metadata", "")))
        }
        storageAdapter.responders[.saveModelCompletion] = saveMetadataResponder

        operation.applyRemoteModelsDispositions(dispositions)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    expect.fulfill()
                case .finished:
                    XCTFail("Unexpected successfully completion")
                }
            }, receiveValue: { _ in
                XCTFail("Unexpected value received")
            }).store(in: &cancellables)
        waitForExpectations(timeout: 1)
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
