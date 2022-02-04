//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

typealias CredentialStoreStateSequence = StateSequence<CredentialStoreState, CredentialStoreEvent>

extension CredentialStoreStateSequence {
    init(oldState: MyState,
         event: MyEvent,
         expected: MyState
    ) {
        self.resolver = CredentialStoreState.Resolver().logging().eraseToAnyResolver()
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }
}

class CredentialStoreStateResolverTests: XCTestCase {
    func testValidCredentialStoreStateSequences() throws {
        let credentialStoreError = CredentialStoreError.configuration(message: "someError")
        let testData = CognitoCredentials.testData
        
        let validSequences: [CredentialStoreStateSequence] = [
            CredentialStoreStateSequence(
                oldState: .notConfigured,
                event: CredentialStoreEvent(eventType: .migrateLegacyCredentialStore),
                expected: .migratingLegacyStore),
            CredentialStoreStateSequence(
                oldState: .migratingLegacyStore,
                event: CredentialStoreEvent(eventType: .loadCredentialStore),
                expected: .loadingStoredCredentials),
            CredentialStoreStateSequence(
                oldState: .loadingStoredCredentials,
                event: CredentialStoreEvent(eventType: .completedOperation(testData)),
                expected: .idle(testData)),
            CredentialStoreStateSequence(
                oldState: .loadingStoredCredentials,
                event: CredentialStoreEvent(eventType: .throwError(credentialStoreError)),
                expected: .error(credentialStoreError)),
            CredentialStoreStateSequence(
                oldState: .clearingCredentials,
                event: CredentialStoreEvent(eventType: .completedOperation(testData)),
                expected: .idle(testData)),
            CredentialStoreStateSequence(
                oldState: .clearingCredentials,
                event: CredentialStoreEvent(eventType: .throwError(credentialStoreError)),
                expected: .error(credentialStoreError)),
            CredentialStoreStateSequence(
                oldState: .storingCredentials,
                event: CredentialStoreEvent(eventType: .completedOperation(testData)),
                expected: .idle(testData)),
            CredentialStoreStateSequence(
                oldState: .storingCredentials,
                event: CredentialStoreEvent(eventType: .throwError(credentialStoreError)),
                expected: .error(credentialStoreError)),
            CredentialStoreStateSequence(
                oldState: .idle(testData),
                event: CredentialStoreEvent(eventType: .loadCredentialStore),
                expected: .loadingStoredCredentials),
            CredentialStoreStateSequence(
                oldState: .idle(testData),
                event: CredentialStoreEvent(eventType: .storeCredentials(testData)),
                expected: .storingCredentials),
            CredentialStoreStateSequence(
                oldState: .idle(testData),
                event: CredentialStoreEvent(eventType: .clearCredentialStore),
                expected: .clearingCredentials),
            CredentialStoreStateSequence(
                oldState: .error(credentialStoreError),
                event: CredentialStoreEvent(eventType: .loadCredentialStore),
                expected: .loadingStoredCredentials),
            CredentialStoreStateSequence(
                oldState: .error(credentialStoreError),
                event: CredentialStoreEvent(eventType: .storeCredentials(testData)),
                expected: .storingCredentials),
            CredentialStoreStateSequence(
                oldState: .error(credentialStoreError),
                event: CredentialStoreEvent(eventType: .clearCredentialStore),
                expected: .clearingCredentials)
        ]
        
        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }
    
}
