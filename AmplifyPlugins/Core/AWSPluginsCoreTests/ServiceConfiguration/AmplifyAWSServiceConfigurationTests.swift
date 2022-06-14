//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPluginsCore
@testable import AWSClientRuntime

class AmplifyAWSServiceConfigurationTests: XCTestCase {

    override func tearDown() async throws {
        AmplifyAWSServiceConfiguration.platformMapping = [:]
    }

    /// Test initiating AmplifyAWSServiceConfiguration
    ///
    /// - Given: Amplify library
    /// - When:
    ///    - I call AmplifyAWSServiceConfiguration with credential provider
    /// - Then:
    ///    - AmplifyAWSServiceConfiguration should be configured properly
    ///
    func testInstantiation() {
        let frameworkMetaData = AmplifyAWSServiceConfiguration.frameworkMetaData()
        XCTAssertNotNil(frameworkMetaData)
        XCTAssertEqual(frameworkMetaData.sanitizedName, "amplify-ios")
        XCTAssertEqual(frameworkMetaData.sanitizedVersion, AmplifyAWSServiceConfiguration.version)
    }

    /// Test adding a new platform to AmplifyAWSServiceConfiguration
    ///
    /// - Given: Amplify library
    /// - When:
    ///    - I add a new platform to the AmplifyAWSServiceConfiguration
    /// - Then:
    ///    - AmplifyAWSServiceConfiguration should be configured properly with the new platform added.
    ///
    func testAddNewPlatform() {
        AmplifyAWSServiceConfiguration.addUserAgentPlatform(.flutter, version: "1.1")
        let frameworkMetaData = AmplifyAWSServiceConfiguration.frameworkMetaData()
        XCTAssertNotNil(frameworkMetaData)
        XCTAssertEqual(frameworkMetaData.sanitizedName, "amplify-flutter")
        XCTAssertEqual(frameworkMetaData.sanitizedVersion, "1.1")

        XCTAssertNotNil(frameworkMetaData.extras)
        XCTAssertEqual(frameworkMetaData.extras["amplify-ios"], AmplifyAWSServiceConfiguration.version)
    }
}
