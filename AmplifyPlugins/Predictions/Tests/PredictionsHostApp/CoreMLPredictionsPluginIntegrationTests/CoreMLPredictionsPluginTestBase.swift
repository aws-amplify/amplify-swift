//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreMLPredictionsPlugin
import XCTest
@testable import Amplify

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSPredictionsPluginTestBase: XCTestCase, @unchecked Sendable {
    let region: JSONValue = "us-east-1"
    // 180 seconds to wait before network timeouts
    let networkTimeout = TimeInterval(180)

    override func setUp() {
        setupAmplify()
    }

    override func tearDown() async throws {
        print("Amplify reset")
        await Amplify.reset()
    }

    private func setupAmplify() {
        // Set up Amplify predictions configuration
        let predictionsConfig = PredictionsCategoryConfiguration(
            plugins: [
                "CoreMLPredictionsPlugin": []
            ]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: predictionsConfig)

        do {
            try Amplify.add(plugin: CoreMLPredictionsPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify")
        }
        print("Amplify initialized")
    }

}
