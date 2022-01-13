//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

import AWSCognitoIdentityProvider
import hierarchical_state_machine_swift

class ConfirmSignUpStateTests: XCTestCase {
    func testConfirmingSignUpResolver() throws {
        let sequence = SignUpStateSequence(oldState: .confirmingSignUp,
                                           event: .confirmSignUpEvent,
                                           expected: .confirmingSignUp)
        sequence.assertResolvesToExpected()
    }

    func testConfirmingSignUpSuccessResolver() throws {
        let sequence = SignUpStateSequence(oldState: .confirmingSignUp,
                                           event: .confirmSignUpSuccessEvent,
                                           expected: .signedUp)
        sequence.assertResolvesToExpected()
    }

    func testConfirmingSignUpFailureResolver() throws {
        let sequence = SignUpStateSequence(oldState: .confirmingSignUp,
                                           event: .confirmSignUpFailureEvent,
                                           expected: .error)
        sequence.assertResolvesToExpected()
    }

    func testConfirmSigningUpDispatcher() {
        let exp = expectation(description: #function)

        let username = "bob"
        let confirmationCode = "123456"

        let confirmSignUpCallback: MockIdentityProvider.ConfirmSignUpCallback = { (input, callback) in
            let response = ConfirmSignUpOutputResponse()
            callback(.success(response))
            exp.fulfill()
        }

        let cognitoUserPoolFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(confirmSignUpCallback: confirmSignUpCallback)
        }

        let environment = BasicUserPoolEnvironment(userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
                                                   cognitoUserPoolFactory: cognitoUserPoolFactory)

        let command = ConfirmSignUp(username: username, confirmationCode: confirmationCode)

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignUpEvent else {
                XCTFail("Expected event to be SignUpEvent but got \(event)")
                return
            }

            if case .confirmSignUp(let eventUsername, let eventConfirmationCode) = event.eventType {
                XCTAssertEqual(username, eventUsername)
                XCTAssertEqual(confirmationCode, eventConfirmationCode)
            }
        }

        command.execute(withDispatcher: dispatcher, environment: environment)

        wait(for: [exp], timeout: 1.0)
    }

}
