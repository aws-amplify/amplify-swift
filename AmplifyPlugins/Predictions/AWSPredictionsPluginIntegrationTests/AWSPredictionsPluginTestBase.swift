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

class AWSPredictionsPluginTestBase: XCTestCase {

    let networkTimeout = TimeInterval(180) // 180 seconds to wait before network timeouts

    override func setUp() async throws {
        try await super.setUp()

        continueAfterFailure = false

        let bundle = Bundle(for: type(of: self))
        guard let configFile = bundle.url(forResource: "amplifyconfiguration", withExtension: "json") else {
            XCTFail("Could not get URL for amplifyconfiguration.json from \(bundle)")
            return
        }

        do {
            let configData = try Data(contentsOf: configFile)
            let amplifyConfig = try JSONDecoder().decode(AmplifyConfiguration.self, from: configData)
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPredictionsPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() async throws {
        sleep(1)
        print("Amplify reset")
        await Amplify.reset()
    }
}
