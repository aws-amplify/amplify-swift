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

struct InitiateAuthDeviceSRP: Action {
    let identifier = "InitiateAuthDeviceSRP"

    let username: String
    let deviceMetadata: DeviceMetadata
    let authResponse: SignInResponseBehavior

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let srpEnv = try environment.srpEnvironment()
            let userPoolEnv = try environment.userPoolEnvironment()
            let srpClient = try SRPSignInHelper.srpClient(srpEnv)
            let nHexValue = srpEnv.srpConfiguration.nHexValue
            let gHexValue = srpEnv.srpConfiguration.gHexValue
            let srpKeyPair = srpClient.generateClientKeyPair()

            let srpStateData = SRPStateData(
                username: username,
                password: "",
                NHexValue: nHexValue,
                gHexValue: gHexValue,
                srpKeyPair: srpKeyPair,
                deviceMetadata: deviceMetadata,
                clientTimestamp: Date())

            let request = request(environment: userPoolEnv,
                                  publicHexValue: srpKeyPair.publicKeyHexValue)

            let client = try userPoolEnv.cognitoUserPoolFactory()

            Task {
                let event: StateMachineEvent
                do {
                    let response = try await client.respondToAuthChallenge(input: request)
                    event = parseResponse(response, with: srpStateData)
                } catch {
                    let authError = SignInError.service(error: error)
                    event = SignInEvent(eventType: .throwAuthError(authError))

                }
                logVerbose("\(#fileID) Sending event \(event)", environment: srpEnv)
                dispatcher.send(event)
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

    private func request(environment: UserPoolEnvironment,
                         publicHexValue: String) -> RespondToAuthChallengeInput {
        let userPoolClientId = environment.userPoolConfiguration.clientId
        var challengeParameters = [
            "USERNAME": username,
            "SRP_A": publicHexValue
        ]

        if let clientSecret = environment.userPoolConfiguration.clientSecret {
            let clientSecretHash = SRPSignInHelper.clientSecretHash(
                username: username,
                userPoolClientId: userPoolClientId,
                clientSecret: clientSecret
            )
            challengeParameters["SECRET_HASH"] = clientSecretHash
        }

        if case .metadata(let data) = deviceMetadata {
            challengeParameters["DEVICE_KEY"] = data.deviceKey
        }

        return RespondToAuthChallengeInput(
            analyticsMetadata: nil,
            challengeName: .deviceSrpAuth,
            challengeResponses: challengeParameters,
            clientId: userPoolClientId,
            clientMetadata: nil,
            session: authResponse.session,
            userContextData: nil)
    }

    func parseResponse(
        _ response: SignInResponseBehavior,
        with stateData: SRPStateData) -> StateMachineEvent {

            if let challengeName = response.challengeName {
                switch challengeName {
                case .devicePasswordVerifier:
                    return SignInEvent(eventType: .respondDevicePasswordVerifier(stateData, response))
                default:
                    let message = "Unsupported challenge response during DeviceSRPAuth \(challengeName)"
                    let error = SignInError.unknown(message: message)
                    return SignInEvent(eventType: .throwAuthError(error))
                }
            } else {
                let message = "Response did not contain challenge info"
                let error = SignInError.invalidServiceResponse(message: message)
                return SignInEvent(eventType: .throwAuthError(error))
            }
        }

}

extension InitiateAuthDeviceSRP: DefaultLogger { }

extension InitiateAuthDeviceSRP: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitiateAuthDeviceSRP: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
