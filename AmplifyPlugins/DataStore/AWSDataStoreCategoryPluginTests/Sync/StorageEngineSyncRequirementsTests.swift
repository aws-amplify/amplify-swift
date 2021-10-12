//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class StorageEngineSyncRequirementsTests: XCTestCase {

    /// Given: a list of auth rules
    /// When: if one or more provider is not of type function/oidc
    /// Then: Auth plugin is required
    func testRequireAuthPluginWithOIDCProvider() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .oidc),
            AuthRule(allow: .private, provider: .iam),
            AuthRule(allow: .owner, provider: .userPools)
        ]
        XCTAssertTrue(authRules.requireAuthPlugin)
    }

    /// Given: a list of auth rules
    /// When: if one or more provider is not of type function/oidc
    /// Then: Auth plugin is required
    func testRequireAuthPluginWithFunctionProvider() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .function),
            AuthRule(allow: .owner, provider: .iam)
        ]
        XCTAssertTrue(authRules.requireAuthPlugin)
    }

    func testDoesNotRequireAuthPlugin() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .oidc),
            AuthRule(allow: .owner, provider: .function),
            AuthRule(allow: .public, provider: .apiKey)
        ]
        XCTAssertFalse(authRules.requireAuthPlugin)
    }
}
