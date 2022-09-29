//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

@testable import AWSCognitoAuthPlugin

typealias FetchAuthSessionStateSequence = StateSequence<FetchAuthSessionState, FetchAuthSessionEvent>

extension FetchAuthSessionStateSequence {
    init(oldState: MyState,
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
//        let cognitoSession = AWSAuthCognitoSession.testData

        let validSequences: [FetchAuthSessionStateSequence] = [
//            StateSequence(oldState: .initializingFetchAuthSession,
//                          event: FetchAuthSessionEvent(eventType: .fetchIdentity(cognitoSession)),
//                          expected: .fetchingIdentity(FetchIdentityState.configuring)),
//            StateSequence(oldState: .initializingFetchAuthSession,
//                          event: FetchAuthSessionEvent(eventType: .fetchUserPoolTokens(cognitoSession)),
//                          expected: .fetchingUserPoolTokens(FetchUserPoolTokensState.configuring)),
//            StateSequence(oldState: .fetchingUserPoolTokens(FetchUserPoolTokensState.configuring),
//                          event: FetchAuthSessionEvent(eventType: .fetchIdentity(cognitoSession)),
//                          expected: .fetchingIdentity(FetchIdentityState.configuring)),
//            StateSequence(oldState: .fetchingIdentity(FetchIdentityState.configuring),
//                          event: FetchAuthSessionEvent(eventType: .fetchAWSCredentials(cognitoSession)),
//                          expected: .fetchingAWSCredentials(FetchAWSCredentialsState.configuring)),
//            StateSequence(oldState: .fetchingAWSCredentials(FetchAWSCredentialsState.fetched),
//                          event: FetchAuthSessionEvent(eventType: .fetchedAuthSession(cognitoSession)),
//                          expected: .sessionEstablished)
        ]

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }

}
