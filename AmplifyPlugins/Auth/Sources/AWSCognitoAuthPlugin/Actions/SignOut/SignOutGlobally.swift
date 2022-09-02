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

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? UserPoolEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = SignOutEvent(id: UUID().uuidString, eventType: .signedOutFailure(error))
            await dispatcher.send(event)
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            return
        }

        let client: CognitoUserPoolBehavior
        do {
            client = try environment.cognitoUserPoolFactory()
        } catch {
            let authError = AuthenticationError.configuration(message: "Failed to get CognitoUserPool client: \(error)")
            let event = SignOutEvent(eventType: .signedOutFailure(authError))
            await dispatcher.send(event)
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            return
        }

        logVerbose("\(#fileID) Starting Global signOut", environment: environment)
        let input = GlobalSignOutInput(accessToken: signedInData.cognitoUserPoolTokens.accessToken)

        do {
            _ = try await client.globalSignOut(input: input)
            // Log the result, but proceed to attempt to revoke tokens regardless of globalSignOut result.
            logVerbose("\(#fileID) Global SignOut success", environment: environment)
        } catch {
            logVerbose("\(#fileID) Global SignOut failed \(error)", environment: environment)
        }
        let event = SignOutEvent(eventType: .revokeToken(signedInData))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
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
