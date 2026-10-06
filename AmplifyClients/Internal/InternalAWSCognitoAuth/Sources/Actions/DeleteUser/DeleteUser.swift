//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package struct DeleteUser: Action {

    package var identifier: String = "DeleteUser"

    package let accessToken: String

    /// Passed on to the sign-out that follows a deletion (`DeleteUserEvent.signOutDeletedUser`).
    package var skipHostedUISignOut: Bool = false

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
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
            let event = SignOutEvent(id: UUID().uuidString, eventType: .signedOutFailure(authError))
            await dispatcher.send(event)
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            return
        }

        logVerbose("\(#fileID) Starting delete user api", environment: environment)

        let input = DeleteUserInput(accessToken: accessToken)
        Task {
            let event: DeleteUserEvent
            do {
                _ = try await client.deleteUser(input: input)
                event = DeleteUserEvent(eventType: .signOutDeletedUser(skipHostedUISignOut: skipHostedUISignOut))
                logVerbose("\(#fileID) Delete User succeeded", environment: environment)
            } catch let error as EngineAuthErrorConvertible {
                event = DeleteUserEvent(eventType: .throwError(error.engineError))
                logVerbose("\(#fileID) Delete User failed \(error)", environment: environment)
            } catch {
                let authError = EngineAuthError.service(
                    "Delete user failed with service error",
                    EngineErrorMessages.reportBugToAWS(),
                    error
                )
                event = DeleteUserEvent(eventType: .throwError(authError))
                logVerbose("\(#fileID) Delete user failed \(error)", environment: environment)
            }
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        }
    }
}

extension DeleteUser: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "accessToken": accessToken.maskedForLog()
        ]
    }
}

extension DeleteUser: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
