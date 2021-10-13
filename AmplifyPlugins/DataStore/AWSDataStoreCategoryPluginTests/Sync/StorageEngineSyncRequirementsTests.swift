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

    // MARK: - AuthRule tests
    
    /// Given: a list of auth rules
    /// When: if at least one provider requires auth plugin
    /// Then: Auth plugin is required
    func testRequireAuthPluginWithOneRequird() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .oidc), // does not require auth plugin
            AuthRule(allow: .private, provider: .iam), // requires auth plugin
            AuthRule(allow: .owner, provider: .userPools) // requires auth plugin
        ]
        XCTAssertTrue(authRules.requireAuthPlugin!)
    }

    /// Given: a list of auth rules
    /// When: If all providers do not require auth plugin
    /// Then: Auth plugin is not required
    func testRequireAuthPluginWithAllNotRequired() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .function),
            AuthRule(allow: .owner, provider: .apiKey),
            AuthRule(allow: .owner, provider: .oidc)
        ]
        XCTAssertFalse(authRules.requireAuthPlugin!)
    }
    
    func testRequireAuthPluginWithOIDCProvider() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .oidc)
        ]
        XCTAssertFalse(authRules.requireAuthPlugin!)
    }
    
    func testRequireAuthPluginWithFunctionProvider() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .function)
        ]
        XCTAssertFalse(authRules.requireAuthPlugin!)
    }
    
    func testRequireAuthPluginWithAPIKeyProvider() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .apiKey)
        ]
        XCTAssertFalse(authRules.requireAuthPlugin!)
    }
    
    func testRequireAuthPluginWithUserPoolsProvider() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .userPools)
        ]
        XCTAssertTrue(authRules.requireAuthPlugin!)
    }
    
    func testRequireAuthPluginWithIAMProvider() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .iam)
        ]
        XCTAssertTrue(authRules.requireAuthPlugin!)
    }


    func testRequireAuthPluginIfProviderIsNil() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: nil)
        ]
        XCTAssertNil(authRules.requireAuthPlugin)
    }

    func testRequireAuthPluginIfOneRulHasProviderNil() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: nil),
            AuthRule(allow: .public, provider: .apiKey)
        ]
        XCTAssertNil(authRules.requireAuthPlugin)
    }
}
