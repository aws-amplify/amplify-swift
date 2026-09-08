//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AuthRuleExtensionTests: XCTestCase, @unchecked Sendable {
    func testAuthRuleProviderToAWSAuth() throws {
        let authRuleProviders: [AuthRuleProvider] = [.apiKey, .oidc, .iam, .userPools]
        let expectedAuthTypes: [AWSAuthorizationType] = [
            .apiKey,
            .openIDConnect,
            .awsIAM,
            .amazonCognitoUserPools
        ]

        for (index, provider) in authRuleProviders.enumerated() {
            XCTAssertEqual(provider.toAWSAuthorizationType(), expectedAuthTypes[index])
        }
    }
}
