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

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let userpoolEnv = try environment.userPoolEnvironment()
            let username = challenge.username
            let session = challenge.session
            let challengeType = challenge.challenge
            let responseKey = try challenge.getChallengeKey()

            let input = RespondToAuthChallengeInput.verifyChallenge(
                username: username,
                challengeType: challengeType,
                session: session,
                responseKey: responseKey,
                answer: confirmSignEventData.answer,
                clientMetadata: confirmSignEventData.metadata,
                attributes: confirmSignEventData.attributes,
                environment: userpoolEnv)

            let responseEvent = try await UserPoolSignInHelper.sendRespondToAuth(
                request: input,
                for: username,
                signInMethod: signInMethod,
                environment: userpoolEnv)
            logVerbose("\(#fileID) Sending event \(responseEvent)",
                       environment: environment)
            await dispatcher.send(responseEvent)
        } catch let error as SignInError {
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        } catch {
            let error = SignInError.invalidServiceResponse(message: error.localizedDescription)
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        }
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
