//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct InitializeCredentialStoreConfiguration: Command {

    let identifier = "InitializeCredentialStoreConfiguration"

    let authConfiguration: AuthConfiguration

    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        // ATM this is a no-op command
        let timer = LoggingTimer(identifier).start("### Starting execution")
        let event = CredentialStoreEvent(eventType: .migrateLegacyCredentialStore(authConfiguration))
        timer.stop("### sending event \(event.type)")
        dispatcher.send(event)
    }
}

extension InitializeCredentialStoreConfiguration: DefaultLogger { }

extension InitializeCredentialStoreConfiguration: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension InitializeCredentialStoreConfiguration: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
