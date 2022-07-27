//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
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
        let credentialStoreError = KeychainStoreError.configuration(message: "someError")
        let testData = AmplifyCredentials.testData

        let validSequences: [CredentialStoreStateSequence] = [
            CredentialStoreStateSequence(
                oldState: .notConfigured,
                event: CredentialStoreEvent(eventType: .migrateLegacyCredentialStore),
                expected: .migratingLegacyStore),
            CredentialStoreStateSequence(
                oldState: .migratingLegacyStore,
                event: CredentialStoreEvent(eventType: .loadCredentialStore(.amplifyCredentials)),
                expected: .loadingStoredCredentials),
            CredentialStoreStateSequence(
                oldState: .loadingStoredCredentials,
                event: CredentialStoreEvent(eventType: .completedOperation(.amplifyCredentials(testData))),
                expected: .success(.amplifyCredentials(testData))),
            CredentialStoreStateSequence(
                oldState: .loadingStoredCredentials,
                event: CredentialStoreEvent(eventType: .throwError(credentialStoreError)),
                expected: .error(credentialStoreError)),
            CredentialStoreStateSequence(
                oldState: .clearingCredentials,
                event: CredentialStoreEvent(eventType: .completedOperation(.amplifyCredentials(testData))),
                expected: .success(.amplifyCredentials(testData))),
            CredentialStoreStateSequence(
                oldState: .clearingCredentials,
                event: CredentialStoreEvent(eventType: .throwError(credentialStoreError)),
                expected: .error(credentialStoreError)),
            CredentialStoreStateSequence(
                oldState: .storingCredentials,
                event: CredentialStoreEvent(eventType: .completedOperation(.amplifyCredentials(testData))),
                expected: .success(.amplifyCredentials(testData))),
            CredentialStoreStateSequence(
                oldState: .storingCredentials,
                event: CredentialStoreEvent(eventType: .throwError(credentialStoreError)),
                expected: .error(credentialStoreError)),
            CredentialStoreStateSequence(
                oldState: .success(.amplifyCredentials(testData)),
                event: CredentialStoreEvent(eventType: .loadCredentialStore(.amplifyCredentials)),
                expected: .success(.amplifyCredentials(testData))),
            CredentialStoreStateSequence(
                oldState: .success(.amplifyCredentials(testData)),
                event: CredentialStoreEvent(eventType: .storeCredentials(.amplifyCredentials(testData))),
                expected: .success(.amplifyCredentials(testData))),
            CredentialStoreStateSequence(
                oldState: .success(.amplifyCredentials(testData)),
                event: CredentialStoreEvent(eventType: .clearCredentialStore(.amplifyCredentials)),
                expected: .success(.amplifyCredentials(testData))),
            CredentialStoreStateSequence(
                oldState: .error(credentialStoreError),
                event: CredentialStoreEvent(eventType: .loadCredentialStore(.amplifyCredentials)),
                expected: .error(credentialStoreError)),
            CredentialStoreStateSequence(
                oldState: .error(credentialStoreError),
                event: CredentialStoreEvent(eventType: .storeCredentials(.amplifyCredentials(testData))),
                expected: .error(credentialStoreError)),
            CredentialStoreStateSequence(
                oldState: .error(credentialStoreError),
                event: CredentialStoreEvent(eventType: .clearCredentialStore(.amplifyCredentials)),
                expected: .error(credentialStoreError)),
            CredentialStoreStateSequence(
                oldState: .idle,
                event: CredentialStoreEvent(eventType: .loadCredentialStore(.amplifyCredentials)),
                expected: .loadingStoredCredentials),
            CredentialStoreStateSequence(
                oldState: .idle,
                event: CredentialStoreEvent(eventType: .storeCredentials(.amplifyCredentials(testData))),
                expected: .storingCredentials),
            CredentialStoreStateSequence(
                oldState: .idle,
                event: CredentialStoreEvent(eventType: .clearCredentialStore(.amplifyCredentials)),
                expected: .clearingCredentials)
        ]

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }

}
