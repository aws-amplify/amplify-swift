//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPredictionsPlugin
import AWSCore

@testable import Amplify
@testable import AmplifyTestCommon

class AWSPredictionsPluginTestBase: XCTestCase {

    let networkTimeout = TimeInterval(20) // 20 seconds to wait before network timeouts
    let amplifyConfigurationFile = "testconfiguration/AWSPredictionsPluginIntegrationTests-amplifyconfiguration"

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        do {
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: amplifyConfigurationFile)
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPredictionsPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() {
        sleep(1)
        print("Amplify reset")
        await Amplify.reset()
    }
}
