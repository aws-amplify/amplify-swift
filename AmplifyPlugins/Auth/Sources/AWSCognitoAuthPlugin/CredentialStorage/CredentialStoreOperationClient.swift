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
    
    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData
    func storeData(data: CredentialStoreData) async throws
    func deleteData(type: CredentialStoreDataType) async throws
    
}

class CredentialStoreOperationClient: CredentialStoreStateBehaviour {
    
    var credentialStoreStateListenerToken: CredentialStoreStateMachine.StateChangeListenerToken!
    let credentialStoreStateMachine: CredentialStoreStateMachine
    
    init(credentialStoreStateMachine: CredentialStoreStateMachine) {
        self.credentialStoreStateMachine = credentialStoreStateMachine
    }
    
    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
        let credentialStoreEvent = CredentialStoreEvent(
            eventType: .loadCredentialStore(type))
        return try await sendEventAndListenToStateChanges(event: credentialStoreEvent)
    }
    
    func storeData(data: CredentialStoreData) async throws {
        let credentialStoreEvent = CredentialStoreEvent(
            eventType: .storeCredentials(data))
        _ = try await sendEventAndListenToStateChanges(event: credentialStoreEvent)
    }
    
    func deleteData(type: CredentialStoreDataType) async throws {
        let credentialStoreEvent = CredentialStoreEvent(
            eventType: .clearCredentialStore(type))
        _ = try await sendDeleteEventAndListenToStateChanges(event: credentialStoreEvent)
    }
    
    func sendEventAndListenToStateChanges(event: CredentialStoreEvent) async throws -> CredentialStoreData {
        let credentials: CredentialStoreData = try await withCheckedThrowingContinuation({ continuation in
            self.credentialStoreStateListenerToken = credentialStoreStateMachine.listen { state in
                
                switch state {
                case .success(let credentialStoreData):
                    continuation.resume(returning: credentialStoreData)
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
    
    func sendDeleteEventAndListenToStateChanges(event: CredentialStoreEvent) async throws {
        try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<Void, Error>) -> Void in
            self.credentialStoreStateListenerToken = credentialStoreStateMachine.listen { state in
                
                switch state {
                case .clearedCredential:
                    continuation.resume()
                case .error(let error):
                    continuation.resume(throwing: error)
                default: break
                }
            } onSubscribe: {
                self.credentialStoreStateMachine.send(event)
            }
        })
        credentialStoreStateMachine.cancel(listenerToken: self.credentialStoreStateListenerToken)
    }
}
