//
// Copyright 2018-2020 Amazon.com,
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

class HubEventsIntegrationTestBase: XCTestCase {

    static let networkTimeout = TimeInterval(180)
    let networkTimeout = HubEventsIntegrationTestBase.networkTimeout

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        let bundle = Bundle(for: type(of: self))
        guard let configFile = bundle.url(forResource: "amplifyconfiguration", withExtension: "json") else {
            XCTFail("Could not get URL for amplifyconfiguration.json from \(bundle)")
            return
        }

        do {
            let configData = try Data(contentsOf: configFile)
            let amplifyConfig = try JSONDecoder().decode(AmplifyConfiguration.self, from: configData)
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: TestModelRegistration()))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: TestModelRegistration()))
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() {
        sleep(1)
        print("Amplify reset")
        Amplify.reset()
    }
}
