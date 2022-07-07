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
    let identifier = "InitiateAuthSRP"

    let username: String
    let clientMetadata: [String: String]

    init(username: String, clientMetadata: [String: String]) {
        self.username = username
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
            "USERNAME": username
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
                                 authFlow: .customAuth,
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
                event = parseResponse(response, for: username)
                logVerbose("\(#fileID) InitiateAuth response success", environment: environment)
            } catch {
                let authError = SignInError.service(error: error)
                event = SignInEvent(eventType: .throwAuthError(authError))
            }
            callback(event)
        }
    }

    private func parseResponse(
        _ response: InitiateAuthOutputResponse,
        for username: String) -> StateMachineEvent {

            if let authenticationResult = response.authenticationResult,
               let idToken = authenticationResult.idToken,
               let accessToken = authenticationResult.accessToken,
               let refreshToken = authenticationResult.refreshToken {

                let userPoolTokens = AWSCognitoUserPoolTokens(idToken: idToken,
                                                              accessToken: accessToken,
                                                              refreshToken: refreshToken,
                                                              expiresIn: authenticationResult.expiresIn)
                let signedInData = SignedInData(userId: "",
                                                userName: username,
                                                signedInDate: Date(),
                                                signInMethod: .apiBased(.userSRP),
                                                cognitoUserPoolTokens: userPoolTokens)
                return SignInEvent(eventType: .finalizeSignIn(signedInData))

            } else if let challengeName = response.challengeName, let session = response.session {
                let parameters = response.challengeParameters
                let response = RespondToAuthChallenge(challenge: challengeName,
                                                      username: username,
                                                      session: session,
                                                      parameters: parameters)

                switch challengeName {
                case .smsMfa:
                    return SignInEvent(eventType: .receivedSMSChallenge(response))
                case .customChallenge:
                    return SignInEvent(eventType: .receivedCustomChallenge(response))
                default:
                    let message = "UnSupported challenge response \(challengeName)"
                    let error = SignInError.invalidServiceResponse(message: message)
                    return SignInEvent(eventType: .throwAuthError(error))
                }
            } else {
                let message = "Response did not contain signIn info"
                let error = SignInError.invalidServiceResponse(message: message)
                return SignInEvent(eventType: .throwAuthError(error))
            }
        }

    // TODO: Implement this
    private static func getDeviceId() -> String? {
        return nil
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
