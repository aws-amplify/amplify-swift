//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct LoadCredentialStore: Action {

    let identifier = "LoadCredentialStore"

    let credentialStoreType: CredentialStoreDataType

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let credentialEnvironment = environment as? CredentialEnvironment else {
            let event = CredentialStoreEvent(
                eventType: .throwError(KeychainStoreError.configuration(
                    message: AuthPluginErrorConstants.configurationError)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
            return
        }

        let credentialStoreEnvironment = credentialEnvironment.credentialStoreEnvironment
        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()

        do {
            let credentialStoreData: CredentialStoreData
            switch credentialStoreType {
            case .amplifyCredentials:
                let storedCredentials = try amplifyCredentialStore.retrieveCredential()
                credentialStoreData = .amplifyCredentials(storedCredentials)
            case .deviceMetadata(let username):
                let deviceMetadata = try amplifyCredentialStore.retrieveDevice(for: username)
                credentialStoreData = .deviceMetadata(deviceMetadata, username)
            case .asfDeviceId(let username):
                let deviceId = try amplifyCredentialStore.retrieveASFDevice(for: username)
                credentialStoreData = .asfDeviceId(deviceId, username)
            }

            let event = CredentialStoreEvent(
                eventType: .completedOperation(credentialStoreData))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        } catch let error as KeychainStoreError {
            let event = CredentialStoreEvent(eventType: .throwError(error))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        } catch {
            let event = CredentialStoreEvent(
                eventType: .throwError(
                    KeychainStoreError.unknown("An unknown error occurred", error)
                )
            )
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }

    }
}

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
