//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@_spi(KeychainStore) import AWSPluginsCore

protocol CredentialStoreStateBehavior {

    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData
    func storeData(data: CredentialStoreData) async throws
    func deleteData(type: CredentialStoreDataType) async throws

}

class CredentialStoreOperationClient: CredentialStoreStateBehavior {

    private let credentialStoreStateMachine: CredentialStoreStateMachine

    // Task queue is being used to manage CRUD operations to the credential store synchronously
    // This will help us keeping the CRUD methods atomic
    private let taskQueue = TaskQueue<CredentialStoreData?>()

    init(credentialStoreStateMachine: CredentialStoreStateMachine) {
        self.credentialStoreStateMachine = credentialStoreStateMachine
    }

    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
        guard let credentialStoreData = try await taskQueue.sync(block: {
            await self.waitForValidState()
            let credentialStoreEvent = CredentialStoreEvent(
                eventType: .loadCredentialStore(type))
            return try await self.sendEventAndListenToStateChanges(event: credentialStoreEvent)
        }) else {
            throw KeychainStoreError.itemNotFound
        }
        return credentialStoreData
    }

    func storeData(data: CredentialStoreData) async throws {
        _ = try await taskQueue.sync {
            await self.waitForValidState()
            let credentialStoreEvent = CredentialStoreEvent(
                eventType: .storeCredentials(data))
            return try await self.sendEventAndListenToStateChanges(event: credentialStoreEvent)
        }
    }

    func deleteData(type: CredentialStoreDataType) async throws {
        _ = try await taskQueue.sync {
            await self.waitForValidState()
            let credentialStoreEvent = CredentialStoreEvent(
                eventType: .clearCredentialStore(type))
            try await self.sendDeleteEventAndListenToStateChanges(event: credentialStoreEvent)
            return nil
        }
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
