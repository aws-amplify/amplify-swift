//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InitializeAuthConfiguration: Action {

    package let identifier = "InitializeAuthConfiguration"

    package let authConfiguration: AuthConfiguration

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        let authEnvironment = environment as? AuthEnvironment

        let credentialStoreClient = authEnvironment?.credentialsClient

        var credentials = AmplifyCredentials.noCredentials

        do {
            let data = try await credentialStoreClient?.fetchData(
                type: .amplifyCredentials)
            if case .amplifyCredentials(let fetchedCredentials) = data {
                credentials = fetchedCredentials
            }
        } catch EngineCredentialStoreError.itemNotFound {
            logInfo("No existing session found.", environment: environment)
        } catch {
            logError("Error when loading amplify credentials: \(error)", environment: environment)
        }

        let event = AuthEvent.init(
            eventType: .validateCredentialAndConfiguration(authConfiguration, credentials))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)

    }
}

extension InitializeAuthConfiguration: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension InitializeAuthConfiguration: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
