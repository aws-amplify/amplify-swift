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
        do {
            let userPoolEnv = try environment.userPoolEnvironment()
            let request = request(environment: userPoolEnv)

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

    private func request(environment: UserPoolEnvironment) -> InitiateAuthInput {
        let userPoolClientId = environment.userPoolConfiguration.clientId
        var authParameters = [
            "USERNAME": username,
            "PASSWORD": password
        ]

        if let clientSecret = environment.userPoolConfiguration.clientSecret {
            let clientSecretHash = SRPSignInHelper.clientSecretHash(
                username: username,
                userPoolClientId: userPoolClientId,
                clientSecret: clientSecret
            )
            authParameters["SECRET_HASH"] = clientSecretHash
        }

        if let deviceId = Self.getDeviceId() {
            authParameters["DEVICE_KEY"] = deviceId
        }

        return InitiateAuthInput(analyticsMetadata: nil,
                                 authFlow: .userPasswordAuth,
                                 authParameters: authParameters,
                                 clientId: userPoolClientId,
                                 clientMetadata: clientMetadata,
                                 userContextData: nil)
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
                event = UserPoolSignInHelper.parseResponse(response, for: username)
                logVerbose("\(#fileID) InitiateAuth response success", environment: environment)
            } catch {
                let authError = SignInError.service(error: error)
                event = SignInEvent(eventType: .throwAuthError(authError))
            }
            callback(event)
        }
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
