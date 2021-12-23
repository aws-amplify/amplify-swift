//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

struct MigrateLegacyCredentialStore: Command {

    let identifier = "MigrateLegacyCredentialStore"

    let authConfiguration: AuthConfiguration

    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
  
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        //TODO: complete the implementation

        
        let event = CredentialStoreEvent(eventType: .loadCredentialStore(authConfiguration))

        timer.stop("### sending event \(event.type)")
        dispatcher.send(event)
    }
}

extension MigrateLegacyCredentialStore: DefaultLogger { }

extension MigrateLegacyCredentialStore: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension MigrateLegacyCredentialStore: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
