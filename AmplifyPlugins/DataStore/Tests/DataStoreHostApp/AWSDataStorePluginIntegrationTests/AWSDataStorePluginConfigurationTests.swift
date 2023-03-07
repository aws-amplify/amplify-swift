//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSDataStorePlugin

class AWSDataStorePluginConfigurationTests: XCTestCase {

    override func tearDown() async throws {
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    // Note this test requires the ability to write a new database in the Documents directcory, so it must be embedded
    // in a host app
    func testDoesNotThrowOnMissingConfig() throws {
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration())
        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyConfiguration()
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTAssertNil(error, "Should not throw even if not supplied with a plugin-specific config.")
        }
    }

}
