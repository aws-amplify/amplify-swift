//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp
import AWSAPIPlugin

class SyncEngineIntegrationV2TestBase: DataStoreTestBase {

    static let amplifyConfigurationFile = "testconfiguration/AWSDataStoreCategoryPluginIntegrationV2Tests-amplifyconfiguration"

    static let networkTimeout = TimeInterval(180)
    let networkTimeout = SyncEngineIntegrationV2TestBase.networkTimeout

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

    func setUp(withModels models: AmplifyModelRegistration, logLevel: LogLevel = .error) async {

        continueAfterFailure = false

        Amplify.Logging.logLevel = logLevel

        do {
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models,
                                                       configuration: .custom(syncMaxRecords: 100)))
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() async throws {
        try await super.tearDown()
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    func stopDataStore() async throws {
        try await Amplify.DataStore.stop()
    }

    func clearDataStore() async throws {
        try await Amplify.DataStore.clear()
    }

    func startAmplify(_ completion: BasicClosure? = nil) throws {
        let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfigurationFile)

        DispatchQueue.global().async {
            do {
                try Amplify.configure(amplifyConfig)
                completion?()
            } catch {
                XCTFail(String(describing: error))
            }
        }
    }

    func startAmplifyAndWaitForSync() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.syncStarted)
    }

    func startAmplifyAndWaitForReady() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.ready)
    }

    private func startAmplifyAndWait(for eventName: String) async throws {
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

        let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfigurationFile)
        try Amplify.configure(amplifyConfig)
        try await Amplify.DataStore.start()
        await waitForExpectations(timeout: 100.0)
    }

    private func extractMutationEvent(event: DataStoreHubEvent) -> MutationEvent? {
        if case .syncReceived(let mutationEvent) = event {
            return mutationEvent
        }
        return nil
    }

    @discardableResult
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
    func updateModelWaitFroSync<T: Model & Equatable>(data: T) async throws -> T {
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
