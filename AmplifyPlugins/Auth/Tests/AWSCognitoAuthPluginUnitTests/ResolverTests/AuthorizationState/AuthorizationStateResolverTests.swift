//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

typealias AuthorizationStateSequence = StateSequence<AuthorizationState, AuthorizationEvent>

extension AuthorizationStateSequence {
    init(oldState: MyState,
         event: MyEvent,
         expected: MyState
    ) {
        self.resolver = AuthorizationState.Resolver().logging().eraseToAnyResolver()
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }
}
class AuthorizationStateResolverTests: XCTestCase {
    
    func testValidAuthorizationStateSequences() throws {
        let sessionData = AWSAuthCognitoSession.testData
        let authorizationError = AuthorizationError.configuration(message: "someError")
        let validSequences: [AuthorizationStateSequence] = [
            AuthorizationStateSequence(oldState: .notConfigured,
                                       event: AuthorizationEvent(eventType: .configure(AuthConfiguration.testData)),
                                       expected: .configured),
            AuthorizationStateSequence(oldState: .configured,
                                       event: AuthorizationEvent(eventType: .fetchAuthSession),
                                       expected: .fetchingAuthSession(FetchAuthSessionState.initializingFetchAuthSession)),
            AuthorizationStateSequence(oldState: .fetchingAuthSession(FetchAuthSessionState.initializingFetchAuthSession),
                                       event: AuthorizationEvent(eventType: .fetchedAuthSession(sessionData)),
                                       expected: .sessionEstablished(sessionData)),
            AuthorizationStateSequence(oldState: .notConfigured,
                                       event: AuthorizationEvent(eventType: .throwError(authorizationError)),
                                       expected: .error(authorizationError))
        ]
        
        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }
    
    func testInvalidAuthorizationStateSequences() throws {
        let sessionData = AWSAuthCognitoSession.testData
        let authorizationError = AuthorizationError.configuration(message: "someError")
        let invalidSequences: [AuthorizationStateSequence] = [
            AuthorizationStateSequence(oldState: .notConfigured,
                                       event: AuthorizationEvent(eventType: .fetchAuthSession),
                                       expected: .fetchingAuthSession(FetchAuthSessionState.initializingFetchAuthSession)),
            AuthorizationStateSequence(oldState: .notConfigured,
                                       event: AuthorizationEvent(eventType: .fetchedAuthSession(sessionData)),
                                       expected: .sessionEstablished(sessionData)),
            AuthorizationStateSequence(oldState: .notConfigured,
                                       event: AuthorizationEvent(eventType: .throwError(authorizationError)),
                                       expected: .configured),
            AuthorizationStateSequence(oldState: .configured,
                                       event: AuthorizationEvent(eventType: .fetchAuthSession),
                                       expected: .notConfigured),
            AuthorizationStateSequence(oldState: .configured,
                                       event: AuthorizationEvent(eventType: .fetchedAuthSession(sessionData)),
                                       expected: .notConfigured),
            AuthorizationStateSequence(oldState: .configured,
                                       event: AuthorizationEvent(eventType: .throwError(authorizationError)),
                                       expected: .notConfigured)
        ]
        
        for sequence in invalidSequences {
            sequence.assertNotResolvesToExpected()
        }
    }
    
}
