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
}

enum CredentialStoreRetrievalDataType: Codable, Equatable {
    case amplifyCredentials
    case deviceMetadata(username: String)
}

struct CredentialStoreEvent: StateMachineEvent {

    enum EventType: Equatable {

        case migrateLegacyCredentialStore

        case loadCredentialStore(CredentialStoreRetrievalDataType)

        case storeCredentials(CredentialStoreData)

        case clearCredentialStore(CredentialStoreRetrievalDataType)

        case completedOperation(CredentialStoreData)

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
