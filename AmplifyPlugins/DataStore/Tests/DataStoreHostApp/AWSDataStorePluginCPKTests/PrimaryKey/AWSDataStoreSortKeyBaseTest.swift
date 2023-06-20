//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Combine
import XCTest

import AWSAPIPlugin
import AWSDataStorePlugin

@testable import Amplify
@testable import DataStoreHostApp

class AWSDataStoreSortKeyBaseTest: XCTestCase {
    static let defaultConfigFile = "AWSDataStoreCategoryPluginPrimaryKeyIntegrationTests-amplifyconfiguration"
    override func setUp() async throws {
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        try await Amplify.DataStore.clear()
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    func setUp(
        models: AmplifyModelRegistration,
        configFile: String = AWSDataStoreSortKeyBaseTest.defaultConfigFile
    ) async throws {
        let config = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: "testconfiguration/\(configFile)")
        try Amplify.add(plugin: AWSAPIPlugin(sessionFactory: AmplifyURLSessionFactory()))
        try Amplify.add(plugin: AWSDataStorePlugin(
            modelRegistration: models,
            configuration: .custom(syncMaxRecords: 100)
        ))

        Amplify.Logging.logLevel = .verbose
        try Amplify.configure(config)
    }

    func waitDataStoreReady() async throws {
        let ready = expectation(description: "DataStore is ready")
        var requests: Set<AnyCancellable> = []
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.ready }
            .sink { _ in
                ready.fulfill()
            }
            .store(in: &requests)

        try await Amplify.DataStore.start()
        await fulfillment(of: [ready], timeout: 60)
    }

}
