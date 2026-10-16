//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package struct SetUpTOTP: Action {

    package var identifier: String = "SetUpTOTP"
    package let authResponse: RespondToAuthChallenge
    package let signInEventData: SignInEventData

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let userpoolEnv = try environment.userPoolEnvironment()
            let client = try userpoolEnv.cognitoUserPoolFactory()
            let input = AssociateSoftwareTokenInput(session: authResponse.session)

            // Initiate Set Up TOTP
            let result = try await client.associateSoftwareToken(input: input)

            guard let username = signInEventData.username else {
                throw SignInError.unknown(message: "Unable unwrap username to for use during TOTP setup")
            }

            guard let session = result.session,
                  let secretCode = result.secretCode
            else {
                throw SignInError.unknown(message: "Error unwrapping result associateSoftwareToken result")
            }

            let responseEvent = SetUpTOTPEvent(eventType:
                    .waitForAnswer(.init(
                        secretCode: secretCode,
                        session: session,
                        username: username
                    )))
            logVerbose(
                "\(#fileID) Sending event \(responseEvent)",
                environment: environment
            )
            await dispatcher.send(responseEvent)
        } catch let error as SignInError {
            logError(error.engineError.errorDescription, environment: environment)
            let errorEvent = SetUpTOTPEvent(eventType: .throwError(error))
            logVerbose(
                "\(#fileID) Sending event \(errorEvent)",
                environment: environment
            )
            await dispatcher.send(errorEvent)
        } catch {
            let error = SignInError.service(error: error)
            logError(error.engineError.errorDescription, environment: environment)
            let errorEvent = SetUpTOTPEvent(eventType: .throwError(error))
            logVerbose(
                "\(#fileID) Sending event \(errorEvent)",
                environment: environment
            )
            await dispatcher.send(errorEvent)
        }
    }

}

extension SetUpTOTP: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "challengeName": authResponse.challenge.rawValue,
            "session": authResponse.session?.maskedForLog() ?? "",
            "challengeParameters": authResponse.parameters ?? [:],
            "signInEventData": signInEventData.debugDictionary
        ]
    }
}

extension SetUpTOTP: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
