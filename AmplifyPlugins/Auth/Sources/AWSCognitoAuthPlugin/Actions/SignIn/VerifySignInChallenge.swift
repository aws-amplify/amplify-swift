//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct VerifySignInChallenge: Action {

    var identifier: String = "VerifySignInChallenge"

    let challenge: RespondToAuthChallenge

    let confirmSignEventData: ConfirmSignInEventData

    let signInMethod: SignInMethod

    let currentSignInStep: AuthSignInStep

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let username = challenge.username
        var deviceMetadata = DeviceMetadata.noData

        do {

            if case .continueSignInWithMFASetupSelection(_) = currentSignInStep {
                let newChallenge = RespondToAuthChallenge(
                    challenge: .mfaSetup,
                    username: challenge.username,
                    session: challenge.session,
                    parameters: ["MFAS_CAN_SETUP": "[\"\(confirmSignEventData.answer)\"]"])

                let event: SignInEvent
                guard let mfaType = MFAType(rawValue: confirmSignEventData.answer) else {
                    throw SignInError.inputValidation(field: "Unknown MFA type")
                }

                switch mfaType {
                case .email:
                    event = SignInEvent(eventType: .receivedChallenge(newChallenge))
                case .totp:
                    event = SignInEvent(eventType: .initiateTOTPSetup(username, newChallenge))
                default:
                    throw SignInError.unknown(message: "MFA Type not supported for setup")
                }

                logVerbose("\(#fileID) Sending event \(event)", environment: environment)
                await dispatcher.send(event)
                return
            }

            let userpoolEnv = try environment.userPoolEnvironment()
            let username = challenge.username
            let session = challenge.session
            let challengeType = challenge.challenge
            let responseKey = try challenge.getChallengeKey()

            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: environment.authEnvironment().credentialsClient)

            deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                            for: username,
                            with: environment)

            let input = await RespondToAuthChallengeInput.verifyChallenge(
                username: username,
                challengeType: challengeType,
                session: session,
                responseKey: responseKey,
                answer: confirmSignEventData.answer,
                clientMetadata: confirmSignEventData.metadata,
                asfDeviceId: asfDeviceId,
                attributes: confirmSignEventData.attributes,
                deviceMetadata: deviceMetadata,
                environment: userpoolEnv)

            let responseEvent = try await UserPoolSignInHelper.sendRespondToAuth(
                request: input,
                for: username,
                signInMethod: signInMethod,
                environment: userpoolEnv)
            logVerbose("\(#fileID) Sending event \(responseEvent)",
                       environment: environment)
            await dispatcher.send(responseEvent)
        } catch let error where deviceNotFound(error: error, deviceMetadata: deviceMetadata) {
            logVerbose("\(#fileID) Received device not found \(error)", environment: environment)
            // Remove the saved device details and retry verify challenge
            await DeviceMetadataHelper.removeDeviceMetaData(for: username, with: environment)
            let event = SignInChallengeEvent(
                eventType: .retryVerifyChallengeAnswer(confirmSignEventData, currentSignInStep)
            )
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
        } catch let error as SignInError {
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        } catch {
            let error = SignInError.service(error: error)
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        }
    }

    func deviceNotFound(error: Error, deviceMetadata: DeviceMetadata) -> Bool {

        // If deviceMetadata was not send, the error returned is not from device not found.
        if case .noData = deviceMetadata {
            return false
        }

        return error is AWSCognitoIdentityProvider.ResourceNotFoundException
    }

}

extension VerifySignInChallenge: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "challenge": challenge.debugDictionary
        ]
    }
}

extension VerifySignInChallenge: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
