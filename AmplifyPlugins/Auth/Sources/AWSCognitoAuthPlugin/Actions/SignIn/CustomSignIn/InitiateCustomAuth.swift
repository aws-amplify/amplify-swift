//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import CryptoKit
import AWSCognitoIdentityProvider

struct InitiateCustomAuth: Action {
    let identifier = "InitiateCustomAuth"

    let username: String
    let clientMetadata: [String: String]
    let deviceMetadata: DeviceMetadata

    init(username: String,
         clientMetadata: [String: String],
         deviceMetadata: DeviceMetadata) {
        self.username = username
        self.clientMetadata = clientMetadata
        self.deviceMetadata = deviceMetadata
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let userPoolEnv = try environment.userPoolEnvironment()
            let request = InitiateAuthInput.customAuth(
                username: username,
                clientMetadata: clientMetadata,
                deviceMetadata: deviceMetadata,
                environment: userPoolEnv)

            try sendRequest(request: request,
                            environment: userPoolEnv) { responseEvent in
                logVerbose("\(#fileID) Sending event \(responseEvent)", environment: environment)
                dispatcher.send(responseEvent)

            }

        } catch let error as SignInError {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let event = SignInEvent(eventType: .throwAuthError(error))
            dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Caught error \(error)", environment: environment)
            let authError = SignInError.service(error: error)
            let event = SignInEvent(
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
        }
    }

    private func sendRequest(request: InitiateAuthInput,
                             environment: UserPoolEnvironment,
                             callback: @escaping (StateMachineEvent) -> Void) throws {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        logVerbose("\(#fileID) Starting execution", environment: environment)

        Task {
            let event: StateMachineEvent!
            do {
                let response = try await cognitoClient.initiateAuth(input: request)
                event = try UserPoolSignInHelper.parseResponse(response, for: username)
                logVerbose("\(#fileID) InitiateAuth response success", environment: environment)
            } catch {
                let authError = SignInError.service(error: error)
                event = SignInEvent(eventType: .throwAuthError(authError))
            }
            callback(event)
        }
    }

}

extension InitiateCustomAuth: DefaultLogger { }

extension InitiateCustomAuth: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.masked()
        ]
    }
}

extension InitiateCustomAuth: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
