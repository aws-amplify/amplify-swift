//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore
import Combine
import AWSAPIPlugin

@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

class DataStoreStressBaseTest: XCTestCase {
 
    static let amplifyConfigurationFile = "testconfiguration/AWSDataStoreStressTests-amplifyconfiguration"
    let concurrencyLimit = 1
    let networkTimeout = TimeInterval(180)
    
    func setUp(withModels models: AmplifyModelRegistration, logLevel: LogLevel = .error) async {
        continueAfterFailure = false
        await Amplify.reset()
        Amplify.Logging.logLevel = logLevel
        
        do {
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfigurationFile)
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
            try Amplify.configure(amplifyConfig)
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

    func startDataStoreAndWaitForSync() async throws {
        try await startDataStoreAndWait(for: HubPayload.EventName.DataStore.syncStarted)
    }

    func startDataStoreAndWaitForReady() async throws {
        try await startDataStoreAndWait(for: HubPayload.EventName.DataStore.ready)
    }

    private func startDataStoreAndWait(for eventName: String) async throws {
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

        await waitForExpectations(timeout: 100.0)
    }
}
