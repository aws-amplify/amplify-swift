//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import XCTest
@testable import Amplify

class AuthSignOutTests: AWSAuthBaseTest {
    // Enable this to set the aws-sdk-swift log level during debugging.
    // This can only be called once per process.
    private static var setSDKLogLevelDebug = true

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
        if Self.setSDKLogLevelDebug {
            SDKLoggingSystem.initialize(logLevel: .debug)
            Self.setSDKLogLevelDebug = false
        }
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test successful signOut with globalSignout enabled.
    ///
    /// - Given: A user signed in via Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signOut
    /// - Then:
    ///    - I should get a completed signout flow.
    ///
    func testGlobalSignOut() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username,
                                    password: password,
                                    email: defaultTestEmail)

        XCTAssertTrue(didSucceed, "Signup operation failed")

        print("calling signOut...")
        try await signOut(globalSignOut: true)
    }

    /// Test successful signOut with globalSignout disabled.
    ///
    /// - Given: A user signed in via Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signOut
    /// - Then:
    ///    - I should get a completed signout flow.
    ///
    func testNonGlobalSignOut() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username,
                                    password: password,
                                    email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "Signup operation failed")
        print("calling signOut...")
        try await signOut(globalSignOut: false)
    }

    /// Test if invoking signOut without unauthenticate state does not fail
    ///
    /// - Given: An unauthenticated state
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSignedOutWithUnAuthState() async throws {
        _ = await Amplify.Auth.signOut()
    }

    private func signOut(globalSignOut: Bool) async throws {
        let options = AuthSignOutRequest.Options(globalSignOut: globalSignOut)
        _ = await Amplify.Auth.signOut(options: options)
    }
}
