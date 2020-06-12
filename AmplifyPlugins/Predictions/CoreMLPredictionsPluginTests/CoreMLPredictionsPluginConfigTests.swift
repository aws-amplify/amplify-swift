//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import CoreMLPredictionsPlugin

class CoreMLPredictionsPluginConfigTests: XCTestCase {

    func testThrowsOnMissingConfig() throws {
        let plugin = CoreMLPredictionsPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = PredictionsCategoryConfiguration(plugins: ["NonExistentPlugin": true])
        let amplifyConfig = AmplifyConfiguration(predictions: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
            XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
        } catch {
            if case PluginError.pluginConfigurationError = error {
                // Pass
            } else {
                XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
            }
        }
    }

}
