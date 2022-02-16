//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

typealias FetchIdentityStateSequence = StateSequence<FetchIdentityState, FetchIdentityEvent>

extension FetchIdentityStateSequence {
    init(oldState: MyState,
         event: MyEvent,
         expected: MyState
    ) {
        self.resolver = FetchIdentityState.Resolver().logging().eraseToAnyResolver()
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }
}

class FetchIdentityStateResolverTests: XCTestCase {
    func testValidFetchIdentityStateSequences() throws {
        let authorizationError = AuthorizationError.configuration(message: "someError")

        let validSequences: [FetchIdentityStateSequence] = [
            FetchIdentityStateSequence(oldState: .configuring,
                                       event: FetchIdentityEvent(eventType: .fetch(AWSAuthCognitoSession.testData)),
                                       expected: .fetching),
            FetchIdentityStateSequence(oldState: .configuring,
                                       event: FetchIdentityEvent(eventType: .fetched),
                                       expected: .fetched),
            FetchIdentityStateSequence(oldState: .fetching,
                                       event: FetchIdentityEvent(eventType: .fetched),
                                       expected: .fetched),
            FetchIdentityStateSequence(oldState: .fetching,
                                       event: FetchIdentityEvent(eventType: .throwError(authorizationError)),
                                       expected: .error(authorizationError))
        ]

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }

}
