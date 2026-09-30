//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import Foundation
import XCTest
@testable import Amplify
@testable import AWSPredictionsPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSPredictionsPluginTestBase: XCTestCase, @unchecked Sendable {

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
