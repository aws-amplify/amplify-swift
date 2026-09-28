//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The credential store machine. Declared here, next to its client, since it moved out of the plugin's
/// `Operations/Helpers/AmplifyOperationHelper.swift`.
package typealias CredentialStoreStateMachine = StateMachine<
    CredentialStoreState,
    CredentialEnvironment
>

/// - Note: `Sendable` because the plugin holds this across task boundaries; the concrete client
///   serializes all CRUD through an `EngineTaskQueue`.
package protocol CredentialStoreStateBehavior: Sendable {

    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData
    func storeData(data: CredentialStoreData) async throws
    func deleteData(type: CredentialStoreDataType) async throws

}

package final class CredentialStoreOperationClient: CredentialStoreStateBehavior {

    private let credentialStoreStateMachine: CredentialStoreStateMachine

    // Task queue is being used to manage CRUD operations to the credential store synchronously
    // This will help us keeping the CRUD methods atomic
    private let taskQueue = EngineTaskQueue<CredentialStoreData?>()

    package init(credentialStoreStateMachine: CredentialStoreStateMachine) {
        self.credentialStoreStateMachine = credentialStoreStateMachine
    }

    package func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
        guard let credentialStoreData = try await taskQueue.sync(block: {
            await self.waitForValidState()
            let credentialStoreEvent = CredentialStoreEvent(
                eventType: .loadCredentialStore(type))
            return try await self.sendEventAndListenToStateChanges(event: credentialStoreEvent)
        }) else {
            throw EngineCredentialStoreError.itemNotFound
        }
        return credentialStoreData
    }

    package func storeData(data: CredentialStoreData) async throws {
        _ = try await taskQueue.sync {
            await self.waitForValidState()
            let credentialStoreEvent = CredentialStoreEvent(
                eventType: .storeCredentials(data))
            return try await self.sendEventAndListenToStateChanges(event: credentialStoreEvent)
        }
    }

    package func deleteData(type: CredentialStoreDataType) async throws {
        _ = try await taskQueue.sync {
            await self.waitForValidState()
            let credentialStoreEvent = CredentialStoreEvent(
                eventType: .clearCredentialStore(type))
            try await self.sendDeleteEventAndListenToStateChanges(event: credentialStoreEvent)
            return nil
        }
    }

    package func sendEventAndListenToStateChanges(event: CredentialStoreEvent) async throws -> CredentialStoreData {
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
        throw EngineCredentialStoreError.unknown("Could not complete the operation")
    }

    package func sendDeleteEventAndListenToStateChanges(event: CredentialStoreEvent) async throws {

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

    package func waitForValidState() async {
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
