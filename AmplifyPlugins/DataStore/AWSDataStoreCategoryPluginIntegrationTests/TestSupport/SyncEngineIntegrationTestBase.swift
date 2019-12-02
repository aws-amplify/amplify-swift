//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class SyncEngineIntegrationTestBase: XCTestCase {
    static let networkTimeout = TimeInterval(180)
    let networkTimeout = SyncEngineIntegrationTestBase.networkTimeout

    var amplifyConfig: AmplifyConfiguration!

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        Amplify.reset()
        Amplify.Logging.logLevel = .verbose

        // TODO: Move this to an integ test config file
        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                "Default": [
                    "endpoint": "https://ldm7yqjfjngrjckbziumz5fxbe.appsync-api.us-west-2.amazonaws.com/graphql",
                    "region": "us-west-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-7jhi34lssbbmjclftlykznhw5m",
                    "endpointType": "GraphQL"
                ]
            ]
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStoreCategoryPlugin": true
        ])

        amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        do {
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSDataStoreCategoryPlugin(modelRegistration: TestModelRegistration()))
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func startAmplifyAndWaitForSync() throws {
        let syncStarted = expectation(description: "Sync started")

        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(to: .dataStore,
                                   eventName: HubPayload.EventName.DataStore.syncStarted) { _ in
                                    syncStarted.fulfill()
                                    Amplify.Hub.removeListener(token)

        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        try Amplify.configure(amplifyConfig)

        wait(for: [syncStarted], timeout: 5.0)

        // TODO: remove this once we get sync startup properly operationalized
        Thread.sleep(forTimeInterval: 5.0)
    }

}
