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

    
    // MARK: - Stress tests
    /// Test concurrent invocations of get current user API
    ///
    /// - Given: A signedIn Amplify Auth Category
    /// - When:
    ///    - I call Amplify.Auth.getCurrentUser for 50 tasks simultaneously
    /// - Then:
    ///    - I should receive a valid user back
    ///
    func testMultipleGetCurrentUser() async throws {
        let username = "integtest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)

        XCTAssertTrue(didSucceed, "SignIn operation failed")
        
        let getCurrentUserExpectation = asyncExpectation(description: "getCurrentUser() is successful",
                                                         expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                let authUser = try await Amplify.Auth.getCurrentUser()
                XCTAssertEqual(authUser.username.lowercased(), username.lowercased())
                XCTAssertNotNil(authUser.userId)
                await getCurrentUserExpectation.fulfill()
            }
        }
        
        await waitForExpectations([getCurrentUserExpectation], timeout: networkTimeout)
    }
}
