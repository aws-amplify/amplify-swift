//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ClearCredentialStore: Action {

    let identifier = "ClearCredentialStore"

    let dataStoreType: CredentialStoreDataType

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        guard let credentialEnvironment = environment as? CredentialEnvironment else {
            let event = CredentialStoreEvent(
                eventType: .throwError(CredentialStoreError.configuration(
                    message: AuthPluginErrorConstants.configurationError)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
            return
        }
        let credentialStoreEnvironment = credentialEnvironment.credentialStoreEnvironment
        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()

        do {

            let credentialStoreData: CredentialStoreData
            switch dataStoreType {
            case .amplifyCredentials:
                try amplifyCredentialStore.deleteCredential()
                credentialStoreData = .amplifyCredentials(.noCredentials)
            case .deviceMetadata(let username):
                try amplifyCredentialStore.removeDevice(for: username)
                credentialStoreData = .deviceMetadata(.noData, username)
            }

            let event = CredentialStoreEvent(
                eventType: .completedOperation(credentialStoreData))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        } catch let error as CredentialStoreError {
            let event = CredentialStoreEvent(eventType: .throwError(error))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        } catch {
            let event = CredentialStoreEvent(
                eventType: .throwError(CredentialStoreError.unknown("An unknown error occurred", error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }

    }

}

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
