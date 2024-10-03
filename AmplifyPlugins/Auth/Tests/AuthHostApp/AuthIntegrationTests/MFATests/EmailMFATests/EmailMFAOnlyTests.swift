//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin

// MFA Required
//  - Email
class EmailMFAOnlyTests: AWSAuthBaseTest {

    override func setUp() async throws {
        onlyUseGen2Configuration = true
        // Use a custom configuration these tests
        amplifyOutputsFile = "testconfiguration/amplify_outputs"

        let awsApiPlugin = AWSAPIPlugin()
        try Amplify.add(plugin: awsApiPlugin)
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test a signIn with valid inputs getting continueSignInWithEmailMFASetup challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .continueSignInWithEmailMFASetup response
    ///
    //Requires only Email MFA to be enabled
    func disabled_testSuccessfulEmailMFASetupStep() async {

        do {
            let uniqueId = UUID().uuidString
            let username = "integTest\(uniqueId)"
            let password = "Pp123@\(uniqueId)"

            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password)

            let options = AuthSignInRequest.Options()
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: options)

            guard case .continueSignInWithEmailMFASetup = result.nextStep else {
                XCTFail("Result should be .continueSignInWithEmailMFASetup for next step, instead got: \(result.nextStep)")
                return
            }
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }
}
