//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSAPIPlugin
import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class DataStoreStressBaseTest: XCTestCase, @unchecked Sendable {

    static let amplifyConfigurationFile = "testconfiguration/AWSAmplifyStressTests-amplifyconfiguration"
    let concurrencyLimit = 50
    let networkTimeout = TimeInterval(180)

    func setUp(withModels models: AmplifyModelRegistration, logLevel: LogLevel = .error) async {

        // With `false`, an async failure runs tearDown alongside the abandoned test body, then exits the process.
        continueAfterFailure = true
        Amplify.Logging.logLevel = logLevel

        do {
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfigurationFile)
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models, configuration: .custom(syncMaxRecords: 100)))
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models, sessionFactory: AmplifyURLSessionFactory()))
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() async throws {
        // Let in-flight sync work unwind before `Amplify.reset()`, as SyncEngineIntegrationTestBase does.
        var teardownError: Error?
        do {
            try await stopDataStore()
            try await clearDataStore()
        } catch {
            teardownError = error
        }
        try? await Task.sleep(seconds: 1)
        // Reset even if stop or clear threw, so the next test can configure Amplify.
        await Amplify.reset()
        if let teardownError {
            throw teardownError
        }
    }

    func stopDataStore() async throws {
        try await Amplify.DataStore.stop()
    }

    func clearDataStore() async throws {
        try await Amplify.DataStore.clear()
    }

    func startDataStoreAndWaitForSync() async throws {
        try await startDataStoreAndWait(for: HubPayload.EventName.DataStore.syncStarted)
    }

    func startDataStoreAndWaitForReady() async throws {
        try await startDataStoreAndWait(for: HubPayload.EventName.DataStore.ready)
    }

    private func startDataStoreAndWait(for eventName: String) async throws {
        let eventReceived = expectation(description: "DataStore \(eventName) event")

        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(
            to: .dataStore,
            eventName: eventName
        ) { _ in
            eventReceived.fulfill()
            Amplify.Hub.removeListener(token)
        }

        guard try await HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        try await Amplify.DataStore.start()

        await fulfillment(of: [eventReceived], timeout: networkTimeout)
    }
}
