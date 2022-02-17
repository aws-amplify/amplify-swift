//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

struct RevokeToken: Action {

    var identifier: String = "RevokeToken"
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
            let event = SignOutEvent(id: UUID().uuidString, eventType: .signedOutFailure(authError))
            dispatcher.send(event)
            logVerbose("Sending event \(event.type)", environment: environment)
            return
        }

        logVerbose("Starting revoke token api", environment: environment)
        let clientId = environment.userPoolConfiguration.clientId
        let clientSecret = environment.userPoolConfiguration.clientSecret
        let refreshToken = signedInData.cognitoUserPoolTokens.refreshToken

        let input = RevokeTokenInput(clientId: clientId, clientSecret: clientSecret, token: refreshToken)

        client.revokeToken(input: input) { result in
            // Log the result, but proceed to clear credential store regardless of revokeToken result.
            logVerbose("Revoke token response received", environment: environment)
            switch result {
            case .success:
                logVerbose("Revoke token succeedd", environment: environment)
            case .failure(let error):
                logVerbose("Revoke token failed \(error)", environment: environment)
            }
            let event = SignOutEvent(eventType: .signOutLocally(signedInData))
            logVerbose("Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }
    }
}

extension RevokeToken: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signedInData": signedInData.debugDictionary
        ]
    }
}

extension RevokeToken: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}


