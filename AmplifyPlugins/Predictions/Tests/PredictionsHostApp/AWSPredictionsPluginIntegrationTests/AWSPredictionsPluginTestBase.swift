//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPredictionsPlugin
import AWSCognitoAuthPlugin
@testable import Amplify
import Foundation

class AWSPredictionsPluginTestBase: XCTestCase {

    // 20 seconds to wait before network timeouts
    let networkTimeout = TimeInterval(20)
    let amplifyConfigurationFile = "testconfiguration/AWSPredictionsPluginIntegrationTests-amplifyconfiguration"

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        do {
            guard let path = Bundle.init(for: type(of: self)).path(
                forResource: amplifyConfigurationFile,
                ofType: "json"
            ) else {
                fatalError("❌ Could not retrieve configuration file: \(amplifyConfigurationFile)")
            }

            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            let jsonDecoder = JSONDecoder()
            let configuration = try jsonDecoder.decode(
                AmplifyConfiguration.self,
                from: data
            )

            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPredictionsPlugin())
            try Amplify.configure(configuration)
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
