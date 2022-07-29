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
                 environment: Environment) {

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
                dispatcher.send(event)
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

            let request = request(
                username: username,
                session: authResponse.session,
                secretBlock: secretBlockString,
                signature: signature,
                environment: userPoolEnv)

            try UserPoolSignInHelper.sendRespondToAuth(
                request: request,
                for: username,
                environment: userPoolEnv) { responseEvent in
                    logVerbose("\(#fileID) Sending event \(responseEvent)",
                               environment: environment)
                    dispatcher.send(responseEvent)
                }
        } catch let error as SignInError {
            logVerbose("\(#fileID) SRPSignInError \(error)", environment: environment)
            let event = SignInEvent(
                eventType: .throwPasswordVerifierError(error)
            )
            dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) SRPSignInError Generic \(error)", environment: environment)
            let authError = SignInError.service(error: error)
            let event = SignInEvent(
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
        }
    }

    private func request(username: String,
                         session: String?,
                         secretBlock: String,
                         signature: String,
                         environment: UserPoolEnvironment)
    -> RespondToAuthChallengeInput {
        let dateStr = generateDateString(date: stateData.clientTimestamp)
        let userPoolClientId = environment.userPoolConfiguration.clientId
        var challengeResponses = ["USERNAME": username]
        if let clientSecret = environment.userPoolConfiguration.clientSecret {

            let clientSecretHash = SRPSignInHelper.clientSecretHash(
                username: username,
                userPoolClientId: userPoolClientId,
                clientSecret: clientSecret
            )
            challengeResponses["SECRET_HASH"] = clientSecretHash
        }

        if case .metadata(let data) = stateData.deviceMetadata {
            challengeResponses["DEVICE_KEY"] = data.deviceKey
        }

        challengeResponses["TIMESTAMP"] = dateStr
        challengeResponses["PASSWORD_CLAIM_SECRET_BLOCK"] = secretBlock
        challengeResponses["PASSWORD_CLAIM_SIGNATURE"] = signature
        return RespondToAuthChallengeInput(
            analyticsMetadata: nil,
            challengeName: .devicePasswordVerifier,
            challengeResponses: challengeResponses,
            clientId: userPoolClientId,
            clientMetadata: nil,
            session: session,
            userContextData: nil)
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
