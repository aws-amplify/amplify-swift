//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct LoadCredentialStore: Action {

    let identifier = "LoadCredentialStore"

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        let timer = LoggingTimer(identifier).start("### Starting execution")

        guard let credentialEnvironment = environment as? CredentialEnvironment else {
            let event = CredentialStoreEvent(
                eventType: .throwError(CredentialStoreError.configuration(
                    message: AuthPluginErrorConstants.configurationError)))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
            return
        }

        let credentialStoreEnvironment = credentialEnvironment.credentialStoreEnvironment
        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()

        do {
            let storedCredentials = try amplifyCredentialStore.retrieveCredential()
            let event = CredentialStoreEvent(eventType: .completedOperation(storedCredentials))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
        } catch let error as CredentialStoreError {
            let event = CredentialStoreEvent(eventType: .throwError(error))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
        } catch {
            let event = CredentialStoreEvent(
                eventType: .throwError(CredentialStoreError.unknown("An unknown error occurred", error)))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
        }

    }
}

extension LoadCredentialStore: DefaultLogger { }

extension LoadCredentialStore: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension LoadCredentialStore: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
