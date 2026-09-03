//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSDataStorePlugin
import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSDataStorePluginFlutterConfigurationTests: XCTestCase, @unchecked Sendable {

    // Note this test requires the ability to write a new database in the Documents directory, so it must be embedded
    // in a host app
    func testDoesNotThrowOnMissingConfig() throws {
        let plugin = AWSDataStorePlugin(modelRegistration: TestFlutterModelRegistration())
        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyConfiguration()
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTAssertNil(error, "Should not throw even if not supplied with a plugin-specific config.")
        }
    }

}
