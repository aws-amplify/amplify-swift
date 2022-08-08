//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct InitiateMigrateAuth: Action {
    let identifier = "InitiateMigrateAuth"

    let username: String
    let password: String
    let clientMetadata: [String: String]

    init(username: String, password: String, clientMetadata: [String: String]) {
        self.username = username
        self.password = password
        self.clientMetadata = clientMetadata
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        Task {
            do {
                let userPoolEnv = try environment.userPoolEnvironment()
                let authEnv = try environment.authEnvironment()
                let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                    for: username,
                    credentialStoreClient: authEnv.credentialStoreClientFactory())
                let request = InitiateAuthInput.migrateAuth(
                    username: username,
                    password: password,
                    clientMetadata: clientMetadata,
                    asfDeviceId: asfDeviceId,
                    environment: userPoolEnv)

                let responseEvent = try await sendRequest(request: request,
                                                          environment: userPoolEnv)
                logVerbose("\(#fileID) Sending event \(responseEvent)", environment: environment)
                dispatcher.send(responseEvent)

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

    }

    private func sendRequest(request: InitiateAuthInput,
                             environment: UserPoolEnvironment) async throws -> StateMachineEvent {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let response = try await cognitoClient.initiateAuth(input: request)
        return try UserPoolSignInHelper.parseResponse(response, for: username)
    }

    // TODO: Implement this
    private static func getDeviceId() -> String? {
        return nil
    }

}

extension InitiateMigrateAuth: DefaultLogger { }

extension InitiateMigrateAuth: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.masked()
        ]
    }
}

extension InitiateMigrateAuth: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
