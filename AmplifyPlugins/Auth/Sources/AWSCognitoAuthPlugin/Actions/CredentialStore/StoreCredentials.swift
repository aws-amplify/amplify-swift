//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct StoreCredentials: Action {

    let identifier = "StoreCredentials"

    let credentials: CredentialStoreData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let credentialEnvironment = environment as? CredentialEnvironment else {
            let event = CredentialStoreEvent(
                eventType: .throwError(KeychainStoreError.configuration(
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
                try amplifyCredentialStore.saveDevice(deviceMetadata, for: username)
            case .asfDeviceId(let deviceId, let username):
                try amplifyCredentialStore.saveASFDevice(deviceId, for: username)
            }

            let event = CredentialStoreEvent(
                eventType: .completedOperation(credentials))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch let error as KeychainStoreError {
            let event = CredentialStoreEvent(eventType: .throwError(error))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch {
            let event = CredentialStoreEvent(
                eventType: .throwError(KeychainStoreError.unknown("An unknown error occurred", error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        }

    }

}

extension StoreCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension StoreCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
