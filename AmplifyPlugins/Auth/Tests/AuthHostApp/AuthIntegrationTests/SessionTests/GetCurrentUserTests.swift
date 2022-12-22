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

class GetCurrentUserTests: AWSAuthBaseTest {
    
    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test get current user API
    ///
    /// - Given: A signedIn Amplify Auth Category
    /// - When:
    ///    - I call Amplify.Auth.getCurrentUser
    /// - Then:
    ///    - I should receive a valid user back
    ///
    func testSuccessfulGetCurrentUser() async throws {
        let username = "integtest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        _ = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)

        let authUser = try await Amplify.Auth.getCurrentUser()

        XCTAssertEqual(authUser.username.lowercased(), username.lowercased())
        XCTAssertNotNil(authUser.userId)
    }

}
