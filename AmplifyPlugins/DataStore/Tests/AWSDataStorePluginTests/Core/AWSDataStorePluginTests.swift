//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyTestCommon
@_implementationOnly import AmplifyAsyncTesting

@testable import Amplify
@testable import AWSDataStorePlugin

// swiftlint:disable type_body_length
class AWSDataStorePluginTests: XCTestCase {
    func testStorageEngineDoesNotStartsOnConfigure() throws {
        let startExpectation = expectation(description: "Start Sync should not be called")
        startExpectation.isInverted = true
        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.startSync] = StartSyncResponder { _ in
            startExpectation.fulfill()
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")
        do {
            try plugin.configure(using: nil)
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
        waitForExpectations(timeout: 1.0)
    }

    func testStorageEngineStartsOnPluginStart() throws {
        let startExpectation = expectation(description: "Start Sync should be called")
        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.startSync] = StartSyncResponder { _ in
            startExpectation.fulfill()
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")
        do {
            try plugin.configure(using: nil)
            plugin.start(completion: {_ in})
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
        waitForExpectations(timeout: 1.0)
    }

    func testStorageEngineStartsOnQuery() async throws {
        let startExpectation = expectation(description: "Start Sync should be called with Query")
        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.startSync] = StartSyncResponder { _ in
            startExpectation.fulfill()
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")
        do {
            try plugin.configure(using: nil)
            let queryCompleted = asyncExpectation(description: "query completed")
            Task {
                _ = try await plugin.query(ExampleWithEveryType.self)
                await queryCompleted.fulfill()
            }
            await waitForExpectations([queryCompleted], timeout: 1.0)
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
        await waitForExpectations(timeout: 1.0)
    }
    
    func testStorageEngineStartsOnPluginStopStart() throws {
        let stopExpectation = expectation(description: "Stop plugin should be called")
        stopExpectation.isInverted = true
        let startExpectation = expectation(description: "Start Sync should be called")
        var currCount = 0
        let storageEngine = MockStorageEngineBehavior()
        
        storageEngine.responders[.stopSync] = StopSyncResponder { _ in
            stopExpectation.fulfill()
        }
        
        storageEngine.responders[.startSync] = StartSyncResponder { _ in
            currCount = self.expect(startExpectation, currCount, 1)
        }
        
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")
        
        do {
            try plugin.configure(using: nil)
            XCTAssertNil(plugin.storageEngine)
            
            plugin.stop(completion: { _ in
                plugin.start(completion: { _ in })
            })
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func testStorageEngineStartsOnPluginClearStart() throws {
        let clearExpectation = expectation(description: "Clear should be called")
        let startExpectation = expectation(description: "Start Sync should be called")
        var currCount = 0
        
        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.clear] = ClearResponder { _ in
            currCount = self.expect(clearExpectation, currCount, 1)
        }
        
        storageEngine.responders[.startSync] = StartSyncResponder { _ in
            currCount = self.expect(startExpectation, currCount, 2)
        }
        
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")
        
        do {
            try plugin.configure(using: nil)
            XCTAssertNil(plugin.storageEngine)
            
            plugin.clear(completion: { _ in
                plugin.start(completion: { _ in })
            })
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
        waitForExpectations(timeout: 1.0)
    }

    func testStorageEngineStartStopStart() throws {
        let startExpectation = expectation(description: "Start Sync should be called with start")
        let stopExpectation = expectation(description: "stop should be called")
        let startExpectationOnSecondStart = expectation(description: "Start Sync should be called again")
        var count = 0

        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.startSync] = StartSyncResponder { _ in
            count = self.expect(startExpectation, count, 1)
        }
        storageEngine.responders[.stopSync] = StopSyncResponder { _ in
            count = self.expect(stopExpectation, count, 2)
        }

        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")

        let finishNotReceived = expectation(
            description: "publisher should not receive .finished completion event after stop() is called")
        finishNotReceived.isInverted = true

        do {
            try plugin.configure(using: nil)
            XCTAssertNil(plugin.storageEngine)

            let sink = plugin.publisher.sink { completion in
                switch completion {
                case .finished:
                    finishNotReceived.fulfill()
                case .failure(let error):
                    XCTFail("Error \(error)")
                }
            } receiveValue: { _ in }

            let startCompleted = expectation(description: "start completed")
            plugin.start(completion: {_ in
                XCTAssertNotNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                startCompleted.fulfill()
            })
            wait(for: [startCompleted], timeout: 1.0)

            let stopCompleted = expectation(description: "stop completed")
            plugin.stop(completion: { _ in
                XCTAssertNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                stopCompleted.fulfill()
            })
            wait(for: [stopCompleted], timeout: 1.0)

            storageEngine.responders[.startSync] = StartSyncResponder { _ in
                count = self.expect(startExpectationOnSecondStart, count, 3)
            }

            plugin.start(completion: { _ in
                XCTAssertNotNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
            })
            waitForExpectations(timeout: 1.0)
            sink.cancel()
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
    }

    func testStorageEngineStartClearStart() throws {
        let startExpectation = expectation(description: "Start Sync should be called with start")
        let clearExpectation = expectation(description: "Clear should be called")
        let startExpectationOnSecondStart = expectation(description: "Start Sync should be called again")
        var count = 0
        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.startSync] = StartSyncResponder { _ in
            count = self.expect(startExpectation, count, 1)
        }
        storageEngine.responders[.clear] = ClearResponder { _ in
            count = self.expect(clearExpectation, count, 2)
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")

        let finishNotReceived = expectation(
            description: "publisher should not receive .finished completion event after clear() is called")
        finishNotReceived.isInverted = true

        do {
            try plugin.configure(using: nil)
            XCTAssertNil(plugin.storageEngine)

            let sink = plugin.publisher.sink { completion in
                switch completion {
                case .finished:
                    finishNotReceived.fulfill()
                case .failure(let error):
                    XCTFail("Error \(error)")
                }
            } receiveValue: { _ in }

            let startCompleted = expectation(description: "start completed")
            plugin.start(completion: {_ in
                XCTAssertNotNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                startCompleted.fulfill()
            })
            wait(for: [startCompleted], timeout: 1.0)

            let clearCompleted = expectation(description: "clear completed")
            plugin.clear(completion: { _ in
                XCTAssertNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                clearCompleted.fulfill()
            })
            wait(for: [clearCompleted], timeout: 1.0)

            storageEngine.responders[.startSync] = StartSyncResponder {_ in
                count = self.expect(startExpectationOnSecondStart, count, 3)
            }

            plugin.start(completion: { _ in
                XCTAssertNotNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
            })
            waitForExpectations(timeout: 1.0)
            sink.cancel()
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
    }

    func testStorageEngineQueryClearQuery() throws {
        let startExpectation = expectation(description: "Start Sync should be called with Query")
        let clearExpectation = expectation(description: "Clear should be called")
        let startExpectationOnQuery = expectation(description: "Start Sync should be called again with Query")
        var count = 0
        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.query] = QueryResponder<ExampleWithEveryType> { _ in
            count = self.expect(startExpectation, count, 1)
            return .success([])
        }
        storageEngine.responders[.clear] = ClearResponder { _ in
            count = self.expect(clearExpectation, count, 2)
        }

        let dataStorePublisher = DataStorePublisher()
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")

        let finishNotReceived = expectation(
            description: "publisher should not receive .finished completion event after clear() is called")
        finishNotReceived.isInverted = true

        do {
            try plugin.configure(using: nil)
            XCTAssertNil(plugin.storageEngine)

            let sink = plugin.publisher.sink { completion in
                switch completion {
                case .finished:
                    finishNotReceived.fulfill()
                case .failure(let error):
                    XCTFail("Error \(error)")
                }
            } receiveValue: { _ in }

            let queryCompleted = expectation(description: "query completed")
            plugin.query(ExampleWithEveryType.self, completion: {_ in
                XCTAssertNotNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                queryCompleted.fulfill()
            })
            wait(for: [queryCompleted], timeout: 1.0)

            let clearCompleted = expectation(description: "clear completed")
            plugin.clear(completion: { _ in
                XCTAssertNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                clearCompleted.fulfill()
            })
            wait(for: [clearCompleted], timeout: 1.0)
            storageEngine.responders[.query] = QueryResponder<ExampleWithEveryType> {_ in
                count = self.expect(startExpectationOnQuery, count, 3)
                return .success([])
            }

            plugin.query(ExampleWithEveryType.self, completion: { _ in
                XCTAssertNotNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
            })
            waitForExpectations(timeout: 1.0)
            sink.cancel()
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
    }

    func expect(_ expectation: XCTestExpectation, _ currCount: Int, _ expectedCount: Int) -> Int {
        let count = currCount + 1
        if count == expectedCount {
            expectation.fulfill()
        }
        return count
    }

    /// - Given: Datastore plugin is initialized
    /// - When:
    ///     - plugin.start() is called
    ///     - plugin.clear() is called
    ///     - a mutation event is sent
    /// - Then: The subscriber to plugin's publisher should receive the mutation

    func testStorageEngineStartClearSend() {
        let startExpectation = expectation(description: "Start Sync should be called with start")
        let clearExpectation = expectation(description: "Clear should be called")

        var count = 0
        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.startSync] = StartSyncResponder { _ in
            count = self.expect(startExpectation, count, 1)
        }
        storageEngine.responders[.clear] = ClearResponder { _ in
            count = self.expect(clearExpectation, count, 2)
        }

        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")

        let finishNotReceived = expectation(
            description: "publisher should not receive .finished completion event after clear() is called")
        finishNotReceived.isInverted = true

        let publisherReceivedValue = expectation(
            description: "publisher should receive a value when mutation event is sent")

        do {
            try plugin.configure(using: nil)
            XCTAssertNil(plugin.storageEngine)

            let sink = plugin.publisher.sink { completion in
                switch completion {
                case .finished:
                    finishNotReceived.fulfill()
                case .failure(let error):
                    XCTFail("Error \(error)")
                }
            } receiveValue: { event in
                XCTAssertEqual(event.modelId, "12345")
                publisherReceivedValue.fulfill()
            }

            let startCompleted = expectation(description: "start completed")
            plugin.start(completion: {_ in
                XCTAssertNotNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                startCompleted.fulfill()
            })
            wait(for: [startCompleted], timeout: 1.0)
            
            let clearCompleted = expectation(description: "clear completed")
            plugin.clear(completion: { _ in
                XCTAssertNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                clearCompleted.fulfill()
            })
            wait(for: [clearCompleted], timeout: 1.0)

            let mockModel = MockSynced(id: "12345")
            try plugin.dataStorePublisher?.send(input: MutationEvent(model: mockModel,
                                                                     modelSchema: mockModel.schema,
                                                                     mutationType: .create))

            waitForExpectations(timeout: 1.0)
            sink.cancel()
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
    }

    /// - Given: Datastore plugin is initialized
    /// - When:
    ///     - plugin.start() is called
    ///     - plugin.stop() is called
    ///     - a mutation event is sent
    /// - Then: The subscriber to plugin's publisher should receive the mutation
    func testStorageEngineStartStopSend() {
        let startExpectation = expectation(description: "Start Sync should be called with start")
        let stopExpectation = expectation(description: "Stop should be called")

        var count = 0
        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.startSync] = StartSyncResponder { _ in
            count = self.expect(startExpectation, count, 1)
        }
        storageEngine.responders[.stopSync] = StopSyncResponder { _ in
            count = self.expect(stopExpectation, count, 2)
        }

        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")

        let finishNotReceived = expectation(
            description: "publisher should not receive .finished completion event after stop() is called")
        finishNotReceived.isInverted = true

        let publisherReceivedValue = expectation(
            description: "publisher should receive a value when mutation event is sent")

        do {
            try plugin.configure(using: nil)
            XCTAssertNil(plugin.storageEngine)

            let sink = plugin.publisher.sink { completion in
                switch completion {
                case .finished:
                    finishNotReceived.fulfill()
                case .failure(let error):
                    XCTFail("Error \(error)")
                }
            } receiveValue: { event in
                XCTAssertEqual(event.modelId, "12345")
                publisherReceivedValue.fulfill()
            }

            let startCompleted = expectation(description: "start completed")
            plugin.start(completion: {_ in
                XCTAssertNotNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                startCompleted.fulfill()
            })
            wait(for: [startCompleted], timeout: 1.0)
            
            let stopCompleted = expectation(description: "stop completed")
            plugin.stop(completion: { _ in
                XCTAssertNil(plugin.storageEngine)
                XCTAssertNotNil(plugin.dataStorePublisher)
                stopCompleted.fulfill()
            })
            wait(for: [stopCompleted], timeout: 1.0)

            let mockModel = MockSynced(id: "12345")
            try plugin.dataStorePublisher?.send(input: MutationEvent(model: mockModel,
                                                                     modelSchema: mockModel.schema,
                                                                     mutationType: .create))

            waitForExpectations(timeout: 1.0)
            sink.cancel()
        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
    }

    /// - Given: Datastore plugin is NOT initialized
    /// - When:
    ///     - plugin.clear() is called
    /// - Then: StorageEngine.clear is called
    func testClearStorageWhenEngineIsNotStarted() {
        let storageEngine = MockStorageEngineBehavior()
        let pluginClearExpectation = expectation(description: "DataStore plugin .clear should called")
        let storageClearExpectation = expectation(description: "StorageEngine .clear should be called")
        storageEngine.responders[.clear] = ClearResponder { _ in
            storageClearExpectation.fulfill()
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")

        plugin.clear {
            if case .success = $0 {
                pluginClearExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0)
    }

    func testStopStorageEngineOnTerminalEvent() {
        let storageEngine = MockStorageEngineBehavior()
        let stopExpectation = expectation(description: "stop should be called")
        var count = 0
        storageEngine.responders[.stopSync] = StopSyncResponder { _ in
            count = self.expect(stopExpectation, count, 1)
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")

        let startCompleted = expectation(description: "start completed")
        plugin.start(completion: {_ in
            XCTAssertNotNil(plugin.storageEngine)
            XCTAssertNotNil(plugin.dataStorePublisher)
            startCompleted.fulfill()
        })
        wait(for: [startCompleted], timeout: 1.0)

        storageEngine.mockPublisher.send(completion: .finished)

        waitForExpectations(timeout: 1.0)
    }

    func testStopStorageEngineOnTerminalFailureEvent() {
        let storageEngine = MockStorageEngineBehavior()
        let stopExpectation = expectation(description: "stop should be called")
        var count = 0
        storageEngine.responders[.stopSync] = StopSyncResponder { _ in
            count = self.expect(stopExpectation, count, 1)
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")

        let startCompleted = expectation(description: "start completed")
        plugin.start(completion: {_ in
            XCTAssertNotNil(plugin.storageEngine)
            XCTAssertNotNil(plugin.dataStorePublisher)
            startCompleted.fulfill()
        })
        wait(for: [startCompleted], timeout: 1.0)

        storageEngine.mockPublisher.send(completion: .failure(.internalOperation("", "", nil)))

        waitForExpectations(timeout: 1.0)
    }
}
