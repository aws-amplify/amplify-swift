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

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPredictionsPlugin())
            try Amplify.configure()
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
