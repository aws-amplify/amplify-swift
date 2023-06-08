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
@testable import DataStoreHostApp

@testable import Amplify

class AWSDataStorePrimaryKeyBaseTest: XCTestCase {
    var requests: Set<AnyCancellable> = []

    var amplifyConfig: AmplifyConfiguration!

    override func setUp() {
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        try await Amplify.DataStore.clear()
        requests = []
        await Amplify.reset()
    }

    /// Setup DataStore with given models
    /// - Parameter models: DataStore models
    func setup(withModels models: AmplifyModelRegistration) {
        do {
            loadAmplifyConfig()
            try Amplify.add(plugin: AWSDataStorePlugin(
                modelRegistration: models,
                configuration: .custom(syncMaxRecords: 100)
            ))

            try Amplify.add(plugin: AWSAPIPlugin(sessionFactory: AmplifyURLSessionFactory()))

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
}

// MARK: - DataStore behavior assert helpers
extension AWSDataStorePrimaryKeyBaseTest {
    /// Asserts that query with given `Model` succeeds
    /// - Parameters:
    ///   - modelType: model type
    ///   - expectation: success XCTestExpectation
    ///   - onFailure: on failure callback
    func assertQuerySuccess<M: Model>(modelType: M.Type) async throws {
        let models = try await Amplify.DataStore.query(modelType)
        XCTAssertNotNil(models)
    }

    /// Asserts that query with given `Model` succeeds
    /// - Parameters:
    ///   - modelType: model type
    ///   - expectation: success XCTestExpectation
    ///   - onFailure: on failure callback
    func assertModelDeleted<M: Model & ModelIdentifiable>(modelType: M.Type,
                                                          identifier: ModelIdentifier<M, M.IdentifierFormat>) async throws {
        let model = try await Amplify.DataStore.query(modelType, byIdentifier: identifier)
        XCTAssertNil(model)
    }

    /// Asserts that DataStore is in a ready state and subscriptions are established
    /// - Parameter events: DataStore Hub events
    func assertDataStoreReady(expectedModelSynced: Int = 1) async throws {
        let ready = expectation(description: "Ready")
        let subscriptionsEstablished = expectation(description: "Subscriptions established")
        let modelsSynced = expectation(description: "Models synced")
        
        var modelSyncedCount = 0
        let dataStoreEvents = HubPayload.EventName.DataStore.self
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .sink { event in
                // subscription fulfilled
                if event.eventName == dataStoreEvents.subscriptionsEstablished {
                    subscriptionsEstablished.fulfill()
                }

                // modelsSynced fulfilled
                if event.eventName == dataStoreEvents.modelSynced {
                    modelSyncedCount += 1
                    if modelSyncedCount == expectedModelSynced {
                        modelsSynced.fulfill()
                    }
                }

                if event.eventName == dataStoreEvents.ready {
                    ready.fulfill()
                }
            }
            .store(in: &requests)

        try await Amplify.DataStore.start()

        await waitForExpectations(timeout: 60)
    }

    /// Assert that a save and a delete mutation complete successfully.
    /// - Parameters:
    ///   - model: model instance saved and then deleted
    ///   - expectations: test expectations
    ///   - onFailure: failure callback
    func assertMutations<M: Model & ModelIdentifiable>(model: M) async throws {
        
        let mutationSaveProcessed = expectation(description: "mutation save processed")
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
                    mutationSaveProcessed.fulfill()
                    return
                }
            }
            .store(in: &requests)

        let savedModels = try await Amplify.DataStore.save(model)
        XCTAssertNotNil(savedModels)
        await waitForExpectations(timeout: 60)
        
        let mutationDeleteProcessed = expectation(description: "mutation delete processed")
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == model.identifier else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    mutationDeleteProcessed.fulfill()
                    return
                }
            }
            .store(in: &requests)
        
        try await Amplify.DataStore.delete(model)
        await waitForExpectations(timeout: 60)
    }

    /// Assert that a save and a delete mutation complete successfully.
    /// - Parameters:
    ///   - model: model instance saved and then deleted
    ///   - expectations: test expectations
    ///   - onFailure: failure callback
    func assertMutationsParentChild<P: Model & ModelIdentifiable,
                                    C: Model & ModelIdentifiable>(parent: P,
                                                                  child: C,
                                                                  shouldDeleteParent: Bool = true) async throws {
        let mutationSaveProcessed = expectation(description: "mutation saved processed")
        mutationSaveProcessed.expectedFulfillmentCount = 2
        
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
                    mutationSaveProcessed.fulfill()
                    return
                }
            }
            .store(in: &requests)

        // save parent first
        _ = try await Amplify.DataStore.save(parent)
        
        // save child
        _ = try await Amplify.DataStore.save(child)

        await waitForExpectations(timeout: 60)
        
        guard shouldDeleteParent else {
            return
        }
        
        try await assertDeleteMutation(parent: parent, child: child)
    }
    
    func assertDeleteMutation<P: Model & ModelIdentifiable,
                              C: Model & ModelIdentifiable>(parent: P, child: C) async throws {
        let mutationDeleteProcessed = expectation(description: "mutation delete processed")
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == parent.identifier || mutationEvent.modelId == child.identifier else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    mutationDeleteProcessed.fulfill()
                    return
                }
            }
            .store(in: &requests)
        
        // delete parent
        try await Amplify.DataStore.delete(parent)
        await waitForExpectations(timeout: 60)
    }
}
