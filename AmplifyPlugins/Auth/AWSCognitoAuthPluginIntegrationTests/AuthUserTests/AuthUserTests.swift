//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthUserTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
    }

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    /// Test retreiving user in a signedout state
    ///
    /// - Given: Amplify Auth plugin in signedout state
    /// - When:
    ///    - I retreive the current user
    /// - Then:
    ///    - I should get a nil object
    ///
    func testUserInSignedOut() {
        let user = Amplify.Auth.getCurrentUser()
        XCTAssertNil(user, "In signedout state the user should be nil")
    }

    /// Test retreiving user in a signedIn state
    ///
    /// - Given: Amplify Auth plugin in signedIn state
    /// - When:
    ///    - I retreive the current user
    /// - Then:
    ///    - I should get a valid user
    ///
    func testUserInSignedIn() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username, password: password) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let user = Amplify.Auth.getCurrentUser()
        XCTAssertNotNil(user, "In signedIn state the user should be nil")
    }
}
