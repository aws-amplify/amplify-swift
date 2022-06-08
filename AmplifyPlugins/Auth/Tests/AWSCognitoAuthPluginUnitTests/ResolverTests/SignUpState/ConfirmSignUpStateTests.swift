//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import AWSCognitoIdentityProvider

class ConfirmSignUpStateTests: XCTestCase {
    func testConfirmingSignUpResolver() throws {
        let sequence = SignUpStateSequence(oldState: .confirmingSignUp(ConfirmSignUpEventData()),
                                           event: .confirmSignUpEvent,
                                           expected: .confirmingSignUp(ConfirmSignUpEventData()))
        sequence.assertResolvesToExpected()
    }

    func testConfirmingSignUpSuccessResolver() throws {
        let sequence = SignUpStateSequence(oldState: .confirmingSignUp(ConfirmSignUpEventData()),
                                           event: .confirmSignUpSuccessEvent,
                                           expected: .signedUp)
        sequence.assertResolvesToExpected()
    }

    func testConfirmingSignUpFailureResolver() throws {
        let sequence = SignUpStateSequence(oldState: .confirmingSignUp(ConfirmSignUpEventData()),
                                           event: .confirmSignUpFailureEvent,
                                           expected: .error(.invalidConfirmationCode(message: "")))
        sequence.assertResolvesToExpected()
    }

    func testConfirmSigningUpDispatcher() {
        let exp = expectation(description: #function)

        let username = "bob"
        let confirmationCode = "123456"

        let confirmSignUpCallback: MockIdentityProvider.MockConfirmSignUpResponse = { _ in
            let response = try! ConfirmSignUpOutputResponse(httpResponse: MockHttpResponse.ok)
            exp.fulfill()
            return response
        }

        let cognitoUserPoolFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(mockConfirmSignUpResponse: confirmSignUpCallback)
        }

        let environment = BasicUserPoolEnvironment(userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
                                                   cognitoUserPoolFactory: cognitoUserPoolFactory)

        let confirmSignUpEventData = ConfirmSignUpEventData(username: username, confirmationCode: confirmationCode)
        let action = ConfirmSignUp(confirmSignUpEventData: confirmSignUpEventData)

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignUpEvent else {
                XCTFail("Expected event to be SignUpEvent but got \(event)")
                return
            }

            if case .confirmSignUp(let confirmSignUpEventData) = event.eventType {
                XCTAssertEqual(username, confirmSignUpEventData.username)
                XCTAssertEqual(confirmationCode, confirmSignUpEventData.confirmationCode)
            }
        }

        action.execute(withDispatcher: dispatcher, environment: environment)

        wait(for: [exp], timeout: 1.0)
    }

}
