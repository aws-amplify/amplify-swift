//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ClearCredentialStore: Action {

    let identifier = "ClearCredentialStore"

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
            try amplifyCredentialStore.deleteCredential()
            let event = CredentialStoreEvent(eventType: .completedOperation(nil))
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

extension ClearCredentialStore: DefaultLogger { }

extension ClearCredentialStore: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ClearCredentialStore: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
