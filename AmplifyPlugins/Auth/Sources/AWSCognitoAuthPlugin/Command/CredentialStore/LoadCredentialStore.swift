//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct LoadCredentialStore: Command {

    let identifier = "LoadCredentialStore"

    let authConfiguration: AuthConfiguration

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        let timer = LoggingTimer(identifier).start("### Starting execution")

        guard let credentialStoreEnvironment = (environment as? AuthEnvironment)?.credentialStoreEnvironment else {
            let event = CredentialStoreEvent(eventType: .loadCredentialStore(authConfiguration))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
            return
        }
        
        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()
        let storedCredentials = try? amplifyCredentialStore.retrieveCredential()
        
        let event = CredentialStoreEvent(eventType: .successfullyLoadedCredentialStore(storedCredentials))
        timer.stop("### sending event \(event.type)")
        dispatcher.send(event)

        dispatcher.send(generateConfigureAuthEvent(authConfiguration: authConfiguration))
    }

    private func generateConfigureAuthEvent(authConfiguration: AuthConfiguration) -> StateMachineEvent {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        var event: StateMachineEvent
        switch authConfiguration {
        case .identityPools:
            event = AuthEvent(eventType: .configureAuthorization(authConfiguration))
        default:
            event = AuthEvent(eventType: .configureAuthentication(authConfiguration))
        }
        timer.stop("### sending event \(event.type)")
        return event
    }
}

extension LoadCredentialStore: DefaultLogger { }

extension LoadCredentialStore: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension LoadCredentialStore: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
