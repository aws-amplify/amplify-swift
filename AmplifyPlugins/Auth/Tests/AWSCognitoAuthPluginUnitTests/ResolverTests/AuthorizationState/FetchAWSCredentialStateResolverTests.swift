//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

typealias FetchAWSCredentialStateSequence = StateSequence<FetchAWSCredentialsState, FetchAWSCredentialEvent>

extension FetchAWSCredentialStateSequence {
    init(oldState: MyState,
         event: MyEvent,
         expected: MyState
    ) {
        self.resolver = FetchAWSCredentialsState.Resolver().logging().eraseToAnyResolver()
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }
}

class FetchAWSCredentialStateResolverTests: XCTestCase {
    func testValidFetchAWSCredentialStateSequences() throws {
        let authorizationError = AuthorizationError.configuration(message: "someError")
        
        let validSequences: [FetchAWSCredentialStateSequence] = [
            FetchAWSCredentialStateSequence(oldState: .configuring,
                                            event: FetchAWSCredentialEvent(eventType: .fetch(AWSAuthCognitoSession.testData)),
                                            expected: .fetching),
            FetchAWSCredentialStateSequence(oldState: .configuring,
                                            event: FetchAWSCredentialEvent(eventType: .fetched),
                                            expected: .fetched),
            FetchAWSCredentialStateSequence(oldState: .fetching,
                                            event: FetchAWSCredentialEvent(eventType: .fetched),
                                            expected: .fetched),
            FetchAWSCredentialStateSequence(oldState: .fetching,
                                            event: FetchAWSCredentialEvent(eventType: .throwError(authorizationError)),
                                            expected: .error(authorizationError))
        ]
        
        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }
    
}
