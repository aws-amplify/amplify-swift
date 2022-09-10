//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

struct RevokeToken: Action {

    var identifier: String = "RevokeToken"
    let signedInData: SignedInData
    let hostedUIError: AWSCognitoHostedUIError?
    let globalSignOutError: AWSCognitoGlobalSignOutError?

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
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

        logVerbose("\(#fileID) Starting revoke token api", environment: environment)
        let clientId = environment.userPoolConfiguration.clientId
        let clientSecret = environment.userPoolConfiguration.clientSecret
        let refreshToken = signedInData.cognitoUserPoolTokens.refreshToken

        let input = RevokeTokenInput(clientId: clientId, clientSecret: clientSecret, token: refreshToken)
        do {
            _ = try await client.revokeToken(input: input)
            logVerbose("\(#fileID) Revoke token succeeded", environment: environment)
            await invokeNextStep(with: nil, dispatcher: dispatcher, environment: environment)
        } catch {
            logVerbose("\(#fileID) Revoke token failed \(error)", environment: environment)
            await invokeNextStep(with: error, dispatcher: dispatcher, environment: environment)
        }

    }

    func invokeNextStep(with error: Error?, dispatcher: EventDispatcher, environment: Environment) async {
        var revokeTokenError: AWSCognitoRevokeTokenError?
        if let authErrorConvertible = error as? AuthErrorConvertible {
            let internalError = authErrorConvertible.authError
            revokeTokenError = AWSCognitoRevokeTokenError(
                refreshToken: signedInData.cognitoUserPoolTokens.refreshToken,
                error: internalError)
        } else if let error = error {
            let internalError = AuthError.service("", "", error)
            revokeTokenError = AWSCognitoRevokeTokenError(
                refreshToken: signedInData.cognitoUserPoolTokens.refreshToken,
                error: internalError)
        }

        let event = SignOutEvent(eventType: .signOutLocally(
            signedInData,
            hostedUIError: hostedUIError,
            globalSignOutError: globalSignOutError,
            revokeTokenError: revokeTokenError))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
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
