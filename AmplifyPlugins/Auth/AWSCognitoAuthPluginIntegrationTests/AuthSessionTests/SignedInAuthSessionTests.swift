//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class SignedInAuthSessionTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
    }

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    func testSuccessfulSessionFetch() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username, password: password) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSessionExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
        }
        wait(for: [authSessionExpectation], timeout: networkTimeout)
    }
}
