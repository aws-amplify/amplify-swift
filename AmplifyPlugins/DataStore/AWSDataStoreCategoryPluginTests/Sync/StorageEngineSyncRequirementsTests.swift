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
@testable import AWSPluginsCore

class StorageEngineSyncRequirementsTests: XCTestCase {

    // MARK: - RequiresAuthPlugin tests

    func testRequiresAuthPluginFalseForMissingAuthRules() {
        let apiPlugin = MockAPICategoryPlugin()
        let result = AWSDataStorePlugin.requiresAuthPlugin(apiPlugin)
        XCTAssertFalse(result)
    }

    func testRequiresAuthPluginSingleAuthRuleAPIKey() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .owner, provider: .apiKey)]
        XCTAssertFalse(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginSingleAuthRuleOIDC() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .owner, provider: .oidc)]
        XCTAssertFalse(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginSingleAuthRuleFunction() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .private, provider: .function)]
        XCTAssertFalse(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginSingleAuthRuleUserPools() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .owner, provider: .userPools)]
        XCTAssertTrue(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginSingleAuthRuleIAM() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .owner, provider: .iam)]
        XCTAssertTrue(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeFunction() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .function
        XCTAssertFalse(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeAPIKey() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .apiKey
        XCTAssertFalse(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeUserPools() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .amazonCognitoUserPools
        XCTAssertTrue(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeIAM() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .awsIAM
        XCTAssertTrue(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeODIC() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .openIDConnect
        XCTAssertFalse(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeNone() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = AWSAuthorizationType.none
        XCTAssertFalse(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginOIDCProvider() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.defaultAuthTypeError = APIError.unknown("Could not get default auth type", "", nil)
        let oidcProvider = MockOIDCAuthProvider()
        apiPlugin.authProviderFactory = MockAPIAuthProviderFactory(oidcProvider: oidcProvider)
        XCTAssertFalse(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginFunctionProvider() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.defaultAuthTypeError = APIError.unknown("Could not get default auth type", "", nil)
        let functionProvider = MockFunctionAuthProvider()
        apiPlugin.authProviderFactory = MockAPIAuthProviderFactory(functionProvider: functionProvider)
        XCTAssertFalse(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    func testRequiresAuthPluginWithAuthRules() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.defaultAuthTypeError = APIError.unknown("Could not get default auth type", "", nil)
        XCTAssertTrue(AWSDataStorePlugin.requiresAuthPlugin(apiPlugin, authRules: authRules))
    }

    // MARK: - AuthRules tests

    /// Given: a list of auth rules
    /// When: if one or more provider is user pools
    /// Then: Auth plugin is required
    func testRequireAuthPluginWithOIDCProvider() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .oidc),
            AuthRule(allow: .private, provider: .iam),
            AuthRule(allow: .owner, provider: .userPools)
        ]
        XCTAssertTrue(authRules.requireAuthPlugin!)
    }

    /// Given: a list of auth rules
    /// When: if one or more provider is iam
    /// Then: Auth plugin is required
    func testRequireAuthPluginWithFunctionProvider() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .function),
            AuthRule(allow: .owner, provider: .iam)
        ]
        XCTAssertTrue(authRules.requireAuthPlugin!)
    }

    /// Given: a list of auth rules
    /// When: if all providers are odic/function/apikey,
    /// Then: Auth plugin is not required
    func testDoesNotRequireAuthPlugin() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: .oidc),
            AuthRule(allow: .owner, provider: .function),
            AuthRule(allow: .public, provider: .apiKey)
        ]
        XCTAssertFalse(authRules.requireAuthPlugin!)
    }

    /// Given: a list of auth rules
    /// When: if the provider is `nil`
    /// Then: cannot be determined
    func testRequireAuthPluginIfProviderIsNil() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: nil)
        ]
        XCTAssertNil(authRules.requireAuthPlugin)
    }

    /// Given: a list of auth rules
    /// When: if one of the providers is `nil`
    /// Then: cannot be determined
    func testRequireAuthPluginIfOneRulHasProviderNil() {
        let authRules: AuthRules = [
            AuthRule(allow: .owner, provider: nil),
            AuthRule(allow: .public, provider: .apiKey)
        ]
        XCTAssertNil(authRules.requireAuthPlugin)
    }

    // MARK: - Helpers

    class MockAPIAuthInformationPlugin: MockAPICategoryPlugin, AWSAPIAuthInformation {

        var authType: AWSAuthorizationType?

        var defaultAuthTypeError: APIError?

        func defaultAuthType() throws -> AWSAuthorizationType {
            try defaultAuthType(for: nil)
        }

        func defaultAuthType(for apiName: String?) throws -> AWSAuthorizationType {
            if let error = defaultAuthTypeError {
                throw error
            } else if let authType = authType {
                return authType
            } else {
                return .amazonCognitoUserPools
            }
        }
    }
}
