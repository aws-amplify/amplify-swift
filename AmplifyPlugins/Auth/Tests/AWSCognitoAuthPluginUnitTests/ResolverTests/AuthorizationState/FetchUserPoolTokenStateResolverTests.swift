//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

typealias FetchUserPoolTokenStateSequence = StateSequence<FetchUserPoolTokensState, FetchUserPoolTokensEvent>

extension FetchUserPoolTokenStateSequence {
    init(oldState: MyState,
         event: MyEvent,
         expected: MyState
    ) {
        self.resolver = FetchUserPoolTokensState.Resolver().logging().eraseToAnyResolver()
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }
}

class FetchUserPoolTokenStateResolverTests: XCTestCase {

    func testValidFetchUserPoolTokenStateSequences() throws {
        let authorizationError = AuthorizationError.configuration(message: "someError")
        let cognitoSession = AWSAuthCognitoSession.testData

        let validSequences: [FetchUserPoolTokenStateSequence] = [
            FetchUserPoolTokenStateSequence(oldState: .configuring,
                                            event: FetchUserPoolTokensEvent(eventType: .refresh(cognitoSession)),
                                            expected: .refreshing),
            FetchUserPoolTokenStateSequence(oldState: .configuring,
                                            event: FetchUserPoolTokensEvent(eventType: .fetched),
                                            expected: .fetched),
            FetchUserPoolTokenStateSequence(oldState: .refreshing,
                                            event: FetchUserPoolTokensEvent(eventType: .fetched),
                                            expected: .fetched),
            FetchUserPoolTokenStateSequence(oldState: .refreshing,
                                            event: FetchUserPoolTokensEvent(eventType: .throwError(authorizationError)),
                                            expected: .error(authorizationError))
        ]

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }
}
