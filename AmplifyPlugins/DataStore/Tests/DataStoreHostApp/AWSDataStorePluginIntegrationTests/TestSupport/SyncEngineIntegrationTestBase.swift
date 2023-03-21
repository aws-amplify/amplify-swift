//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPIPlugin

@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

class SyncEngineIntegrationTestBase: DataStoreTestBase {

    static let amplifyConfigurationFile = "testconfiguration/AWSDataStoreCategoryPluginIntegrationTests-amplifyconfiguration"

    static let networkTimeout = TimeInterval(180)
    let networkTimeout = SyncEngineIntegrationTestBase.networkTimeout

    // Convenience property to obtain a handle to the underlying storage adapter implementation, for use in asserting
    // database behaviors. Full of force-unwrapped badness.
    // swiftlint:disable force_try
    // swiftlint:disable force_cast
    var storageAdapter: SQLiteStorageEngineAdapter {
        let plugin = try! Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let storageEngine = plugin.storageEngine as! StorageEngine
        let storageAdapter = storageEngine.storageAdapter as! SQLiteStorageEngineAdapter
        return storageAdapter
    }
    // swiftlint:enable force_try
    // swiftlint:enable force_cast

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        try await super.tearDown()
        try await stopDataStore()
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    func setUp(
        withModels models: AmplifyModelRegistration,
        logLevel: LogLevel = .error,
        dataStoreConfiguration: DataStoreConfiguration? = nil
    ) async {
        Amplify.Logging.logLevel = logLevel

        do {
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
            try Amplify.add(
                plugin: AWSDataStorePlugin(
                    modelRegistration: models,
                    configuration: dataStoreConfiguration ?? .custom(syncMaxRecords: 100)
                )
            )
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }
    
    func stopDataStore() async throws {
        try await Amplify.DataStore.stop()
    }
    
    func clearDataStore() async throws {
        try await Amplify.DataStore.clear()
    }

    func getTestConfiguration() throws -> AmplifyConfiguration {
        try TestConfigHelper.retrieveAmplifyConfiguration(
            forResource: Self.amplifyConfigurationFile)
    }

    func startAmplify() throws {
        let amplifyConfig = try getTestConfiguration()
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func startAmplifyAndWaitForSync() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.syncStarted)
    }

    func startAmplifyAndWaitForReady() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.ready)
    }

    private func startAmplifyAndWait(for eventName: String) async throws {
        try startAmplify()

        let eventReceived = expectation(description: "DataStore \(eventName) event")
        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(to: .dataStore,
                                   eventName: eventName) { _ in
            eventReceived.fulfill()
            Amplify.Hub.removeListener(token)
        }

        guard try await HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        try await Amplify.DataStore.start()
        await waitForExpectations(timeout: 10.0)

        try await deleteMutationEvents()
    }
    
    func deleteMutationEvents() async throws {
        try await Amplify.DataStore.delete(MutationEvent.self, where: QueryPredicateConstant.all)
    }

    private func extractMutationEvent(event: DataStoreHubEvent) -> MutationEvent? {
        if case .syncReceived(let mutationEvent) = event {
            return mutationEvent
        }
        return nil
    }

    func createModelUntilSynced<T: Model>(data: T) async throws -> T {
        let expection = AsyncExpectation(description: "Wait for creating [\(data.modelName): \(data.identifier)]")
        let cancellable = Amplify.Hub.publisher(for: .dataStore)
            .map { DataStoreHubEvent(payload: $0) }
            .compactMap(extractMutationEvent(event:))
            .filter { $0.modelName == T.modelName }
            .filter { $0.mutationType == MutationEvent.MutationType.create.rawValue }
            .compactMap { try? $0.decodeModel() as? T }
            .filter { $0.identifier == data.identifier }
            .sink { _ in
                Task { await expection.fulfill() }
            }
        defer { cancellable.cancel() }

        let model = try await Amplify.DataStore.save(data)
        await waitForExpectations([expection], timeout: 10)
        return model
    }

    @discardableResult
    func updateModelWaitForSync<T: Model & Equatable>(data: T) async throws -> T {
        try await updateModelWaitForSync(data: data, isEqual: { $0 == $1 })
    }

    @discardableResult
    func updateModelWaitForSync<T: Model>(data: T, isEqual: @escaping (T, T) -> Bool) async throws -> T {
        let expection = AsyncExpectation(description: "Wait for updating [\(data.modelName): \(data.identifier)]")
        let cancellable = Amplify.Hub.publisher(for: .dataStore)
            .map { DataStoreHubEvent(payload: $0) }
            .compactMap(extractMutationEvent(event:))
            .filter { $0.modelName == T.modelName }
            .filter { $0.mutationType == MutationEvent.MutationType.update.rawValue }
            .compactMap { try? $0.decodeModel() as? T }
            .filter { isEqual($0, data) }
            .sink { _ in
                Task { await expection.fulfill() }
            }
        defer { cancellable.cancel() }

        let model = try await Amplify.DataStore.save(data)
        await waitForExpectations([expection], timeout: 10)
        return model
    }


    func deleteModelWaitForSync<T: Model>(data: T, predicate: QueryPredicate? = nil) async throws {
        let expection = AsyncExpectation(description: "Wait for deleting [\(data.modelName): \(data.identifier)]")
        let cancellable = Amplify.Hub.publisher(for: .dataStore)
            .map { DataStoreHubEvent(payload: $0) }
            .compactMap(extractMutationEvent(event:))
            .filter { $0.modelName == T.modelName }
            .filter { $0.mutationType == MutationEvent.MutationType.delete.rawValue }
            .compactMap { try? $0.decodeModel() as? T }
            .filter { $0.identifier == data.identifier }
            .sink { _ in
                Task { await expection.fulfill() }
            }
        defer { cancellable.cancel() }

        try await Amplify.DataStore.delete(data, where: predicate)
        await waitForExpectations([expection], timeout: 10)
    }
}
