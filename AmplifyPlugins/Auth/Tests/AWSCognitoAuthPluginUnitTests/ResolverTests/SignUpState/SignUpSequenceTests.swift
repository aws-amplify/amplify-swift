//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

import AWSCognitoIdentityProvider

typealias SignUpStateSequence = StateSequence<SignUpState, SignUpEvent>

extension SignUpStateSequence {
    init(oldState: MyState,
         event: MyEvent,
         expected: MyState
    ) {
        self.resolver = SignUpState.Resolver().logging().eraseToAnyResolver()
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }
}

extension SignUpEventData {
    init() {
        self.init(username: "", password: "")
    }
}

extension ConfirmSignUpEventData {
    init() {
        self.init(username: "", confirmationCode: "")
    }
}

class SignUpSequenceTests: XCTestCase {
    func testValidSignUpSequences() throws {
        let validSequences: [SignUpStateSequence] = [
            StateSequence(oldState: .notStarted,
                          event: .initiateSignUpEvent,
                          expected: .initiatingSigningUp(SignUpEventData())),
            StateSequence(oldState: .signingUpInitiated,
                          event: .initiateSignUpSuccessEvent,
                          expected: .signingUpInitiated),
            StateSequence(oldState: .initiatingSigningUp(SignUpEventData()),
                          event: .initiateSignUpFailureEvent,
                          expected: .error(.invalidUsername(message: ""))),
            StateSequence(oldState: .confirmingSignUp(ConfirmSignUpEventData()),
                          event: .confirmSignUpEvent,
                          expected: .confirmingSignUp(ConfirmSignUpEventData())),
            StateSequence(oldState: .confirmingSignUp(ConfirmSignUpEventData()),
                          event: .confirmSignUpSuccessEvent,
                          expected: .signedUp),
            StateSequence(oldState: .confirmingSignUp(ConfirmSignUpEventData()),
                          event: .confirmSignUpFailureEvent,
                          expected: .error(.invalidConfirmationCode(message: "")))
        ]

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }

    func testInvalidSignUpSequences() throws {
        let invalidSequences: [SignUpStateSequence] = [
            SignUpStateSequence(oldState: .notStarted,
                                event: .confirmSignUpEvent,
                                expected: .initiatingSigningUp(SignUpEventData())),
            SignUpStateSequence(oldState: .confirmingSignUp(ConfirmSignUpEventData()),
                                event: .confirmSignUpSuccessEvent,
                                expected: .error(.invalidPassword(message: ""))),
            SignUpStateSequence(oldState: .confirmingSignUp(ConfirmSignUpEventData()),
                                event: .confirmSignUpFailureEvent,
                                expected: .signedUp)
        ]

        for sequence in invalidSequences {
            sequence.assertNotResolvesToExpected()
        }
    }
}
