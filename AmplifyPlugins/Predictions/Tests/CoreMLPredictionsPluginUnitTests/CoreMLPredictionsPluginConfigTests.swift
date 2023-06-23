//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Speech) && canImport(Vision)
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
            guard case PluginError.pluginConfigurationError = error else {
                XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
                return
            }
        }
    }

}
#endif
