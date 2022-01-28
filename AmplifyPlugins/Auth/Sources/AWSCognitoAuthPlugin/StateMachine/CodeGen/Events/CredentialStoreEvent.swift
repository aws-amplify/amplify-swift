//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct CredentialStoreEvent: StateMachineEvent {

    enum EventType: Equatable {

        case migrateLegacyCredentialStore(AuthConfiguration)
        case loadCredentialStore(AuthConfiguration)
        case successfullyLoadedCredentialStore(CognitoCredentials?)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .migrateLegacyCredentialStore: return  "CredentialStoreEvent.migrateLegacyCredentialStore"
        case .loadCredentialStore: return  "CredentialStoreEvent.loadCredentialStore"
        case .successfullyLoadedCredentialStore: return  "CredentialStoreEvent.successfullyLoadedCredentialStore"
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

