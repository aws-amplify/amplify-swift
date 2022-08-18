//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct VerifyDevicePasswordSRP: Action {
    let identifier = "VerifyDevicePasswordSRP"

    let stateData: SRPStateData
    let authResponse: SignInResponseBehavior

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let srpEnv = try environment.srpEnvironment()
            let userPoolEnv = try environment.userPoolEnvironment()
            let srpClient = try SRPSignInHelper.srpClient(srpEnv)
            let parameters = try challengeParameters()

            let inputUsername = stateData.username
            let username = parameters["USERNAME"] ?? inputUsername

            let saltHex = try saltHex(parameters)
            let secretBlockString = try secretBlockString(parameters)
            let secretBlock = try secretBlock(secretBlockString)
            let serverPublicB = try serverPublic(parameters)

            guard case .metadata(let deviceData) = stateData.deviceMetadata else {
                let authError = SignInError.service(error: SRPError.calculation)
                logVerbose("\(#fileID) DevciceSRPSignInError \(authError)", environment: environment)
                let event = SignInEvent(
                    eventType: .throwPasswordVerifierError(authError)
                )
                await dispatcher.send(event)
                return
            }

            let signature = try signature(
                deviceGroupKey: deviceData.deviceGroupKey,
                deviceKey: deviceData.deviceKey,
                deviceSecret: deviceData.deviceSecret,
                saltHex: saltHex,
                secretBlock: secretBlock,
                serverPublicBHexString: serverPublicB,
                srpClient: srpClient)

            let request = RespondToAuthChallengeInput.devicePasswordVerifier(
                username: username,
                stateData: stateData,
                session: authResponse.session,
                secretBlock: secretBlockString,
                signature: signature,
                environment: userPoolEnv)

            let responseEvent = await try UserPoolSignInHelper.sendRespondToAuth(
                request: request,
                for: username,
                environment: userPoolEnv)
            logVerbose("\(#fileID) Sending event \(responseEvent)",
                       environment: environment)
            await dispatcher.send(responseEvent)

        } catch let error as SignInError {
            logVerbose("\(#fileID) SRPSignInError \(error)", environment: environment)
            let event = SignInEvent(
                eventType: .throwPasswordVerifierError(error)
            )
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) SRPSignInError Generic \(error)", environment: environment)
            let authError = SignInError.service(error: error)
            let event = SignInEvent(
                eventType: .throwAuthError(authError)
            )
            await dispatcher.send(event)
        }
    }
}

extension VerifyDevicePasswordSRP: DefaultLogger { }

extension VerifyDevicePasswordSRP: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "stateData": stateData.debugDictionary,
            "authResponse": authResponse
        ]
    }
}

extension VerifyDevicePasswordSRP: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
