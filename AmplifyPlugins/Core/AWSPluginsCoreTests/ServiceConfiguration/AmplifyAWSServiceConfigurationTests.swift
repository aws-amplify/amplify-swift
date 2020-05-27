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
    func testInstantiation() {
        let currentSystemName = UIDevice.current.systemName.replacingOccurrences(of: " ", with: "-")
        let currentSystemVersion = UIDevice.current.systemVersion
        let expectedLocale = Locale.current.identifier
        let expectedSystem = "\(currentSystemName)/\(currentSystemVersion)"

        let configuration = AmplifyAWSServiceConfiguration(region: .USEast1,
                                                           credentialsProvider: credentialProvider)

        XCTAssertNotNil(configuration.userAgent)
        let userAgentParts = configuration.userAgent.components(separatedBy: " ")
        XCTAssertEqual(3, userAgentParts.count)
        XCTAssert(userAgentParts[0].starts(with: "amplify-iOS/"))
        XCTAssertEqual(expectedSystem, userAgentParts[1])
        XCTAssertEqual(expectedLocale, userAgentParts[2])
    }
}
