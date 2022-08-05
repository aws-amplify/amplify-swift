//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

enum CredentialStoreData: Codable, Equatable {
    case amplifyCredentials(AmplifyCredentials)
    case deviceMetadata(DeviceMetadata, Username)
    case asfDeviceId(String, Username)
}

enum CredentialStoreDataType: Codable, Equatable {
    case amplifyCredentials
    case deviceMetadata(username: String)
    case asfDeviceId(username: String)
}

struct CredentialStoreEvent: StateMachineEvent {

    enum EventType: Equatable {

        case migrateLegacyCredentialStore

        case loadCredentialStore(CredentialStoreDataType)

        case storeCredentials(CredentialStoreData)

        case clearCredentialStore(CredentialStoreDataType)

        case completedOperation(CredentialStoreData)

        case credentialCleared(CredentialStoreDataType)

        case throwError(KeychainStoreError)

        case moveToIdleState

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
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

    init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}
