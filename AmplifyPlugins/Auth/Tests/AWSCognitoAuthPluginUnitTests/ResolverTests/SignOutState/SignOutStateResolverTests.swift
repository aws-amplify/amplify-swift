//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

typealias SignOutStateSequence = StateSequence<SignOutState, SignOutEvent>

extension SignOutStateSequence {
    init(oldState: MyState,
         event: MyEvent,
         expected: MyState
    ) {
        self.resolver = SignOutState.Resolver().logging().eraseToAnyResolver()
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }
}

class SignOutStateResolverTests: XCTestCase {
    func testValidSignOutStateSequences() throws {
        let validSequences: [SignOutStateSequence] = [
            SignOutStateSequence(
                oldState: .notStarted,
                event: SignOutEvent(eventType: .signOutGlobally(.testData)),
                expected: .signingOutGlobally),
            SignOutStateSequence(
                oldState: .notStarted,
                event: SignOutEvent(eventType: .revokeToken(.testData)),
                expected: .revokingToken),
            SignOutStateSequence(
                oldState: .signingOutGlobally,
                event: SignOutEvent(eventType: .revokeToken(.testData)),
                expected: .revokingToken),
            SignOutStateSequence(
                oldState: .signingOutGlobally,
                event: SignOutEvent(eventType: .signedOutFailure(.testData)),
                expected: .error(.testData)),
            SignOutStateSequence(
                oldState: .revokingToken,
                event: SignOutEvent(eventType: .signOutLocally(.testData)),
                expected: .signingOutLocally(.testData)),
            SignOutStateSequence(
                oldState: .revokingToken,
                event: SignOutEvent(eventType: .signedOutFailure(.testData)),
                expected: .error(.testData))
        ]

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }

}
