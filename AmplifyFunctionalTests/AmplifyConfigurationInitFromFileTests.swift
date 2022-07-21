//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AmplifyTestCommon

/// Test the public AmplifyConfiguration initializer. Note that this means we must not import
/// Amplify as `@testable`. That means we cannot `await Amplify.reset()`, which means we can only have
/// one test in this file. Further, this means we need to ensure that other tests do call
/// `await Amplify.reset()` in their static `setUp()` and `tearDown()` methods.
class AmplifyConfigurationInitFromFileTests: XCTestCase {

    func testInitFromFile() throws {
        let configString = """
        {
            "UserAgent": "aws-amplify-cli/2.0",
            "Version": "1.0"
        }
        """

        let configData = configString.data(using: .utf8)!
        let configURL = FileManager
            .default
            .temporaryDirectory
            .appendingPathComponent("testconfig.json")
        try configData.write(to: configURL)

        var config: AmplifyConfiguration!
        XCTAssertNoThrow(config = try AmplifyConfiguration(configurationFile: configURL))
        XCTAssertNoThrow(try Amplify.configure(config))
    }

}
