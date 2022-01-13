//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public struct CredentialStoreEvent: StateMachineEvent {

    public enum EventType: Equatable {

        case migrateLegacyCredentialStore(AuthConfiguration)
        case loadCredentialStore(AuthConfiguration)
        case successfullyLoadedCredentialStore(AuthConfiguration)
    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
        switch eventType {
        case .migrateLegacyCredentialStore: return  "CredentialStoreEvent.migrateLegacyCredentialStore"
        case .loadCredentialStore: return  "CredentialStoreEvent.loadCredentialStore"
        case .successfullyLoadedCredentialStore: return  "CredentialStoreEvent.successfullyLoadedCredentialStore"
        }
    }

    public init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}

