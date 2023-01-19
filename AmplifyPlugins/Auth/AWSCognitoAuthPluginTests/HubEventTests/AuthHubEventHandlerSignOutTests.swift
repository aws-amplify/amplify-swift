//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSPluginsCore

final class AuthHubEventHandlerSignOutTests: XCTestCase {

    var systemUnderTest: AuthHubEventHandler!

    override func setUpWithError() throws {
        try Amplify.configure(AmplifyConfiguration())
        systemUnderTest = AuthHubEventHandler()
    }

    override func tearDownWithError() throws {
        Amplify.reset()
        systemUnderTest = nil
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A signOutAPI event without an data property is received
    /// - Then: No signedOut event is emitted
    func testWithoutData() throws {
        let signedOutExpectation = expectation(description: "signedOut")
        signedOutExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedOut:
                signedOutExpectation.fulfill()
            default:
                break
            }
        }

        let payload = HubPayload(eventName: HubPayload.EventName.Auth.signOutAPI)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [signedOutExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A signOutAPI event with a data value representing success is received
    /// - Then: A signedOut event is emitted
    func testWithData() {
        let signedOutExpectation = expectation(description: "signedOut")

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedOut:
                signedOutExpectation.fulfill()
            default:
                break
            }
        }

        let operationResult: AWSAuthSignOutOperation.OperationResult = .success(())
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.signOutAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [signedOutExpectation], timeout: 1)
    }

}
