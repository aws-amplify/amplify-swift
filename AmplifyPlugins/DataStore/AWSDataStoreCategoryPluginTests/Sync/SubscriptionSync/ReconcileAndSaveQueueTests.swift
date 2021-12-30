//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class ReconcileAndSaveQueueTests: XCTestCase {
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    var anyPostMetadata: MutationSyncMetadata!
    var anyPostMutationSync: MutationSync<AnyModel>!
    var stateMachine: MockStateMachine<ReconcileAndLocalSaveOperation.State, ReconcileAndLocalSaveOperation.Action>!
    override func setUp() {
        ModelRegistry.register(modelType: Post.self)
        let testPost = Post(id: "1", title: "post1", content: "content", createdAt: .now())
        let anyPost = AnyModel(testPost)
        anyPostMetadata = MutationSyncMetadata(modelId: "1",
                                               modelName: testPost.modelName,
                                               deleted: false,
                                               lastChangedAt: Int(Date().timeIntervalSince1970),
                                               version: 1)
        anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)
        anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)
        storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQuery(dataStoreResult: .none)
        storageAdapter.returnOnSave(dataStoreResult: .none)
        stateMachine = MockStateMachine(initialState: .waiting,
                                        resolver: ReconcileAndLocalSaveOperation.Resolver.resolve(currentState:action:))
    }

    func testAddOperation() throws {
        let operationAdded = expectation(description: "operation added")
        let operationRemoved = expectation(description: "operation removed")
        let queue = ReconcileAndSaveQueue([Post.schema])
        let sink = queue.publisher.sink { completion in
            print(completion)
        } receiveValue: { event in
            switch event {
            case .operationAdded:
                operationAdded.fulfill()
            case .operationRemoved:
                operationRemoved.fulfill()
            default:
                return
            }
        }
        let operation = ReconcileAndLocalSaveOperation(modelSchema: anyPostMutationSync.model.schema,
                                                       remoteModels: [anyPostMutationSync],
                                                       storageAdapter: storageAdapter,
                                                       stateMachine: stateMachine)
        queue.addOperation(operation, modelName: Post.modelName)
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.waiting)
        wait(for: [operationAdded], timeout: 1)
        stateMachine.state = .finished
        wait(for: [operationRemoved], timeout: 1)
    }

    func testCancelOperationsForModelName() {
        let operationAdded = expectation(description: "operation added")
        let cancelledOperations = expectation(description: "cancelled operations")
        let queue = ReconcileAndSaveQueue([Post.schema])
        let sink = queue.publisher.sink { completion in
            print(completion)
        } receiveValue: { event in
            switch event {
            case .operationAdded:
                operationAdded.fulfill()
            case .cancelledOperations(let modelName):
                XCTAssertEqual(modelName, Post.modelName)
                cancelledOperations.fulfill()
            default:
                return
            }
        }
        let operation = ReconcileAndLocalSaveOperation(modelSchema: anyPostMutationSync.model.schema,
                                                       remoteModels: [anyPostMutationSync],
                                                       storageAdapter: storageAdapter,
                                                       stateMachine: stateMachine)
        queue.addOperation(operation, modelName: Post.modelName)
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.waiting)
        wait(for: [operationAdded], timeout: 1)

        queue.cancelOperations(modelName: Post.modelName)
        wait(for: [cancelledOperations], timeout: 1)
    }

    func testCancelAllOperations() {
        let operationAdded = expectation(description: "operation added")
        let cancelledOperations = expectation(description: "cancelled operations")
        let queue = ReconcileAndSaveQueue([Post.schema])
        let sink = queue.publisher.sink { completion in
            print(completion)
        } receiveValue: { event in
            switch event {
            case .operationAdded:
                operationAdded.fulfill()
            case .cancelledOperations(let modelName):
                XCTAssertEqual(modelName, Post.modelName)
                cancelledOperations.fulfill()
            default:
                return
            }
        }
        let operation = ReconcileAndLocalSaveOperation(modelSchema: anyPostMutationSync.model.schema,
                                                       remoteModels: [anyPostMutationSync],
                                                       storageAdapter: storageAdapter,
                                                       stateMachine: stateMachine)
        queue.addOperation(operation, modelName: Post.modelName)
        XCTAssertEqual(stateMachine.state, ReconcileAndLocalSaveOperation.State.waiting)
        wait(for: [operationAdded], timeout: 1)

        queue.cancelAllOperations()
        wait(for: [cancelledOperations], timeout: 1)
    }
}
