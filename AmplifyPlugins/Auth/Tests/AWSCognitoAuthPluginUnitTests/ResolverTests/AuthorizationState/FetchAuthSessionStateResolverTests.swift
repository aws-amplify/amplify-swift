//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

@testable import AWSCognitoAuthPlugin

typealias FetchAuthSessionStateSequence = StateSequence<FetchAuthSessionState, FetchAuthSessionEvent>

extension FetchAuthSessionStateSequence {
    init(
        oldState: MyState,
        event: MyEvent,
        expected: MyState
    ) {
        self.resolver = FetchAuthSessionState.Resolver().logging().eraseToAnyResolver()
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }
}

class FetchAuthSessionStateResolverTests: XCTestCase {

    func testValidFetchAuthSessionStateSequences() throws {

        let validSequences: [FetchAuthSessionStateSequence] = []

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }

}
