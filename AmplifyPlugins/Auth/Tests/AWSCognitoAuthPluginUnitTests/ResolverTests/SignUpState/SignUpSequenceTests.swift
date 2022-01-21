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

class SignUpSequenceTests: XCTestCase {
    func testValidSignUpSequences() throws {
        let validSequences: [SignUpStateSequence] = [
            StateSequence(oldState: .notStarted,
                          event: .initiateSignUpEvent,
                          expected: .initiatingSigningUp),
            StateSequence(oldState: .signingUpInitiated,
                          event: .initiateSignUpSuccessEvent,
                          expected: .signingUpInitiated),
            StateSequence(oldState: .initiatingSigningUp,
                          event: .initiateSignUpFailureEvent,
                          expected: .error),
            StateSequence(oldState: .confirmingSignUp,
                          event: .confirmSignUpEvent,
                          expected: .confirmingSignUp),
            StateSequence(oldState: .confirmingSignUp,
                          event: .confirmSignUpSuccessEvent,
                          expected: .signedUp),
            StateSequence(oldState: .confirmingSignUp,
                          event: .confirmSignUpFailureEvent,
                          expected: .error)
        ]

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }

    func testInvalidSignUpSequences() throws {
        let invalidSequences: [SignUpStateSequence] = [
            SignUpStateSequence(oldState: .notStarted,
                                event: .confirmSignUpEvent,
                                expected: .initiatingSigningUp),
            SignUpStateSequence(oldState: .confirmingSignUp,
                                event: .confirmSignUpSuccessEvent,
                                expected: .error),
            SignUpStateSequence(oldState: .confirmingSignUp,
                                event: .confirmSignUpFailureEvent,
                                expected: .signedUp)
        ]

        for sequence in invalidSequences {
            sequence.assertNotResolvesToExpected()
        }
    }
}
