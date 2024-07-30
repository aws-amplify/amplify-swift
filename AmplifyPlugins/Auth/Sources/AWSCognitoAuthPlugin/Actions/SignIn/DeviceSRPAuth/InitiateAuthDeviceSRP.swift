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
    let authResponse: SignInResponseBehavior

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let srpEnv = try environment.srpEnvironment()
            let userPoolEnv = try environment.userPoolEnvironment()
            let srpClient = try SRPSignInHelper.srpClient(srpEnv)
            let nHexValue = srpEnv.srpConfiguration.nHexValue
            let gHexValue = srpEnv.srpConfiguration.gHexValue
            let srpKeyPair = srpClient.generateClientKeyPair()

            // Get device metadata
            let deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                for: username,
                with: environment)

            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: environment.authEnvironment().credentialsClient)

            let srpStateData = SRPStateData(
                username: username,
                password: "",
                NHexValue: nHexValue,
                gHexValue: gHexValue,
                srpKeyPair: srpKeyPair,
                clientTimestamp: Date())

            let request = await RespondToAuthChallengeInput.deviceSRP(
                username: username,
                environment: userPoolEnv,
                deviceMetadata: deviceMetadata,
                asfDeviceId: asfDeviceId,
                session: authResponse.session,
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
                await dispatcher.send(event)
            }
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

    func parseResponse(
        _ response: SignInResponseBehavior,
        with stateData: SRPStateData) -> StateMachineEvent {
            guard case .devicePasswordVerifier = response.challengeName else {
                let message = """
                Unsupported challenge response during DeviceSRPAuth
                \(response.challengeName ?? .sdkUnknown("Response did not contain challenge info"))
                """
                let error = SignInError.unknown(message: message)
                return SignInEvent(eventType: .throwAuthError(error))
            }
            return SignInEvent(eventType: .respondDevicePasswordVerifier(stateData, response))
        }

}

extension InitiateAuthDeviceSRP: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }

    public var log: Logger {
        Self.log
    }
}

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
