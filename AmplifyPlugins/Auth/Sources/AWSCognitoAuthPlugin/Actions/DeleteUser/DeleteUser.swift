//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct DeleteUser: Action {

    var identifier: String = "DeleteUser"
    
    let accessToken: String

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        
        guard let environment = environment as? UserPoolEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = SignOutEvent(id: UUID().uuidString, eventType: .signedOutFailure(error))
            dispatcher.send(event)
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            return
        }

        let client: CognitoUserPoolBehavior
        do {
            client = try environment.cognitoUserPoolFactory()
        } catch {
            let authError = AuthenticationError.configuration(message: "Failed to get CognitoUserPool client: \(error)")
            let event = SignOutEvent(id: UUID().uuidString, eventType: .signedOutFailure(authError))
            dispatcher.send(event)
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            return
        }

        logVerbose("\(#fileID) Starting revoke token api", environment: environment)

        let input = DeleteUserInput(accessToken: accessToken)
        Task {
            let event: DeleteUserEvent
            do {
                _ = try await client.deleteUser(input: input)
                event = DeleteUserEvent(eventType: .signOutDeletedUser)
                logVerbose("\(#fileID) Revoke token succeeded", environment: environment)
            } catch let error as DeleteUserOutputError {
                event = DeleteUserEvent(eventType: .throwError)
                logVerbose("\(#fileID) Revoke token failed \(error)", environment: environment)
            } catch let error {
                event = DeleteUserEvent(eventType: .throwError)
                logVerbose("\(#fileID) Revoke token failed \(error)", environment: environment)
            }
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }
    }

}

extension DeleteUser: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension DeleteUser: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
