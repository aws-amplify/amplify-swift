//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import CoreMLPredictionsPlugin

class AWSPredictionsPluginTestBase: XCTestCase {

    let region: JSONValue = "us-east-1"
    // 180 seconds to wait before network timeouts
    let networkTimeout = TimeInterval(180)

    override func setUp() {
        setupAmplify()
    }

    override func tearDown() async throws {
        print("Amplify reset")
        await Amplify.reset()
//        sleep(5)
    }

    private func setupAmplify() {
        // Set up Amplify predictions configuration
        let predictionsConfig = PredictionsCategoryConfiguration(
            plugins: [
                "CoreMLPredictionsPlugin": []
            ]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: predictionsConfig)

        // Set up Amplify
        do {
            try Amplify.add(plugin: CoreMLPredictionsPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify")
        }
        print("Amplify initialized")
    }

}
