//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore

class FederatedSessionTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test unsuccessful federation
    ///
    /// - Given: A not authorized token from 3P provider
    /// - When:
    ///    - I invoke Amplify.Auth.federateToIdentityPool
    /// - Then:
    ///    - I should get a not authorized error
    ///
    func testUnsuccessfulFederation() async throws {
        let authCognitoPlugin = try! Amplify.Auth.getPlugin(for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin
        do {
            _ = try await authCognitoPlugin.federateToIdentityPool( withProviderToken: "someToken", for: .facebook)
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("SignIn with a valid username/password should not fail \(error)")
                return
            }
        }
    }

}
