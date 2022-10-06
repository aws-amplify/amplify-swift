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
    let deviceMetadata: DeviceMetadata

    init(username: String,
         password: String,
         clientMetadata: [String: String],
         deviceMetadata: DeviceMetadata) {
        self.username = username
        self.password = password
        self.clientMetadata = clientMetadata
        self.deviceMetadata = deviceMetadata
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let userPoolEnv = try environment.userPoolEnvironment()
            let authEnv = try environment.authEnvironment()
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: authEnv.credentialsClient)
            let request = InitiateAuthInput.migrateAuth(
                username: username,
                password: password,
                clientMetadata: clientMetadata,
                asfDeviceId: asfDeviceId,
                deviceMetadata: deviceMetadata,
                environment: userPoolEnv)

            let responseEvent = try await sendRequest(request: request,
                                                      environment: userPoolEnv)
            logVerbose("\(#fileID) Sending event \(responseEvent)", environment: environment)
            await dispatcher.send(responseEvent)

        } catch let error as SignInError {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let event = SignInEvent(eventType: .throwAuthError(error))
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Caught error \(error)", environment: environment)
            let authError = SignInError.service(error: error)
            let event = SignInEvent(
                eventType: .throwAuthError(authError)
            )
            await dispatcher.send(event)
        }

    }

    private func sendRequest(request: InitiateAuthInput,
                             environment: UserPoolEnvironment) async throws -> StateMachineEvent {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let response = try await cognitoClient.initiateAuth(input: request)
        return try UserPoolSignInHelper.parseResponse(response,
                                                      for: username,
                                                      signInMethod: .apiBased(.userPassword))
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
