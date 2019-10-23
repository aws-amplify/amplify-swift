//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class AWSAPICategoryPluginTestBase: XCTestCase {

    override func setUp() {
        Amplify.reset()
        
        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
              "Prod": [
                "Endpoint": "https://example.apiforintegrationtests.com",
                "Region": "us-east-1"
              ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        let apiPlugin = AWSAPICategoryPlugin()

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

}
