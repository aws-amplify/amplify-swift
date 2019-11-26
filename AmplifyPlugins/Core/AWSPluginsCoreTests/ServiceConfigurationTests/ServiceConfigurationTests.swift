//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore

class ServiceConfigurationTests: XCTestCase {

    let credentialProvider = AWSAuthService().getCognitoCredentialsProvider()

    /// Test if we can initialize configuration
    ///
    /// - Given: ServiceConfiguration class
    /// - When:
    ///    - I initialize ServiceConfiguration
    /// - Then:
    ///    - I should get a non nil and non empty user agent
    ///
    func testUserAgent() {
        let configuration = ServiceConfiguration(region: .USEast1,
                                                 credentialsProvider: credentialProvider)
        XCTAssertNotNil(configuration.userAgent, "User agent should not be nil")
        XCTAssertNotEqual(configuration.userAgent, "", "User agent should not be empty")
    }

    /// Test if configuration contain amplify in userAgent
    ///
    /// - Given: A ServiceConfiguration object
    /// - When:
    ///    - I check the userAgent
    /// - Then:
    ///    - I should get aws-amplify-iOS as part of user Agent
    ///
    func testUserAgentWithAmplify() {
        let configuration = ServiceConfiguration(region: .USEast1,
                                                 credentialsProvider: credentialProvider)
        let amplifyKeyWord = configuration.userAgent.contains("aws-amplify-iOS")
        XCTAssertTrue(amplifyKeyWord, "User agent should contain amplify keyword")
    }
}
