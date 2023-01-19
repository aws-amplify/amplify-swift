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

final class AuthHubEventHandlerUserDeletedTests: XCTestCase {

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
    /// - When: A deleteUserAPI event without an data property is received
    /// - Then: No userDeleted event is emitted
    func testWithoutData() throws {
        let userDeletedExpectation = expectation(description: "userDeleted")
        userDeletedExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.userDeleted:
                userDeletedExpectation.fulfill()
            default:
                break
            }
        }

        let payload = HubPayload(eventName: HubPayload.EventName.Auth.deleteUserAPI)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [userDeletedExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A deleteUserAPI event with a data value representing success is received
    /// - Then: A session userDeleted event is emitted
    func testWithData() {
        let userDeletedExpectation = expectation(description: "userDeleted")

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.userDeleted:
                userDeletedExpectation.fulfill()
            default:
                break
            }
        }

        let operationResult: AWSAuthDeleteUserOperation.OperationResult = .success(())
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.deleteUserAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [userDeletedExpectation], timeout: 1)
    }

}
