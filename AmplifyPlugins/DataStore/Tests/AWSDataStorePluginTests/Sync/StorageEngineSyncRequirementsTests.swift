//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

class StorageEngineSyncRequirementsTests: XCTestCase {

    // MARK: - RequiresAuthPlugin tests

    func testRequiresAuthPluginFalseForMissingAuthRules() {
        let apiPlugin = MockAPICategoryPlugin()
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginSingleAuthRuleAPIKey() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .owner, provider: .apiKey)]
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginSingleAuthRuleOIDC() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .owner, provider: .oidc)]
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginSingleAuthRuleFunction() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .private, provider: .function)]
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginSingleAuthRuleUserPools() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .owner, provider: .userPools)]
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginSingleAuthRuleIAM() {
        let apiPlugin = MockAPICategoryPlugin()
        let authRules = [AuthRule(allow: .owner, provider: .iam)]
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeFunction() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .function
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeAPIKey() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .apiKey
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeUserPools() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .amazonCognitoUserPools
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeIAM() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .awsIAM
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeODIC() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = .openIDConnect
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginNoProvidersWithAuthTypeNone() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = AWSAuthorizationType.none
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginOIDCProvider() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.defaultAuthTypeError = APIError.unknown("Could not get default auth type", "", nil)
        let oidcProvider = MockOIDCAuthProvider()
        apiPlugin.authProviderFactory = MockAPIAuthProviderFactory(oidcProvider: oidcProvider)
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }
    
    func testRequiresAuthPluginOIDCProvider_MultiAuthRules() {
        // OIDC requires an auth provider on the API, this is added below
        let authRules = [AuthRule(allow: .owner, provider: .oidc),
                         AuthRule(allow: .private, provider: .iam)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.defaultAuthTypeError = APIError.unknown("Could not get default auth type", "", nil)
        let oidcProvider = MockOIDCAuthProvider()
        apiPlugin.authProviderFactory = MockAPIAuthProviderFactory(oidcProvider: oidcProvider)
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, 
                                                        authRules: authRules,
                                                        authModeStrategy: .default),
                       "Should be false since OIDC is the default auth type on the API.")
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin,
                                                       authRules: authRules,
                                                       authModeStrategy: .multiAuth),
                      "Should be true since IAM requires auth plugin.")
    }
    
    func testRequiresAuthPluginUserPoolProvider_MultiAuthRules() {
        let authRules = [AuthRule(allow: .owner, provider: .userPools),
                         AuthRule(allow: .private, provider: .iam)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.authType = AWSAuthorizationType.amazonCognitoUserPools
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin,
                                                        authRules: authRules,
                                                        authModeStrategy: .default),
                       "Should be true since UserPool is the default auth type on the API.")
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin,
                                                       authRules: authRules,
                                                       authModeStrategy: .multiAuth),
                      "Should be true since both UserPool and IAM requires auth plugin.")
    }

    func testRequiresAuthPluginFunctionProvider() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.defaultAuthTypeError = APIError.unknown("Could not get default auth type", "", nil)
        let functionProvider = MockFunctionAuthProvider()
        apiPlugin.authProviderFactory = MockAPIAuthProviderFactory(functionProvider: functionProvider)
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertFalse(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
    }

    func testRequiresAuthPluginWithAuthRules() {
        let authRules = [AuthRule(allow: .owner)]
        let apiPlugin = MockAPIAuthInformationPlugin()
        apiPlugin.defaultAuthTypeError = APIError.unknown("Could not get default auth type", "", nil)
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .default))
        XCTAssertTrue(StorageEngine.requiresAuthPlugin(apiPlugin, authRules: authRules, authModeStrategy: .multiAuth))
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
