//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

struct SignOutGlobally: Action {

    var identifier: String = "SignOutGlobally"
    let signedInData: SignedInData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("Starting execution", environment: environment)

        guard let environment = environment as? UserPoolEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = SignOutEvent(id: UUID().uuidString, eventType: .signedOutFailure(error))
            dispatcher.send(event)
            logVerbose("Sending event \(event.type)", environment: environment)
            return
        }

        let client: CognitoUserPoolBehavior
        do {
            client = try environment.cognitoUserPoolFactory()
        } catch {
            let authError = AuthenticationError.configuration(message: "Failed to get CognitoUserPool client: \(error)")
            let event = SignOutEvent(eventType: .signedOutFailure(authError))
            dispatcher.send(event)
            logVerbose("Sending event \(event.type)", environment: environment)
            return
        }

        logVerbose("Starting Global signOut", environment: environment)
        let input = GlobalSignOutInput(accessToken: signedInData.cognitoUserPoolTokens.accessToken)

        client.globalSignOut(input: input) { result in
            // Log the result, but proceed to attempt to revoke tokens regardless of globalSignOut result.
            logVerbose("Global signOut response received", environment: environment)
            switch result {
            case .success:
                logVerbose("Global SignOut success", environment: environment)
            case .failure(let error):
                logVerbose("Global SignOut failed \(error)", environment: environment)
            }
            let event = SignOutEvent(eventType: .revokeToken(signedInData))
            dispatcher.send(event)
            logVerbose("Sending event \(event.type)", environment: environment)
        }
    }
}

extension SignOutGlobally: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signedInData": signedInData.debugDictionary
        ]
    }
}

extension SignOutGlobally: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

