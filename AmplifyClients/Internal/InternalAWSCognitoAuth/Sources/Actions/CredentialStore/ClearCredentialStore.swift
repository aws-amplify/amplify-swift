//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct ClearCredentialStore: Action {

    package let identifier = "ClearCredentialStore"

    package let dataStoreType: CredentialStoreDataType

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

            let dataType: CredentialStoreDataType
            switch dataStoreType {
            case .amplifyCredentials:
                try amplifyCredentialStore.deleteCredential()
                clearLegacyStores(for: credentialEnvironment, environment: environment)
                dataType = .amplifyCredentials
            case .deviceMetadata(let username):
                try await amplifyCredentialStore.removeDevice(for: username)
                dataType = .deviceMetadata(username: username)
            case .asfDeviceId(username: let username):
                try await amplifyCredentialStore.removeASFDevice(for: username)
                dataType = .asfDeviceId(username: username)
            }

            let event = CredentialStoreEvent(eventType: .credentialCleared(dataType))
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

    /// Clears the legacy (AWSMobileClient) stores once the session has been cleared, so that a legacy
    /// session kept for a later migration cannot come back after the user has signed out.
    ///
    /// Best effort: a failure is logged and never fails the clear, because the session itself is
    /// already gone. If a legacy store survives, the next migration still finds it; that is no worse
    /// than before this clear ran.
    private func clearLegacyStores(for credentialEnvironment: CredentialEnvironment, environment: Environment) {
        let credentialStoreEnvironment = credentialEnvironment.credentialStoreEnvironment
        let serviceKeys = MigrateLegacyCredentialStore.legacyServiceKeys(
            for: credentialEnvironment.authConfiguration
        )
        for serviceKey in serviceKeys {
            do {
                try credentialStoreEnvironment.legacyKeychainStore(serviceKey)._removeAll()
            } catch {
                let logger = (environment as? LoggerProvider)?.logger
                logger?.warn("\(#fileID) Unable to clear a legacy credential store: \(error)")
            }
        }
    }

}

extension ClearCredentialStore: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ClearCredentialStore: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
