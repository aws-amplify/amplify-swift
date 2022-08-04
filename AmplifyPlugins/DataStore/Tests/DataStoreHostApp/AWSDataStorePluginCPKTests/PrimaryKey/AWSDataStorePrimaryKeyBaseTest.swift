//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine
import AWSDataStorePlugin
import AWSAPIPlugin

@testable import Amplify

class AWSDataStorePrimaryKeyBaseTest: XCTestCase {
    var requests: Set<AnyCancellable> = []

    var amplifyConfig: AmplifyConfiguration!

    override func setUp() {
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        clearDataStore()
        requests = []
        await Amplify.reset()
    }

    // MARK: - Test Helpers
    func makeExpectations() -> TestExpectations {
        TestExpectations(
            subscriptionsEstablished: expectation(description: "Subscriptions established"),
            modelsSynced: expectation(description: "Models synced"),

            query: expectation(description: "Query success"),

            mutationSave: expectation(description: "Mutation save success"),
            mutationSaveProcessed: expectation(description: "Mutation save processed"),

            mutationDelete: expectation(description: "Mutation delete success"),
            mutationDeleteProcessed: expectation(description: "Mutation delete processed"),

            ready: expectation(description: "Ready")
        )
    }

    /// Setup DataStore with given models
    /// - Parameter models: DataStore models
    func setup(withModels models: AmplifyModelRegistration) {
        do {
            loadAmplifyConfig()
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))

            try Amplify.add(plugin: AWSAPIPlugin())

            Amplify.Logging.logLevel = .verbose

            try Amplify.configure(amplifyConfig)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    func loadAmplifyConfig() {
        let baseFileName = "AWSDataStoreCategoryPluginPrimaryKeyIntegrationTests"
        let basePath = "testconfiguration"
        let configFile = "\(basePath)/\(baseFileName)-amplifyconfiguration"
        do {
            amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: configFile)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    func clearDataStore() {
        let semaphore = DispatchSemaphore(value: 0)
        Amplify.DataStore.clear {
            if case let .failure(error) = $0 {
                XCTFail("DataStore clear failed \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
}

// MARK: - DataStore behavior assert helpers
extension AWSDataStorePrimaryKeyBaseTest {
    /// Asserts that query with given `Model` succeeds
    /// - Parameters:
    ///   - modelType: model type
    ///   - expectation: success XCTestExpectation
    ///   - onFailure: on failure callback
    func assertQuerySuccess<M: Model>(modelType: M.Type,
                                      _ expectations: TestExpectations,
                                      onFailure: @escaping (_ error: DataStoreError) -> Void) {
        Amplify.DataStore.query(modelType).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { models in
            XCTAssertNotNil(models)
            expectations.query.fulfill()
        }.store(in: &requests)
        wait(for: [expectations.query],
             timeout: 60)
    }

    /// Asserts that query with given `Model` succeeds
    /// - Parameters:
    ///   - modelType: model type
    ///   - expectation: success XCTestExpectation
    ///   - onFailure: on failure callback
    func assertModelDeleted<M: Model & ModelIdentifiable>(modelType: M.Type,
                                                          identifier: ModelIdentifier<M, M.IdentifierFormat>,
                                                          onFailure: @escaping (_ error: DataStoreError) -> Void) {
        let expectation = expectation(description: "Model deleted")
        Amplify.DataStore.query(modelType, byIdentifier: identifier).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { model in
            XCTAssertNil(model)
            expectation.fulfill()
        }.store(in: &requests)
        wait(for: [expectation],
             timeout: 60)
    }

    /// Asserts that DataStore is in a ready state and subscriptions are established
    /// - Parameter events: DataStore Hub events
    func assertDataStoreReady(_ expectations: TestExpectations,
                              expectedModelSynced: Int = 1) {
        var modelSyncedCount = 0
        let dataStoreEvents = HubPayload.EventName.DataStore.self
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .sink { event in
                // subscription fulfilled
                if event.eventName == dataStoreEvents.subscriptionsEstablished {
                    expectations.subscriptionsEstablished.fulfill()
                }

                // modelsSynced fulfilled
                if event.eventName == dataStoreEvents.modelSynced {
                    modelSyncedCount += 1
                    if modelSyncedCount == expectedModelSynced {
                        expectations.modelsSynced.fulfill()
                    }
                }

                if event.eventName == dataStoreEvents.ready {
                    expectations.ready.fulfill()
                }
            }
            .store(in: &requests)

        Amplify.DataStore.start { _ in }

        wait(for: [expectations.subscriptionsEstablished,
                   expectations.modelsSynced,
                   expectations.ready],
             timeout: 60)

    }

    /// Assert that a save and a delete mutation complete successfully.
    /// - Parameters:
    ///   - model: model instance saved and then deleted
    ///   - expectations: test expectations
    ///   - onFailure: failure callback
    func assertMutations<M: Model & ModelIdentifiable>(model: M,
                                                       _ expectations: TestExpectations,
                                                       onFailure: @escaping (_ error: DataStoreError) -> Void) {
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == model.identifier else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    expectations.mutationSaveProcessed.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    expectations.mutationDeleteProcessed.fulfill()
                    return
                }
            }
            .store(in: &requests)

        Amplify.DataStore.save(model).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectations.mutationSave.fulfill()
        }.store(in: &requests)

        wait(for: [expectations.mutationSave, expectations.mutationSaveProcessed], timeout: 60)

        Amplify.DataStore.delete(model).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectations.mutationDelete.fulfill()
        }.store(in: &requests)

        wait(for: [expectations.mutationDelete, expectations.mutationDeleteProcessed], timeout: 60)
    }

    /// Assert that a save and a delete mutation complete successfully.
    /// - Parameters:
    ///   - model: model instance saved and then deleted
    ///   - expectations: test expectations
    ///   - onFailure: failure callback
    func assertMutationsParentChild<P: Model & ModelIdentifiable,
                                    C: Model & ModelIdentifiable>(parent: P,
                                                                  child: C,
                                                                  _ expectations: TestExpectations,
                                                                  onFailure: @escaping (_ error: DataStoreError) -> Void) {
        expectations.mutationSave.expectedFulfillmentCount = 2
        expectations.mutationSaveProcessed.expectedFulfillmentCount = 2

        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == parent.identifier || mutationEvent.modelId == child.identifier else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    expectations.mutationSaveProcessed.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    expectations.mutationDeleteProcessed.fulfill()
                    return
                }
            }
            .store(in: &requests)

        // save parent first
        Amplify.DataStore.save(parent).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectations.mutationSave.fulfill()
        }.store(in: &requests)

        // save child
        Amplify.DataStore.save(child).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectations.mutationSave.fulfill()
        }.store(in: &requests)

        wait(for: [expectations.mutationSave, expectations.mutationSaveProcessed], timeout: 60)

        // delete parent
        Amplify.DataStore.delete(parent).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectations.mutationDelete.fulfill()
        }.store(in: &requests)

        wait(for: [expectations.mutationDelete, expectations.mutationDeleteProcessed], timeout: 60)
    }
}

// MARK: - Expectations
extension AWSDataStorePrimaryKeyBaseTest {
    struct TestExpectations {
        var subscriptionsEstablished: XCTestExpectation
        var modelsSynced: XCTestExpectation
        var query: XCTestExpectation
        var mutationSave: XCTestExpectation
        var mutationSaveProcessed: XCTestExpectation
        var mutationDelete: XCTestExpectation
        var mutationDeleteProcessed: XCTestExpectation
        var ready: XCTestExpectation
        var expectations: [XCTestExpectation] {
            return [subscriptionsEstablished,
                    modelsSynced,
                    query,
                    mutationSave,
                    mutationSaveProcessed
            ]
        }
    }
}
