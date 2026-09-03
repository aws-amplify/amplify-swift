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

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class FetchAuthSessionStateResolverTests: XCTestCase, @unchecked Sendable {

    func testValidFetchAuthSessionStateSequences() throws {

        let validSequences: [FetchAuthSessionStateSequence] = []

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }

}
