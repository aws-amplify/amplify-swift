//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

class AWSAPICategoryPluginTests: XCTestCase {
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

    func testStorageEngineStartsOnQuery() throws {
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
            plugin.query(ExampleWithEveryType.self)
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
        do {
            try plugin.configure(using: nil)
            XCTAssert(plugin.storageEngine == nil)

            let semaphore = DispatchSemaphore(value: 0)
            plugin.start(completion: {_ in
                XCTAssert(plugin.storageEngine != nil)
                XCTAssert(plugin.dataStorePublisher != nil)
                semaphore.signal()
            })
            semaphore.wait()

            plugin.stop(completion: { _ in
                XCTAssert(plugin.storageEngine == nil)
                XCTAssert(plugin.dataStorePublisher == nil)
                semaphore.signal()
            })
            semaphore.wait()

            storageEngine.responders[.startSync] = StartSyncResponder { _ in
                count = self.expect(startExpectationOnSecondStart, count, 3)
            }

            plugin.start(completion: { _ in
                XCTAssert(plugin.storageEngine != nil)
                XCTAssert(plugin.dataStorePublisher != nil)
            })

        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
        waitForExpectations(timeout: 1.0)
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
        do {
            try plugin.configure(using: nil)
            XCTAssert(plugin.storageEngine == nil)

            let semaphore = DispatchSemaphore(value: 0)
            plugin.start(completion: {_ in
                XCTAssert(plugin.storageEngine != nil)
                XCTAssert(plugin.dataStorePublisher != nil)
                semaphore.signal()
            })
            semaphore.wait()

            plugin.clear(completion: { _ in
                XCTAssert(plugin.storageEngine == nil)
                XCTAssert(plugin.dataStorePublisher == nil)
                semaphore.signal()
            })
            semaphore.wait()
            storageEngine.responders[.startSync] = StartSyncResponder {_ in
                count = self.expect(startExpectationOnSecondStart, count, 3)
            }

            plugin.start(completion: { _ in
                XCTAssert(plugin.storageEngine != nil)
                XCTAssert(plugin.dataStorePublisher != nil)
            })

        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
        waitForExpectations(timeout: 1.0)
    }

    func testStorageEngineQueryClearQuery() throws {
        let startExpectation = expectation(description: "Start Sync should be called with Query")
        let clearExpectation = expectation(description: "Clear should be called")
        let startExpectationOnQuery = expectation(description: "Start Sync should be called again with Query")
        var count = 0
        let storageEngine = MockStorageEngineBehavior()
        storageEngine.responders[.query] = QueryResponder { _ in
            count = self.expect(startExpectation, count, 1)
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
        do {
            try plugin.configure(using: nil)
            XCTAssert(plugin.storageEngine == nil)

            let semaphore = DispatchSemaphore(value: 0)
            plugin.query(ExampleWithEveryType.self, completion: {_ in
                XCTAssert(plugin.storageEngine != nil)
                XCTAssert(plugin.dataStorePublisher != nil)
                semaphore.signal()
            })
            semaphore.wait()

            plugin.clear(completion: { _ in
                XCTAssert(plugin.storageEngine == nil)
                XCTAssert(plugin.dataStorePublisher == nil)
                semaphore.signal()
            })
            semaphore.wait()
            storageEngine.responders[.query] = QueryResponder {_ in
                count = self.expect(startExpectationOnQuery, count, 3)
            }

            plugin.query(ExampleWithEveryType.self, completion: { _ in
                XCTAssert(plugin.storageEngine != nil)
                XCTAssert(plugin.dataStorePublisher != nil)
            })

        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
        waitForExpectations(timeout: 1.0)
    }

    func expect(_ expectation: XCTestExpectation, _ currCount: Int, _ expectedCount: Int) -> Int {
        let count = currCount + 1
        if count == expectedCount {
            expectation.fulfill()
        }
        return count
    }
}
