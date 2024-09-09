//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import XCTest
@testable import Amplify

class AuthFetchDeviceTests: AWSAuthBaseTest {

    var unsubscribeToken: UnsubscribeToken!

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Calling fetch devices with a user signed in should return a successful result
    ///
    /// - Given: A valid username is registered and sign in - no device is remembered
    /// - When:
    ///    - I invoke fetchDevices with the username
    /// - Then:
    ///    - I should get a successful result with empty devices list
    ///
    func testSuccessfulFetchDevices() async throws {

        // register a user and signin
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "SignIn event should be fired")

        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signInExpectation.fulfill()
            default:
                break
            }
        }

        do {
            _ = try await AuthSignInHelper.registerAndSignInUser(
                username: username,
                password: password,
                email: defaultTestEmail
            )
        } catch {
            print(error)
        }

        await fulfillment(of: [signInExpectation], timeout: networkTimeout)

        // fetch devices
        let devices = try await Amplify.Auth.fetchDevices()
        XCTAssertNotNil(devices)
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices.first?.name.isEmpty, false)
        XCTAssertEqual(devices.first?.id.isEmpty, false)
        guard let awsDevice = devices.first as? AWSAuthDevice else {
            XCTFail("Should be able to cast to AWSAuthDevice")
            return
        }
        XCTAssertEqual(awsDevice.attributes.isEmpty, false)
        XCTAssertNotNil(awsDevice.createdDate)
        XCTAssertNotNil(awsDevice.lastAuthenticatedDate)
        XCTAssertNotNil(awsDevice.lastModifiedDate)
    }
}
