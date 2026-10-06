//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package struct SignOutGlobally: Action {

    package var identifier: String = "SignOutGlobally"
    package let signedInData: SignedInData
    package let hostedUIError: EngineHostedUISignOutFailure?

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? UserPoolEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            await invokeNextStep(with: error, dispatcher: dispatcher, environment: environment)
            return
        }

        let client: CognitoUserPoolBehavior
        do {
            client = try environment.cognitoUserPoolFactory()
        } catch {
            let authError = AuthenticationError.configuration(
                message: "Failed to get CognitoUserPool client: \(error)")
            await invokeNextStep(with: authError, dispatcher: dispatcher, environment: environment)
            return
        }

        logVerbose("\(#fileID) Starting Global signOut", environment: environment)
        let accessToken = signedInData.cognitoUserPoolTokens.accessToken
        let input = GlobalSignOutInput(accessToken: accessToken)

        do {
            _ = try await client.globalSignOut(input: input)
            logVerbose("\(#fileID) Global SignOut success", environment: environment)
            await invokeNextStep(with: nil, dispatcher: dispatcher, environment: environment)
        } catch {
            logVerbose("\(#fileID) Global SignOut failed \(error)", environment: environment)
            await invokeNextStep(with: error, dispatcher: dispatcher, environment: environment)
        }
    }

    package func invokeNextStep(with error: Error?, dispatcher: EventDispatcher, environment: Environment) async {
        var globalSignOutError: EngineGlobalSignOutFailure?
        if let authErrorConvertible = error as? EngineAuthErrorConvertible {
            let internalError = authErrorConvertible.engineError
            globalSignOutError = EngineGlobalSignOutFailure(
                accessToken: signedInData.cognitoUserPoolTokens.accessToken,
                error: internalError
            )
        } else if let error {
            let internalError = EngineAuthError.service("", "", error)
            globalSignOutError = EngineGlobalSignOutFailure(
                accessToken: signedInData.cognitoUserPoolTokens.accessToken,
                error: internalError
            )
        }

        if let globalSignOutError {
            let event = SignOutEvent(eventType: .globalSignOutError(
                signedInData,
                globalSignOutError: globalSignOutError,
                hostedUIError: hostedUIError
            ))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
            return
        }

        let event = SignOutEvent(eventType: .revokeToken(
            signedInData,
            hostedUIError: hostedUIError
        ))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension SignOutGlobally: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signedInData": signedInData.debugDictionary
        ]
    }
}

extension SignOutGlobally: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
