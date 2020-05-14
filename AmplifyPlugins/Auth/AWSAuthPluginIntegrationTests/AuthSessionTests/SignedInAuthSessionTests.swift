//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSAuthPlugin

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
        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        _ = Amplify.Auth.fetchAuthSession {event in

            authSessionExpectation.fulfill()
        }
        wait(for: [authSessionExpectation], timeout: 500)
    }
}
