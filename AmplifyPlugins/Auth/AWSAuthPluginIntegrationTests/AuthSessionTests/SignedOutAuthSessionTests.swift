//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSAuthPlugin
import AWSPluginsCore

class SignedOutAuthSessionTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
    }

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    /// Test if we can fetch auth session in signedOut state
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testSuccessfulSessionFetch() {
        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        let operation = Amplify.Auth.fetchAuthSession {event in
            switch event {
            case .completed(let result):
                XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
            case .failed(let error):
                XCTFail("Should not receive error \(error)")
            default:
                break
            }
            authSessionExpectation.fulfill()
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [authSessionExpectation], timeout: networkTimeout)
    }

    /// Test if we can retreive valid credentials for a signedOut session.
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testSuccessfulSessionFetchWithCredentials() {
        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        let operation = Amplify.Auth.fetchAuthSession {event in
            switch event {
            case .completed(let result):
                XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
                let credentialsResult = (result as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard let awsCredentails = try? credentialsResult?.get() else {
                    XCTFail("Could not fetch aws credentials")
                    return
                }
                XCTAssertNotNil(awsCredentails.accessKey, "Access key should not be nil")

            case .failed(let error):
                XCTFail("Should not receive error \(error)")
            default:
                break
            }
            authSessionExpectation.fulfill()
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [authSessionExpectation], timeout: networkTimeout)
    }
}
