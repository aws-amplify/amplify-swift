//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package enum CredentialStoreData: Codable, Equatable {
    case amplifyCredentials(AmplifyCredentials)
    case deviceMetadata(DeviceMetadata, Username)
    case asfDeviceId(String, Username)
}

package enum CredentialStoreDataType: Codable, Equatable {
    case amplifyCredentials
    case deviceMetadata(username: String)
    case asfDeviceId(username: String)
}

package struct CredentialStoreEvent: StateMachineEvent {

    // `Sendable` because the enclosing event conforms to `StateMachineEvent`, which is `Sendable`.
    package enum EventType: Equatable, Sendable {

        case migrateLegacyCredentialStore

        case loadCredentialStore(CredentialStoreDataType)

        case storeCredentials(CredentialStoreData)

        case clearCredentialStore(CredentialStoreDataType)

        case completedOperation(CredentialStoreData)

        case credentialCleared(CredentialStoreDataType)

        case throwError(EngineCredentialStoreError)

        case moveToIdleState

    }

    package let id: String
    package let eventType: EventType
    package let time: Date?

    package var type: String {
        switch eventType {
        case .migrateLegacyCredentialStore: return  "CredentialStoreEvent.migrateLegacyCredentialStore"
        case .loadCredentialStore: return  "CredentialStoreEvent.loadCredentialStore"
        case .storeCredentials: return  "CredentialStoreEvent.saveCredentials"
        case .credentialCleared: return  "CredentialStoreEvent.credentialCleared"
        case .clearCredentialStore: return  "CredentialStoreEvent.clearCredentialStore"
        case .completedOperation: return  "CredentialStoreEvent.completedOperation"
        case .throwError: return  "CredentialStoreEvent.throwError"
        case .moveToIdleState: return  "CredentialStoreEvent.moveToIdleState"
        }
    }

    package init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}
