//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSAPIPlugin
import AWSDataStorePlugin
import Combine
import Foundation
import XCTest
#if !os(watchOS)
@testable import DataStoreHostApp
#endif

@testable import Amplify

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSDataStorePrimaryKeyBaseTest: XCTestCase, @unchecked Sendable {
    var requests: Set<AnyCancellable> = []

    var amplifyConfig: AmplifyConfiguration!

    override func setUp() {
        // With `false`, an async failure runs tearDown alongside the abandoned test body, then exits the process.
        continueAfterFailure = true
    }

    override func tearDown() async throws {
        // Stop and let in-flight sync unwind before reset clears the ModelRegistry; otherwise a
        // late outgoing mutation crashes with "Could not retrieve schema for the model ...".
        var teardownError: Error?
        do {
            try await Amplify.DataStore.stop()
            try await Amplify.DataStore.clear()
        } catch {
            teardownError = error
        }
        requests = []
        try? await Task.sleep(seconds: 1)
        // Reset even if stop or clear threw, so the next test can configure Amplify.
        await Amplify.reset()
        if let teardownError {
            throw teardownError
        }
    }

    /// Setup DataStore with given models
    /// - Parameter models: DataStore models
    func setup(withModels models: AmplifyModelRegistration) {
        do {
            loadAmplifyConfig()
            #if os(watchOS)
            try Amplify.add(plugin: AWSDataStorePlugin(
                modelRegistration: models,
                configuration: .custom(syncMaxRecords: 100, disableSubscriptions: { false })
            ))
            #else
            try Amplify.add(plugin: AWSDataStorePlugin(
                modelRegistration: models,
                configuration: .custom(syncMaxRecords: 100)
            ))
            #endif

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
    func assertQuerySuccess(modelType: (some Model).Type) async throws {
        let models = try await Amplify.DataStore.query(modelType)
        XCTAssertNotNil(models)
    }

    /// Asserts that query with given `Model` succeeds
    /// - Parameters:
    ///   - modelType: model type
    ///   - expectation: success XCTestExpectation
    ///   - onFailure: on failure callback
    func assertModelDeleted<M: Model & ModelIdentifiable>(
        modelType: M.Type,
        identifier: ModelIdentifier<M, M.IdentifierFormat>
    ) async throws {
        let model = try await Amplify.DataStore.query(modelType, byIdentifier: identifier)
        XCTAssertNil(model)
    }

    /// Asserts that DataStore is in a ready state and subscriptions are established
    /// - Parameter events: DataStore Hub events
    func assertDataStoreReady(expectedModelSynced: Int = 1) async throws {
        // The sink lives until tearDown, and a sync-engine restart sends both events again.
        let ready = expectation(description: "Ready")
        ready.assertForOverFulfill = false
        let subscriptionsEstablished = expectation(description: "Subscriptions established")
        subscriptionsEstablished.assertForOverFulfill = false
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
        await fulfillment(
            of: [
                ready,
                subscriptionsEstablished,
                modelsSynced
            ],
            timeout: 60
        )
    }

    /// Assert that a save and a delete mutation complete successfully.
    /// - Parameters:
    ///   - model: model instance saved and then deleted
    ///   - expectations: test expectations
    ///   - onFailure: failure callback
    func assertMutations(model: some Model & ModelIdentifiable) async throws {

        let mutationSaveProcessed = expectation(description: "mutation save processed")
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == model.identifier
                else {
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
        await fulfillment(
            of: [mutationSaveProcessed],
            timeout: 60
        )

        let mutationDeleteProcessed = expectation(description: "mutation delete processed")
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == model.identifier
                else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    mutationDeleteProcessed.fulfill()
                    return
                }
            }
            .store(in: &requests)

        try await Amplify.DataStore.delete(model)
        await fulfillment(
            of: [mutationDeleteProcessed],
            timeout: 60
        )
    }

    /// Assert that a save and a delete mutation complete successfully.
    /// - Parameters:
    ///   - model: model instance saved and then deleted
    ///   - expectations: test expectations
    ///   - onFailure: failure callback
    func assertMutationsParentChild(
        parent: some Model & ModelIdentifiable,
        child: some Model & ModelIdentifiable,
        shouldDeleteParent: Bool = true
    ) async throws {
        let mutationSaveProcessed = expectation(description: "mutation saved processed")
        mutationSaveProcessed.expectedFulfillmentCount = 2

        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == parent.identifier || mutationEvent.modelId == child.identifier
                else {
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

        await fulfillment(of: [mutationSaveProcessed], timeout: 60)

        guard shouldDeleteParent else {
            return
        }

        try await assertDeleteMutation(parent: parent, child: child)
    }

    func assertDeleteMutation(parent: some Model & ModelIdentifiable, child: some Model & ModelIdentifiable) async throws {
        // Deleting the parent cascades to the child, so both deletes sync and match this sink.
        let mutationDeleteProcessed = expectation(description: "mutation delete processed")
        mutationDeleteProcessed.assertForOverFulfill = false
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == parent.identifier || mutationEvent.modelId == child.identifier
                else {
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
        await fulfillment(of: [mutationDeleteProcessed], timeout: 60)
    }
}
