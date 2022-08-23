//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPluginsCore

class AuthRuleExtensionTests: XCTestCase {
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
