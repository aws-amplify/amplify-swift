//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPluginsCore

class AmplifyAWSServiceConfigurationTests: XCTestCase {
    let credentialProvider = AWSAuthService().getCredentialsProvider()

    override func tearDown() {
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
        let currentSystemName = UIDevice.current.systemName.replacingOccurrences(of: " ", with: "-")
        let currentSystemVersion = UIDevice.current.systemVersion
        let expectedLocale = Locale.current.identifier
        let expectedSystem = "\(currentSystemName)/\(currentSystemVersion)"

        let configuration = AmplifyAWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)

        XCTAssertNotNil(configuration.userAgent)
        let userAgentParts = configuration.userAgent.components(separatedBy: " ")
        XCTAssertEqual(3, userAgentParts.count)
        XCTAssert(userAgentParts[0].starts(with: "amplify-iOS/"))
        XCTAssertEqual(expectedSystem, userAgentParts[1])
        XCTAssertEqual(expectedLocale, userAgentParts[2])
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
        let currentSystemName = UIDevice.current.systemName.replacingOccurrences(of: " ", with: "-")
        let currentSystemVersion = UIDevice.current.systemVersion
        let expectedLocale = Locale.current.identifier
        let expectedSystem = "\(currentSystemName)/\(currentSystemVersion)"
        let expectedPlatform = "\(AmplifyAWSServiceConfiguration.Platform.flutter.rawValue)/1.1"
        let configuration = AmplifyAWSServiceConfiguration()

        XCTAssertNotNil(configuration.userAgent)
        let userAgentParts = configuration.userAgent.components(separatedBy: " ")
        XCTAssertEqual(4, userAgentParts.count)
        XCTAssertEqual(expectedPlatform, userAgentParts[0])
        XCTAssert(userAgentParts[1].starts(with: "amplify-iOS/"))
        XCTAssertEqual(expectedSystem, userAgentParts[2])
        XCTAssertEqual(expectedLocale, userAgentParts[3])
    }
}
