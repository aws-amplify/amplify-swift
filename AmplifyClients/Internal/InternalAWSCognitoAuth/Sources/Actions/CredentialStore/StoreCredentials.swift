//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct StoreCredentials: Action {

    package let identifier = "StoreCredentials"

    package let credentials: CredentialStoreData

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let credentialEnvironment = environment as? CredentialEnvironment else {
            let event = CredentialStoreEvent(
                eventType: .throwError(EngineCredentialStoreError.configuration(
                    message: AuthPluginErrorConstants.configurationError)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
            return
        }
        let credentialStoreEnvironment = credentialEnvironment.credentialStoreEnvironment
        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()

        do {

            switch credentials {
            case .amplifyCredentials(let amplifyCredentials):
                try amplifyCredentialStore.saveCredential(amplifyCredentials)
            case .deviceMetadata(let deviceMetadata, let username):
                try await amplifyCredentialStore.saveDevice(deviceMetadata, for: username)
            case .asfDeviceId(let deviceId, let username):
                try await amplifyCredentialStore.saveASFDevice(deviceId, for: username)
            }

            let event = CredentialStoreEvent(
                eventType: .completedOperation(credentials))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch let error as EngineCredentialStoreError {
            let event = CredentialStoreEvent(eventType: .throwError(error))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch {
            let event = CredentialStoreEvent(
                eventType: .throwError(EngineCredentialStoreError.unknown("An unknown error occurred", error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        }

    }

}

extension StoreCredentials: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension StoreCredentials: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
