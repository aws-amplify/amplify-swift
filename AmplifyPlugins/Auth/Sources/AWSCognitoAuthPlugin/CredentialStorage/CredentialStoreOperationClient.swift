//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@_spi(KeychainStore) import AWSPluginsCore

protocol CredentialStoreStateBehaviour {
    
    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData
    func storeData(data: CredentialStoreData) async throws
    func deleteData(type: CredentialStoreDataType) async throws
    
}

class CredentialStoreOperationClient: CredentialStoreStateBehaviour {

    let credentialStoreStateMachine: CredentialStoreStateMachine
    
    init(credentialStoreStateMachine: CredentialStoreStateMachine) {
        self.credentialStoreStateMachine = credentialStoreStateMachine
    }
    
    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
        await waitForValidState()
        let credentialStoreEvent = CredentialStoreEvent(
            eventType: .loadCredentialStore(type))
        return try await sendEventAndListenToStateChanges(event: credentialStoreEvent)
    }
    
    func storeData(data: CredentialStoreData) async throws {
        await waitForValidState()
        let credentialStoreEvent = CredentialStoreEvent(
            eventType: .storeCredentials(data))
        _ = try await sendEventAndListenToStateChanges(event: credentialStoreEvent)
    }
    
    func deleteData(type: CredentialStoreDataType) async throws {
        await waitForValidState()
        let credentialStoreEvent = CredentialStoreEvent(
            eventType: .clearCredentialStore(type))
        _ = try await sendDeleteEventAndListenToStateChanges(event: credentialStoreEvent)
    }
    
    func sendEventAndListenToStateChanges(event: CredentialStoreEvent) async throws -> CredentialStoreData {
        let stateSequences = await credentialStoreStateMachine.listen()
        await credentialStoreStateMachine.send(event)
        for await state in stateSequences {
            switch state {
            case .success(let credentialStoreData):
                return credentialStoreData
            case .error(let error):
                throw error
            default: continue
            }
        }
        throw KeychainStoreError.unknown("Could not complete the operation")
    }
    
    func sendDeleteEventAndListenToStateChanges(event: CredentialStoreEvent) async throws {

        let stateSequences = await credentialStoreStateMachine.listen()
        await credentialStoreStateMachine.send(event)
        for await state in stateSequences {
            switch state {
            case .clearedCredential:
                return
            case .error(let error):
                throw error
            default: continue
            }
        }
    }

    func waitForValidState() async {
        let stateSequences = await credentialStoreStateMachine.listen()

        for await state in stateSequences {
            switch state {
            case .idle, .notConfigured:
                return
            default: continue
            }
        }
    }
    
}
