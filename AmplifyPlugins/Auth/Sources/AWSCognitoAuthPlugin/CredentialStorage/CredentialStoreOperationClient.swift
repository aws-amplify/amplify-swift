//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Security

protocol CredentialStoreStateBehaviour {

    func fetchData(type: CredentialStoreRetrievalDataType) async throws -> CredentialStoreData
    func storeData(data: CredentialStoreData) async throws
    func deleteData(type: CredentialStoreRetrievalDataType) async throws

}

class CredentialStoreOperationClient: CredentialStoreStateBehaviour {

    var credentialStoreStateListenerToken: CredentialStoreStateMachine.StateChangeListenerToken!
    let credentialStoreStateMachine: CredentialStoreStateMachine

    init(credentialStoreStateMachine: CredentialStoreStateMachine) {
        self.credentialStoreStateMachine = credentialStoreStateMachine
    }

    func fetchData(type: CredentialStoreRetrievalDataType) async throws -> CredentialStoreData {
        let credentialStoreEvent = CredentialStoreEvent(
            eventType: .loadCredentialStore(type))
        return try await sendEventAndListenToStateChanges(event: credentialStoreEvent)
    }

    func storeData(data: CredentialStoreData) async throws {
        let credentialStoreEvent = CredentialStoreEvent(
            eventType: .storeCredentials(data))
        _ = try await sendEventAndListenToStateChanges(event: credentialStoreEvent)
    }

    func deleteData(type: CredentialStoreRetrievalDataType) async throws {
        let credentialStoreEvent = CredentialStoreEvent(
            eventType: .clearCredentialStore(type))
        _ = try await sendEventAndListenToStateChanges(event: credentialStoreEvent)
    }

    func sendEventAndListenToStateChanges(event: CredentialStoreEvent) async throws -> CredentialStoreData {
        let credentials: CredentialStoreData = try await withCheckedThrowingContinuation({ continuation in
            self.credentialStoreStateListenerToken = credentialStoreStateMachine.listen { state in

                switch state {
                case .success(let credentialStoreData):

                    switch credentialStoreData {
                    case .amplifyCredentials(let credentials):
                        continuation.resume(returning: .amplifyCredentials(credentials))
                    case .deviceMetadata(let deviceMetadata, let username):
                        continuation.resume(returning: .deviceMetadata(deviceMetadata, username))
                    }

                case .error(let error):
                    continuation.resume(throwing: error)

                default: break
                }
            } onSubscribe: {
                self.credentialStoreStateMachine.send(event)
            }
        })
        credentialStoreStateMachine.cancel(listenerToken: self.credentialStoreStateListenerToken)

        return credentials
    }
}
