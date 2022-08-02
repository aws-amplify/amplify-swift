//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

import AWSCognitoIdentityProvider

class SignUpStateTests: XCTestCase {
    func testSignUpNotStartedResolver() throws {
        let sequence = SignUpStateSequence(oldState: .notStarted,
                                           event: .initiateSignUpEvent,
                                           expected: .initiatingSigningUp(SignUpEventData()))
        sequence.assertResolvesToExpected()
    }

    func testSignUpInitiatingSigningUpSuccessResolver() throws {
        let sequence = SignUpStateSequence(oldState: .initiatingSigningUp(SignUpEventData()),
                                           event: .initiateSignUpSuccessEvent,
                                           expected: .signingUpInitiated(username: "", response: SignUpOutputResponse()))
        sequence.assertResolvesToExpected()
    }

    func testSignUpInitiatingSigningUpFailureResolver() throws {
        let sequence = SignUpStateSequence(oldState: .initiatingSigningUp(SignUpEventData()),
                                           event: .initiateSignUpFailureEvent,
                                           expected: .error(.invalidUsername(message: "")))
        sequence.assertResolvesToExpected()
    }

    func testInitiatingSigningUpDispatcher() throws {
        let exp = expectation(description: #function)

        let username = "bob"
        let password = "yearandmydogsname"

        let signUpCallback: MockIdentityProvider.MockSignUpResponse = { _ in
            exp.fulfill()
            return SignUpOutputResponse(userConfirmed: false, userSub: username)
        }

        let cognitoUserPoolFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(mockSignUpResponse: signUpCallback)
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: cognitoUserPoolFactory,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF)
        let signUpEventData = SignUpEventData(username: username,
                                              password: password,
                                              attributes: [:])
        let action = InitiateSignUp(signUpEventData: signUpEventData)

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignUpEvent else {
                XCTFail("Expected event to be SignUpEvent but got \(event)")
                return
            }

            if case .initiateSignUp(let signUpEventData) = event.eventType {
                XCTAssertEqual(username, signUpEventData.username)
                XCTAssertEqual(password, signUpEventData.password)
            }
        }

        action.execute(withDispatcher: dispatcher, environment: environment)

        wait(for: [exp], timeout: 1.0)
    }

}
