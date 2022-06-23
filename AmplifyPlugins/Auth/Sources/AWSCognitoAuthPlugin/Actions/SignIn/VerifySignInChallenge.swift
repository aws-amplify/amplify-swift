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

    let answer: String

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let userpoolEnv = try environment.userPoolEnvironment()
            let username = challenge.username
            let session = challenge.session
            let challengeType = challenge.challenge
            let responseKey = "SMS_MFA_CODE"
            let userPoolClientId = userpoolEnv.userPoolConfiguration.clientId

            var challengeResponses = ["USERNAME": username, responseKey: answer]

            if let clientSecret = userpoolEnv.userPoolConfiguration.clientSecret {

                let clientSecretHash = SRPSignInHelper.clientSecretHash(
                    username: username,
                    userPoolClientId: userPoolClientId,
                    clientSecret: clientSecret
                )
                challengeResponses["SECRET_HASH"] = clientSecretHash
            }

            let input = RespondToAuthChallengeInput(
                analyticsMetadata: nil,
                challengeName: challengeType,
                challengeResponses: challengeResponses,
                clientId: userPoolClientId,
                clientMetadata: [:],
                session: session,
                userContextData: nil)


            try UserPoolSignInHelper.sendRespondToAuth(
                request: input,
                for: username,
                environment: userpoolEnv) { responseEvent in
                    logVerbose("\(#fileID) Sending event \(responseEvent)",
                               environment: environment)
                    dispatcher.send(responseEvent)
                }
        } catch let error as SignInError {
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            dispatcher.send(errorEvent)
        } catch {
            let error = SignInError.invalidServiceResponse(message: error.localizedDescription)
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            dispatcher.send(errorEvent)
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
